"""
3_generate_classes.py
Gera arquivos .clas.abap para municípios usando Claude CLI ou Codex CLI e, por padrão,
também a classe de teste ABAP Unit correspondente (.prog.abap), seguindo o padrão do
repositório s4tax_tests (include /s4tax/nfse_{uf}{ibge}_t99).

Lê os .txt de "EFTs txt/" (ou --efts-dir), busca o código IBGE em ibge_codes.json
e chama a CLI de IA selecionada para gerar o código ABAP.

Saída (em "Municipios Prontos/"):
  #s4tax#nfse_{uf}{ibge}.clas.abap          -> classe principal do município
  #s4tax#nfse_{uf}{ibge}_t99.prog.abap      -> include de teste ABAP Unit (colar no Eclipse)

Uso:
  python src/scripts/3_generate_classes.py [--only "Cacador SC"] [--force] [--efts-dir CAMINHO] [--no-tests] [--provider claude|codex] [--model NOME]
  --only:     processa apenas o município/UF informado (ex: "Cacador SC")
  --force:    regera mesmo se o .clas.abap (e/ou teste) já existir
  --efts-dir: pasta com os .txt de EFT (padrão: <raiz>/EFTs txt)
  --no-tests: gera apenas a classe principal, sem a classe de teste
  --provider: CLI de IA usada (padrão: claude)
  --model:    modelo opcional passado para a CLI selecionada

Não requer nenhuma variável de ambiente de API — usa a CLI local selecionada.
"""
import difflib
import json
import re
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

from ai_cli import DEFAULT_PROVIDER, call_ai, check_provider, option_value, validate_provider

ROOT_DIR    = Path(__file__).parent.parent.parent   # nfse-builder/
PROJECT_DIR = ROOT_DIR.parent.parent                # claude_abap/

OUTPUT_DIR  = ROOT_DIR / "Municipios Prontos"
IBGE_FILE   = ROOT_DIR / "ibge_codes.json"
NFSE_MD     = PROJECT_DIR / "nfse-municipios.md"
CLAUDE_MD   = PROJECT_DIR / "CLAUDE.md"
LISTA_MD    = ROOT_DIR / "Municipios Prontos" / "lista_prontos.md"
AI_PROVIDER = DEFAULT_PROVIDER
AI_MODEL    = None

# Exemplos few-shot da CLASSE PRINCIPAL (buscados dinamicamente no repo s4tax_nfse).
# Escolhidos por serem concisos e cobrirem os dois padrões de herança:
#   nfse_ba2922003 : herda /s4tax/nfse_default — serie IS INITIAL -> 'NF', tipo_rps '1', cancelamento
#   nfse_to1712504 : herda /s4tax/nfse_nacional (padrão nacional) — apenas get_reasons_cancellation
FEW_SHOT_PREFERRED = [
    "#s4tax#nfse_ba2922003.clas.abap",
    "#s4tax#nfse_to1712504.clas.abap",
]

# Exemplos few-shot da CLASSE DE TESTE (buscados dinamicamente no repo s4tax_tests).
#   nfse_es3200409_t99 : testa serie/tipo_rps (com e sem série) + todos os códigos de cancelamento
#   nfse_ba2918407_t99 : teste mínimo (apenas tipo_rps fixo)
TEST_FEW_SHOT_PREFERRED = [
    "#s4tax#nfse_es3200409_t99.prog.abap",
    "#s4tax#nfse_ba2918407_t99.prog.abap",
]

# API da classe base de testes /s4tax/nfse_default_test (resumo para o prompt).
# Mantém a geração do teste alinhada aos helpers/membros realmente disponíveis.
BASE_TEST_API = """A classe de teste DEVE herdar de `/s4tax/nfse_default_test` (classe base abstrata FOR TESTING).
Membros de instância já disponíveis (herdados — NÃO declarar de novo):
  - branch_info TYPE REF TO /s4tax/nfse_branch_info
  - documents   TYPE REF TO /s4tax/nfse_documents
  - doc         TYPE REF TO /s4tax/doc
  - branch      TYPE REF TO /s4tax/branch
  - extension_head / extension_item (para mexer em série, regime, natureza op. etc.)
Membro de classe (CLASS-DATA) herdado:
  - reporter TYPE REF TO /s4tax/ireporter

Métodos auxiliares herdados (PROTECTED — chamar como me->metodo( )):
  - mock_identificacao( )  : popula doc com série '001', docnum '0123456789', datas etc.
  - mock_extension( )      : popula extension_head/item (regime 'T', natureza '2', item_lista '14.01' ...)
  - mock_servico( )        : popula impostos/serviço do item_1
  - mock_all( )            : identificacao + tomador + endereço + serviço + constr. civil
  - mount_identificacao_expected( ) RETURNING /s4tax/s_nfse_identificacao : valores esperados padrão (série '001', tipo_rps '1', natureza '1' ...)
Para forçar série/numero diretamente no doc:
  - doc->set_series( iv_series = 'XX' )   " '' para simular série vazia
  - doc->set_docnum( '0000123456' )

Tipos úteis nos testes:
  - /s4tax/s_nfse_identificacao   (campos: serie, tipo_rps, natureza_operacao, competencia, numero ...)
  - /s4tax/s_nfse_cancel_fields   (campos: code, motivo)
  - /s4tax/s_nfse_servico

Padrão de instanciação do objeto sob teste (cut) — usar SEMPRE get_instance da classe base:
  cut ?= /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter ).
O nome da classe municipal é resolvido por /s4tax/tests_utils=>get_classname_by_data( cut ) e aplicado via
me->branch_info->get_class( )->set_class( ... ) dentro de class_setup/setup."""

# Regex para extrair (cidade, UF) do nome do arquivo EFT
FILENAME_PATTERNS = [
    re.compile(r"NFSe?\s+(.+?)\s+-\s+([A-Z]{2})", re.IGNORECASE),
    re.compile(r"NFSe?_(.+?)_([A-Z]{2})(?:\.txt)?$", re.IGNORECASE),
]


# ---------------------------------------------------------------------------
# AI CLI helper
# ---------------------------------------------------------------------------

def call_provider(prompt: str, timeout: int = 180) -> str:
    return call_ai(prompt, provider=AI_PROVIDER, model=AI_MODEL, timeout=timeout)


# ---------------------------------------------------------------------------
# Helpers de normalização e busca IBGE
# ---------------------------------------------------------------------------

def normalize(name: str) -> str:
    nfkd = unicodedata.normalize("NFKD", name)
    return "".join(c for c in nfkd if not unicodedata.combining(c)).lower().strip()


def parse_eft_filename(stem: str):
    """Extrai (cidade, UF) do nome do arquivo sem extensão. None se falhar."""
    for pattern in FILENAME_PATTERNS:
        m = pattern.search(stem)
        if m:
            city = m.group(1).strip().replace("_", " ")
            uf = m.group(2).upper()
            return city, uf
    return None


def find_ibge_code(ibge_data: dict, city: str, uf: str):
    """
    Busca código IBGE para (cidade, UF).
    Retorna (ibge_code, matched_name) ou (None, None).
    """
    state_data = ibge_data.get(uf.upper(), {})
    if not state_data:
        return None, None

    city_norm = normalize(city)
    if city_norm in state_data:
        return state_data[city_norm], city_norm

    matches = difflib.get_close_matches(city_norm, list(state_data.keys()), n=1, cutoff=0.7)
    if matches:
        return state_data[matches[0]], matches[0]

    return None, None


# ---------------------------------------------------------------------------
# Carregamento de contexto (arquitetura, CLAUDE.md, exemplos)
# ---------------------------------------------------------------------------

def load_text_file(path: Path, label: str) -> str:
    if path.exists():
        return path.read_text(encoding="utf-8")
    print(f"  [AVISO] {label} não encontrado: {path}")
    return ""


def _find_repo_src(repo_name: str):
    """
    Localiza a pasta /src de um repositório clonado.
    Procura primeiro no layout atual (repositorios/git_online/<repo>/src) e
    cai para layouts antigos (repositorios/**/<repo>*/src) como fallback.
    """
    primary = PROJECT_DIR / "repositorios" / "git_online" / repo_name / "src"
    if primary.exists():
        return primary
    candidates = sorted(PROJECT_DIR.glob(f"repositorios/**/{repo_name}*/src"))
    return candidates[0] if candidates else None


def find_repo_src():
    """Pasta src do repositório s4tax_nfse (classes municipais)."""
    return _find_repo_src("s4tax_nfse")


def find_tests_repo_src():
    """Pasta src do repositório s4tax_tests (classes de teste municipais)."""
    return _find_repo_src("s4tax_tests")


def load_few_shot_examples(repo_src) -> str:
    if not repo_src:
        print("  [AVISO] Repositório NFS-e não encontrado — sem exemplos few-shot.")
        return ""

    examples = []
    # Tenta os preferidos primeiro
    for fname in FEW_SHOT_PREFERRED:
        fpath = repo_src / fname
        if fpath.exists():
            content = fpath.read_text(encoding="utf-8")
            examples.append(f"### Exemplo: {fname}\n```abap\n{content}\n```")

    # Se ainda não tem 2, busca quaisquer outros
    if len(examples) < 2:
        for fpath in sorted(repo_src.glob("#s4tax#nfse_*.clas.abap"))[:4]:
            if fpath.name not in FEW_SHOT_PREFERRED:
                content = fpath.read_text(encoding="utf-8")
                examples.append(f"### Exemplo: {fpath.name}\n```abap\n{content}\n```")
            if len(examples) >= 2:
                break

    if not examples:
        print("  [AVISO] Nenhum exemplo .clas.abap encontrado no repositório.")

    return "\n\n".join(examples[:2])


def load_test_few_shot_examples(tests_repo_src) -> str:
    """Carrega exemplos de classes de teste (.prog.abap) do repo s4tax_tests."""
    if not tests_repo_src:
        print("  [AVISO] Repositório de testes não encontrado — sem exemplos de teste.")
        return ""

    examples = []
    for fname in TEST_FEW_SHOT_PREFERRED:
        fpath = tests_repo_src / fname
        if fpath.exists():
            content = fpath.read_text(encoding="utf-8")
            examples.append(f"### Exemplo de teste: {fname}\n```abap\n{content}\n```")

    # Fallback: quaisquer testes municipais
    if len(examples) < 2:
        for fpath in sorted(tests_repo_src.glob("#s4tax#nfse_*_t99.prog.abap"))[:6]:
            if fpath.name not in TEST_FEW_SHOT_PREFERRED:
                content = fpath.read_text(encoding="utf-8")
                examples.append(f"### Exemplo de teste: {fpath.name}\n```abap\n{content}\n```")
            if len(examples) >= 2:
                break

    if not examples:
        print("  [AVISO] Nenhum exemplo de teste .prog.abap encontrado no repositório.")

    return "\n\n".join(examples[:2])


# ---------------------------------------------------------------------------
# Geração ABAP
# ---------------------------------------------------------------------------

def build_generation_prompt(
    city: str, uf: str, ibge_code: str,
    eft_text: str, architecture: str, claude_md: str, examples: str
) -> str:
    uf_lower = uf.lower()
    class_name = f"/s4tax/nfse_{uf_lower}{ibge_code}"
    file_name  = f"#s4tax#nfse_{uf_lower}{ibge_code}.clas.abap"
    tax_addr   = f"{uf.upper()} {ibge_code}"

    return f"""Você é especialista em ABAP S/4HANA criando classes municipais NFS-e para o pacote /S4TAX/NFSE.

## Convenções Gerais do Projeto (CLAUDE.md)

{claude_md}

## Arquitetura das Classes Municipais (nfse-municipios.md)

{architecture}

## Exemplos de Classes Existentes (few-shot)

{examples}

---

## TAREFA

Crie a classe ABAP para o município abaixo:

- **Município:** {city} ({uf.upper()})
- **Código IBGE:** {ibge_code}
- **Nome da classe:** {class_name}
- **Nome do arquivo:** {file_name}
- **Constante tax_address:** '{tax_addr}'

## Especificação Funcional (EFT)

{eft_text}

---

## Regras obrigatórias

1. Herança:
   - Por padrão, herdar de `/s4tax/nfse_default` (municípios com layout/padrão próprio).
   - Se o EFT indicar claramente o **padrão NACIONAL** de NFS-e (ex.: modelo nacional/NFSe Nacional,
     tags `DPS/infDPS`, ABRASF nacional), herdar de `/s4tax/nfse_nacional` e sobrescrever apenas o
     que diverge do padrão nacional. Na dúvida, herdar de `/s4tax/nfse_default`.
2. Declarar `CONSTANTS tax_address TYPE string VALUE '{tax_addr}'.`
3. Sobrescrever APENAS os métodos que o EFT indica comportamento diferente
4. Sempre chamar `super->método( )` primeiro em cada override (exceto `get_reasons_cancellation`)
5. NUNCA usar inline declarations, VALUE #(), NEW #(), COND #() — compatibilidade ABAP < 7.40
6. Sem prefixos húngaros em variáveis (sem lo_, lv_, lt_ etc.)
7. `get_reasons_cancellation` é de interface: declarar como `/s4tax/infse_data~get_reasons_cancellation REDEFINITION`.
   Quando o EFT listar os códigos de cancelamento, mapear CADA código (normalmente 1..5) e o caso default
   usando `CASE code. WHEN '1'. ... WHEN OTHERS. ... ENDCASE.` — NUNCA `IF/ELSEIF/ELSE` para este método.
   Preencher SEMPRE os DOIS campos do resultado: `result-code` (o código) E `result-motivo` (o texto).
   O parâmetro de entrada é `reason_domain`. Estrutura obrigatória:
   ```abap
   DATA code TYPE string.
   code = reason_domain.
   CASE code.
     WHEN '1'.
       result-code = '1'.
       result-motivo = 'Erro na emissao'.
     WHEN OTHERS.
       result-code = '2'.
       result-motivo = 'Servico nao prestado'.
   ENDCASE.
   ```
8. Declarar SEMPRE `PROTECTED SECTION.` e `PRIVATE SECTION.` na definição da classe, mesmo vazias
   (sem métodos/atributos) — mesmo quando só existir `PUBLIC SECTION`. O SAP emite warning de
   sintaxe quando essas seções não são declaradas explicitamente. Ordem: `PUBLIC SECTION.`,
   `PROTECTED SECTION.`, `PRIVATE SECTION.`, depois `ENDCLASS.`. Exemplo mínimo:
   ```abap
   CLASS /s4tax/nfse_{uf}{ibge} DEFINITION
     PUBLIC
     INHERITING FROM /s4tax/nfse_nacional
     FINAL
     CREATE PUBLIC.

     PUBLIC SECTION.
       CONSTANTS tax_address TYPE string VALUE '{UF} {IBGE}'.

     PROTECTED SECTION.

     PRIVATE SECTION.

   ENDCLASS.
   ```
9. Retornar SOMENTE o código ABAP — sem markdown, sem texto antes ou depois
10. Começar com `CLASS {class_name} DEFINITION` e terminar com `ENDCLASS.`
"""


def clean_generated_code(raw: str, city: str, uf: str) -> str:
    """
    Limpa o output do Claude:
    - Remove blocos markdown (```abap ... ```)
    - Remove qualquer texto antes de 'CLASS /s4tax/'
    - Remove qualquer texto após o último ENDCLASS.
    - Garante o comentário '" Cidade/UF' após CREATE PUBLIC.
    """
    # Remove markdown
    raw = re.sub(r"^```(?:abap)?\s*\n", "", raw.strip(), flags=re.MULTILINE)
    raw = re.sub(r"\n```\s*$", "", raw.strip(), flags=re.MULTILINE)

    # Remove texto antes de CLASS /s4tax/
    class_match = re.search(r'^CLASS /s4tax/', raw, re.MULTILINE)
    if class_match:
        raw = raw[class_match.start():]

    # Remove texto após o ÚLTIMO ENDCLASS. (o que fecha a IMPLEMENTATION)
    endclass_matches = list(re.finditer(r'^ENDCLASS\.', raw, re.MULTILINE))
    if endclass_matches:
        raw = raw[:endclass_matches[-1].end()]

    raw = raw.strip()

    # Insere comentário com cidade/UF após CREATE PUBLIC. se ainda não estiver
    comment = f'" {city}/{uf.upper()}'
    if comment not in raw:
        raw = re.sub(
            r'(CREATE PUBLIC\s*\.)',
            r'\1\n' + comment,
            raw,
            count=1
        )

    return raw


def validate(code: str, class_name: str, tax_address: str) -> list:
    errors = []
    if f"CLASS {class_name} DEFINITION" not in code:
        errors.append(f"Falta 'CLASS {class_name} DEFINITION'")
    # Aceita herança de nfse_default (padrão próprio) ou nfse_nacional (padrão nacional)
    if ("INHERITING FROM /s4tax/nfse_default" not in code
            and "INHERITING FROM /s4tax/nfse_nacional" not in code):
        errors.append("Falta herança de /s4tax/nfse_default ou /s4tax/nfse_nacional")
    if tax_address not in code:
        errors.append(f"Falta constante tax_address '{tax_address}'")
    if "IMPLEMENTATION" not in code:
        errors.append("Falta seção IMPLEMENTATION")
    if code.count("ENDCLASS.") < 2:
        errors.append("Falta ENDCLASS. da IMPLEMENTATION (esperados 2)")
    return errors


# ---------------------------------------------------------------------------
# Geração da CLASSE DE TESTE (.prog.abap + .prog.xml)
# ---------------------------------------------------------------------------

def build_test_prompt(
    city: str, uf: str, ibge_code: str,
    class_name: str, class_code: str,
    test_examples: str, eft_text: str,
) -> str:
    uf_upper   = uf.upper()
    ltcl_name  = f"ltcl_nfse_{uf.lower()}{ibge_code}"
    include    = f"{class_name}_t99"

    return f"""Você é especialista em ABAP Unit criando a CLASSE DE TESTE de uma classe municipal NFS-e do pacote /S4TAX/NFSE.

## Classe base de testes disponível

{BASE_TEST_API}

## Exemplos de classes de teste existentes (few-shot — siga EXATAMENTE este padrão)

{test_examples}

---

## TAREFA

Gerar o include de teste ABAP Unit para a classe municipal abaixo.

- **Município:** {city} ({uf_upper}) — IBGE {ibge_code}
- **Classe sob teste:** {class_name}
- **Nome do include de teste:** {include}
- **Nome da classe local de teste:** {ltcl_name}

### Código da CLASSE PRINCIPAL que será testada (base para os testes)

```abap
{class_code}
```

### Especificação Funcional (EFT) — use para descrever as regras nas mensagens de assert

{eft_text}

---

## Regras obrigatórias

1. Comece o arquivo EXATAMENTE com o cabeçalho de include:
   `*&---------------------------------------------------------------------*`
   `*& Include {include}`
   `*&---------------------------------------------------------------------*`
2. Definir `CLASS {ltcl_name} DEFINITION ... FOR TESTING INHERITING FROM /s4tax/nfse_default_test DURATION SHORT RISK LEVEL HARMLESS.`
3. Declarar `DATA: cut TYPE REF TO {class_name}.` na PRIVATE SECTION.
4. Implementar `setup` (e `class_setup` quando usar o cache de nome) instanciando `cut` via
   `cut ?= /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter )`
   exatamente como nos exemplos.
5. Criar UM método `FOR TESTING RAISING cx_static_check` para CADA comportamento que a classe principal
   sobrescreve. Olhe o código da classe principal e cubra:
   - `get_rps_identificacao`: se fixa `tipo_rps`, testar `tipo_rps`; se trata série (IS INITIAL -> valor),
     testar os DOIS casos (série vazia e série preenchida via `doc->set_series`); se ajusta natureza_operacao
     ou competência, testar também.
   - `/s4tax/infse_data~get_reasons_cancellation`: testar cada código tratado (1..5) e o caso default,
     conferindo `code` e/ou `motivo` conforme a implementação.
   - Qualquer outro método redefinido (get_rps_servico, get_rps_tomador etc.).
6. Use SOMENTE helpers/membros listados na "Classe base de testes" — não invente métodos.
7. NUNCA usar inline declarations, VALUE #(), NEW #(), COND #() — compatibilidade ABAP < 7.40.
   (Declare `DATA` no início do método e atribua separadamente; use `CREATE OBJECT`.)
8. Sem prefixos húngaros em variáveis.
9. Retornar SOMENTE o código ABAP — sem markdown, sem texto antes ou depois.
10. Terminar com o `ENDCLASS.` da IMPLEMENTATION.
"""


def clean_generated_test(raw: str) -> str:
    """Limpa o output do Claude para o include de teste."""
    # Remove markdown
    raw = re.sub(r"^```(?:abap)?\s*\n", "", raw.strip(), flags=re.MULTILINE)
    raw = re.sub(r"\n```\s*$", "", raw.strip(), flags=re.MULTILINE)

    # Remove texto antes do cabeçalho do include (*&) ou da definição da classe local
    header_match = re.search(r'^\*&-+\*', raw, re.MULTILINE)
    class_match  = re.search(r'^CLASS\s+ltcl_', raw, re.MULTILINE | re.IGNORECASE)
    start = None
    if header_match:
        start = header_match.start()
    elif class_match:
        start = class_match.start()
    if start is not None:
        raw = raw[start:]

    # Remove texto após o ÚLTIMO ENDCLASS.
    endclass_matches = list(re.finditer(r'^ENDCLASS\.', raw, re.MULTILINE))
    if endclass_matches:
        raw = raw[:endclass_matches[-1].end()]

    return raw.strip()


def validate_test(code: str, class_name: str, ltcl_name: str) -> list:
    errors = []
    if f"CLASS {ltcl_name} DEFINITION" not in code:
        errors.append(f"Falta 'CLASS {ltcl_name} DEFINITION'")
    if "FOR TESTING" not in code:
        errors.append("Falta 'FOR TESTING'")
    if "INHERITING FROM /s4tax/nfse_default_test" not in code:
        errors.append("Falta herança de /s4tax/nfse_default_test")
    if f"TYPE REF TO {class_name}" not in code:
        errors.append(f"Falta declaração 'cut TYPE REF TO {class_name}'")
    if "FOR TESTING" in code and "cl_abap_unit_assert" not in code:
        errors.append("Nenhuma asserção cl_abap_unit_assert encontrada")
    if code.count("ENDCLASS.") < 2:
        errors.append("Falta ENDCLASS. da IMPLEMENTATION (esperados 2)")
    return errors


def generate_test_class(
    city: str, uf: str, ibge_code: str,
    class_name: str, class_code: str,
    test_examples: str, eft_text: str,
    force: bool,
) -> dict:
    """Gera o include de teste (.prog.abap + .prog.xml). Retorna dict com status."""
    uf_lower    = uf.lower()
    ltcl_name   = f"ltcl_nfse_{uf_lower}{ibge_code}"
    base_file   = f"#s4tax#nfse_{uf_lower}{ibge_code}_t99"
    abap_path   = OUTPUT_DIR / f"{base_file}.prog.abap"

    result = {"status": "error", "output_file": None, "error": None}

    if abap_path.exists() and not force:
        print(f"  [PULAR] {abap_path.name} já existe. Use --force para regenerar.")
        result["status"] = "skipped"
        result["output_file"] = str(abap_path)
        return result

    print(f"  Gerando teste: {abap_path.name} ({AI_PROVIDER} CLI) ...")
    try:
        prompt = build_test_prompt(
            city, uf, ibge_code, class_name, class_code, test_examples, eft_text
        )
        raw = call_provider(prompt, timeout=180)
        code = clean_generated_test(raw)
    except Exception as e:
        result["error"] = f"Erro na chamada ao {AI_PROVIDER} CLI (teste): {e}"
        return result

    errors = validate_test(code, class_name, ltcl_name)
    if errors:
        invalid_path = OUTPUT_DIR / (abap_path.name + ".invalid")
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        invalid_path.write_text(code, encoding="utf-8")
        result["error"] = (
            f"Validação do teste falhou: {'; '.join(errors)}\n"
            f"  Código salvo em: {invalid_path.name} (revisar manualmente)"
        )
        return result

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    abap_path.write_text(code, encoding="utf-8")

    result["status"] = "created"
    result["output_file"] = str(abap_path)
    print(f"  [OK] {abap_path.name}")
    return result


# ---------------------------------------------------------------------------
# Atualização de lista_prontos.md
# ---------------------------------------------------------------------------

def update_lista_prontos(city: str, uf: str, ibge_code: str) -> None:
    """Adiciona ou atualiza entrada do município na tabela lista_prontos.md."""
    if not LISTA_MD.exists():
        print(f"  [AVISO] {LISTA_MD} não encontrado — não será atualizado.")
        return

    content = LISTA_MD.read_text(encoding="utf-8")
    today = datetime.now().strftime("%Y-%m-%d")
    entry_key = f"{city} - {uf.upper()}"
    new_row = f"| {entry_key} | {ibge_code} | {today} | {today} |"

    lines = content.splitlines()
    updated = False

    for i, line in enumerate(lines):
        if f"| {entry_key} |" in line or f"|{entry_key}|" in line:
            # Atualiza coluna "Ultima modificacao" (4a coluna)
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 5:
                parts[4] = today
                lines[i] = "| " + " | ".join(parts[1:-1]) + " |"
            updated = True
            break

    if not updated:
        # Adiciona nova linha ao final da tabela
        lines.append(new_row)

    LISTA_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    action = "atualizado" if updated else "adicionado"
    print(f"  [OK] lista_prontos.md: {entry_key} {action}.")


# ---------------------------------------------------------------------------
# Processamento de um arquivo EFT
# ---------------------------------------------------------------------------

def process_eft_file(
    txt_path: Path,
    ibge_data: dict,
    architecture: str,
    claude_md: str,
    examples: str,
    test_examples: str,
    force: bool,
    gen_tests: bool = True,
) -> dict:
    """Processa um .txt de EFT e gera o .clas.abap (+ classe de teste) correspondente."""
    result = {
        "file": txt_path.name,
        "status": "error",
        "city": None,
        "uf": None,
        "ibge_code": None,
        "output_file": None,
        "error": None,
        "test_status": "skipped",
        "test_file": None,
        "test_error": None,
    }

    # 1. Parsear município + UF do nome do arquivo
    parsed = parse_eft_filename(txt_path.stem)
    if not parsed:
        result["error"] = f"Não conseguiu parsear município/UF: '{txt_path.stem}'"
        return result

    city, uf = parsed
    result["city"] = city
    result["uf"] = uf

    # 2. Buscar código IBGE
    ibge_code, matched_name = find_ibge_code(ibge_data, city, uf)
    if not ibge_code:
        result["error"] = (
            f"Código IBGE não encontrado para '{city}' ({uf}). "
            "Verifique ibge_codes.json ou adicione manualmente."
        )
        return result

    result["ibge_code"] = ibge_code
    if matched_name and normalize(city) != matched_name:
        print(f"    [AVISO] Match fuzzy: '{city}' -> '{matched_name}' ({ibge_code})")

    # 3. Verificar se já existe
    uf_lower = uf.lower()
    out_filename = f"#s4tax#nfse_{uf_lower}{ibge_code}.clas.abap"
    out_path = OUTPUT_DIR / out_filename

    eft_text = txt_path.read_text(encoding="utf-8")
    class_name  = f"/s4tax/nfse_{uf_lower}{ibge_code}"
    tax_address = f"{uf.upper()} {ibge_code}"

    if out_path.exists() and not force:
        print(f"  [PULAR] {out_filename} já existe. Use --force para regenerar.")
        result["status"] = "skipped"
        result["output_file"] = str(out_path)
        # Mesmo com a classe já existente, gera o teste se ainda não houver
        if gen_tests:
            existing_code = out_path.read_text(encoding="utf-8")
            test_res = generate_test_class(
                city, uf, ibge_code, class_name, existing_code,
                test_examples, eft_text, force
            )
            result["test_status"] = test_res["status"]
            result["test_file"]   = test_res["output_file"]
            result["test_error"]  = test_res["error"]
        return result

    # 4. Gerar classe via CLI de IA selecionada

    print(f"  Gerando: {out_filename} ({AI_PROVIDER} CLI) ...")
    try:
        prompt = build_generation_prompt(
            city, uf, ibge_code, eft_text, architecture, claude_md, examples
        )
        raw_code = call_provider(prompt, timeout=180)
        code = clean_generated_code(raw_code, city, uf)
    except Exception as e:
        result["error"] = f"Erro na chamada ao {AI_PROVIDER} CLI: {e}"
        return result

    # 5. Validar
    errors = validate(code, class_name, tax_address)
    if errors:
        result["error"] = f"Validação falhou: {'; '.join(errors)}"
        invalid_path = OUTPUT_DIR / (out_filename + ".invalid")
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        invalid_path.write_text(code, encoding="utf-8")
        result["error"] += f"\n  Código salvo em: {invalid_path.name} (revisar manualmente)"
        return result

    # 6. Salvar arquivo
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path.write_text(code, encoding="utf-8")
    result["status"] = "created"
    result["output_file"] = str(out_path)
    print(f"  [OK] {out_filename}")

    # 7. Atualizar lista_prontos.md
    update_lista_prontos(city, uf, ibge_code)

    # 8. Gerar a classe de teste correspondente
    if gen_tests:
        test_res = generate_test_class(
            city, uf, ibge_code, class_name, code,
            test_examples, eft_text, force
        )
        result["test_status"] = test_res["status"]
        result["test_file"]   = test_res["output_file"]
        result["test_error"]  = test_res["error"]
        if test_res["error"]:
            print(f"  [ERRO-TESTE] {test_res['error']}")

    return result


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    global AI_PROVIDER, AI_MODEL

    print("=== Etapa 3: Geração de Classes ABAP ===\n")

    try:
        AI_PROVIDER = validate_provider(option_value(sys.argv, "--provider", DEFAULT_PROVIDER))
        AI_MODEL = option_value(sys.argv, "--model")
        version = check_provider(AI_PROVIDER)
    except (ValueError, RuntimeError) as e:
        print(f"ERRO: {e}")
        sys.exit(1)
    print(f"  Provedor IA: {AI_PROVIDER} ({version})")
    print(f"  Modelo:      {AI_MODEL or 'padrao da CLI'}")

    # Diretório dos .txt (pode ser sobrescrito via --efts-dir)
    input_dir = ROOT_DIR / "EFTs txt"
    if "--efts-dir" in sys.argv:
        idx = sys.argv.index("--efts-dir")
        if idx + 1 < len(sys.argv):
            input_dir = Path(sys.argv[idx + 1])

    if not input_dir.exists():
        print(f"ERRO: Pasta de EFTs em texto não encontrada: {input_dir}")
        sys.exit(1)

    txt_count = len(list(input_dir.glob("*.txt")))
    print(f"  Fonte dos EFTs: {input_dir} ({txt_count} arquivo(s))")

    if not IBGE_FILE.exists():
        print(f"ERRO: {IBGE_FILE} não encontrado.")
        print("  Execute primeiro: python src/scripts/1_scrape_ibge.py")
        sys.exit(1)

    force = "--force" in sys.argv
    gen_tests = "--no-tests" not in sys.argv   # por padrão gera a classe de teste também
    only = None
    if "--only" in sys.argv:
        idx = sys.argv.index("--only")
        if idx + 1 < len(sys.argv):
            only = sys.argv[idx + 1]

    # Carregamento de contexto
    print("Carregando contexto (arquitetura, CLAUDE.md, exemplos)...")
    architecture  = load_text_file(NFSE_MD, "nfse-municipios.md")
    claude_md     = load_text_file(CLAUDE_MD, "CLAUDE.md")
    repo_src      = find_repo_src()
    examples      = load_few_shot_examples(repo_src)
    tests_repo    = find_tests_repo_src()
    test_examples = load_test_few_shot_examples(tests_repo) if gen_tests else ""
    print(f"  Arquitetura:      {'OK' if architecture else 'NAO ENCONTRADO'}")
    print(f"  CLAUDE.md:        {'OK' if claude_md else 'NAO ENCONTRADO'}")
    print(f"  Exemplos classe:  {'OK' if examples else 'NENHUM'}")
    if gen_tests:
        print(f"  Exemplos teste:   {'OK' if test_examples else 'NENHUM'}")
    else:
        print(f"  Geração de teste: DESATIVADA (--no-tests)")

    # Dados IBGE
    with open(IBGE_FILE, encoding="utf-8") as f:
        ibge_data = json.load(f)

    # Listar arquivos EFT
    txt_files = [f for f in sorted(input_dir.glob("*.txt")) if f.name != "README.md"]
    if not txt_files:
        print(f"Nenhum arquivo .txt encontrado em {input_dir}")
        sys.exit(0)

    if only:
        only_norm = normalize(only)
        txt_files = [f for f in txt_files if only_norm in normalize(f.stem)]
        if not txt_files:
            print(f"ERRO: Nenhum arquivo encontrado com '{only}' no nome.")
            sys.exit(1)

    print(f"\nProcessando {len(txt_files)} arquivo(s) de EFT...\n")

    results = []
    for txt_path in txt_files:
        print(f"-> {txt_path.name}")
        r = process_eft_file(
            txt_path, ibge_data, architecture, claude_md,
            examples, test_examples, force, gen_tests
        )
        results.append(r)
        if r.get("error"):
            print(f"  [ERRO] {r['error']}")
        print()

    # Relatório final
    created = [r for r in results if r["status"] == "created"]
    skipped = [r for r in results if r["status"] == "skipped"]
    errors  = [r for r in results if r["status"] == "error"]

    tests_created = [r for r in results if r.get("test_status") == "created"]
    tests_errors  = [r for r in results if r.get("test_error")]

    print("=" * 60)
    print(f"RELATORIO: {len(created)} criado(s) | {len(skipped)} pulado(s) | {len(errors)} erro(s)")
    if gen_tests:
        print(f"  TESTES:  {len(tests_created)} criado(s) | {len(tests_errors)} com erro")
    print("=" * 60)

    if created:
        print("\nCriados:")
        for r in created:
            print(f"  [OK] {r['city']} ({r['uf']}) -> {Path(r['output_file']).name}")
            if r.get("test_status") == "created" and r.get("test_file"):
                print(f"       + teste: {Path(r['test_file']).name}")

    if skipped:
        print("\nPulados (já existiam):")
        for r in skipped:
            extra = ""
            if r.get("test_status") == "created" and r.get("test_file"):
                extra = f" (teste gerado: {Path(r['test_file']).name})"
            print(f"  [PULAR] {r['city']} ({r['uf']}){extra}")

    if errors:
        print("\nErros:")
        for r in errors:
            print(f"  [ERRO] {r['file']}: {r['error']}")

    if tests_errors:
        print("\nErros na geração de testes:")
        for r in tests_errors:
            print(f"  [ERRO-TESTE] {r['city']} ({r['uf']}): {r['test_error']}")

    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
