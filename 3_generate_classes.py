"""
3_generate_classes.py
Gera arquivos .clas.abap para municípios usando Claude API.
Lê os .txt de EFTs_text/, busca o código IBGE em ibge_codes.json
e chama a API do Claude para gerar o código ABAP.

Uso:
  python 3_generate_classes.py [--only "Caçador SC"] [--force]
  --only: processa apenas o município/UF informado (ex: "Caçador SC" ou "cacador_SC")
  --force: regera mesmo se o .clas.abap já existir

Variável de ambiente necessária: ANTHROPIC_API_KEY
"""
import difflib
import json
import os
import re
import sys
import unicodedata
from pathlib import Path

import anthropic

# Carrega variáveis de ambiente (.env ou prompt interativo)
sys.path.insert(0, str(Path(__file__).parent))
from _env import load_env

BASE_DIR = Path(__file__).parent.parent
INPUT_DIR = BASE_DIR / "EFTs_text"
OUTPUT_DIR = BASE_DIR / "municipios_novos"
IBGE_FILE = Path(__file__).parent / "ibge_codes.json"
NFSE_MD = BASE_DIR / "nfse-municipios.md"
REPO_SRC = (
    BASE_DIR
    / "repositorios"
    / "orbitspot-s4tax_nfse-8bd75d03315f412fd631edb4e617f4afde972e01"
    / "src"
)

# Exemplos de classes para few-shot (nome do arquivo no repositório)
FEW_SHOT_EXAMPLES = [
    "#s4tax#nfse_rj3304557.clas.abap",  # Exemplo completo com vários overrides
    "#s4tax#nfse_ce2304400.clas.abap",  # Exemplo simples (só identificacao)
    "#s4tax#nfse_mg3106200.clas.abap",  # Exemplo médio
]

# Regex para extrair cidade e UF do nome do arquivo EFT
# Padrão: "COGNA_EFT - NFSe Caçador - SC.txt"
# ou: "COGNA_EFT_NFSe_Santa_Cruz_do_Capibaribe_PE.txt"
FILENAME_PATTERNS = [
    re.compile(r"NFSe?\s+(.+?)\s+-\s+([A-Z]{2})", re.IGNORECASE),
    re.compile(r"NFSe?_(.+?)_([A-Z]{2})", re.IGNORECASE),
]


def normalize(name: str) -> str:
    """Remove acentos, converte para lowercase, para comparação fuzzy."""
    nfkd = unicodedata.normalize("NFKD", name)
    ascii_str = "".join(c for c in nfkd if not unicodedata.combining(c))
    return ascii_str.lower().strip()


def parse_eft_filename(stem: str) -> tuple[str, str] | None:
    """
    Extrai (cidade, UF) do nome do arquivo sem extensão.
    Retorna None se não conseguir parsear.
    """
    for pattern in FILENAME_PATTERNS:
        m = pattern.search(stem)
        if m:
            city = m.group(1).strip().replace("_", " ")
            uf = m.group(2).upper()
            return city, uf
    return None


def find_ibge_code(
    ibge_data: dict, city: str, uf: str
) -> tuple[str | None, str | None]:
    """
    Busca o código IBGE para (cidade, UF).
    Retorna (ibge_code, matched_name) ou (None, None).
    Tenta match exato por nome normalizado e depois fuzzy.
    """
    state_data = ibge_data.get(uf.upper(), {})
    if not state_data:
        return None, None

    city_norm = normalize(city)

    # Match exato
    if city_norm in state_data:
        return state_data[city_norm], city_norm

    # Match fuzzy (difflib)
    candidates = list(state_data.keys())
    matches = difflib.get_close_matches(city_norm, candidates, n=1, cutoff=0.7)
    if matches:
        best = matches[0]
        return state_data[best], best

    return None, None


def load_few_shot_examples() -> str:
    """Carrega os exemplos de classes existentes para o prompt."""
    examples = []
    for fname in FEW_SHOT_EXAMPLES:
        fpath = REPO_SRC / fname
        if fpath.exists():
            content = fpath.read_text(encoding="utf-8")
            examples.append(f"### Exemplo: {fname}\n```abap\n{content}\n```")
        else:
            print(f"  [AVISO] Exemplo não encontrado: {fpath}")
    return "\n\n".join(examples)


def load_nfse_architecture() -> str:
    """Carrega o conteúdo relevante do nfse-municipios.md."""
    if NFSE_MD.exists():
        content = NFSE_MD.read_text(encoding="utf-8")
        # Retorna as seções mais relevantes (limitando tamanho)
        # Seções 9, 10, 12 são as mais importantes para geração
        return content
    return ""


def build_system_prompt(architecture: str, examples: str) -> str:
    return f"""Você é um especialista em ABAP S/4HANA que cria classes municipais NFS-e para o pacote /S4TAX/NFSE da Orbitspot/4TaxCloud.

## Arquitetura e Padrões

{architecture}

## Exemplos de Classes Municipais Existentes

{examples}

## Regras Obrigatórias

1. A classe DEVE herdar de `/s4tax/nfse_default`
2. DEVE declarar: `CONSTANTS tax_address TYPE string VALUE '{{UF}} {{IBGE}}'`
3. Sobrescreva APENAS os métodos que precisam de comportamento diferente do padrão
4. SEMPRE chame `super->método()` primeiro em cada override (exceto `get_reasons_cancellation`)
5. NUNCA use inline declarations (DATA(...)), VALUE #(), NEW #(), ou ABAP 7.40+
6. NUNCA adicione `FINAL` a menos que o EFT indique que não haverá subclasses
7. Use `string_utils`, `currency_utils` conforme padrão dos exemplos
8. O método `get_reasons_cancellation` é de interface: declare como `/s4tax/infse_data~get_reasons_cancellation REDEFINITION`
9. Gere APENAS o código ABAP — sem comentários explicativos externos, sem markdown, sem texto antes ou depois do código

## Formato de Saída

Retorne SOMENTE o conteúdo do arquivo .clas.abap, começando com `CLASS /s4tax/nfse_...` e terminando com `ENDCLASS.`
"""


def build_user_prompt(city: str, uf: str, ibge_code: str, eft_text: str) -> str:
    uf_lower = uf.lower()
    class_name = f"/s4tax/nfse_{uf_lower}{ibge_code}"
    file_name = f"#s4tax#nfse_{uf_lower}{ibge_code}.clas.abap"
    tax_addr = f"{uf.upper()} {ibge_code}"

    return f"""Crie a classe ABAP para o seguinte município:

- **Município:** {city} ({uf.upper()})
- **Código IBGE:** {ibge_code}
- **Nome da classe SAP:** {class_name}
- **Nome do arquivo:** {file_name}
- **Constante tax_address:** '{tax_addr}'

## Especificação Funcional (EFT) do Município

{eft_text}

---

Analise o EFT acima e gere apenas o código do arquivo `{file_name}`.
Implemente apenas os métodos necessários com base nas regras específicas descritas no EFT.
Se o EFT não descrever uma regra específica para determinado método, NÃO o sobrescreva.
"""


def validate_generated_code(code: str, class_name: str, tax_address: str) -> list[str]:
    """Valida estrutura mínima do código gerado. Retorna lista de erros."""
    errors = []
    if "CLASS " + class_name + " DEFINITION" not in code:
        errors.append(f"Falta 'CLASS {class_name} DEFINITION'")
    if "INHERITING FROM /s4tax/nfse_default" not in code:
        errors.append("Falta 'INHERITING FROM /s4tax/nfse_default'")
    if tax_address not in code:
        errors.append(f"Falta constante tax_address com valor '{tax_address}'")
    if "ENDCLASS." not in code:
        errors.append("Falta 'ENDCLASS.'")
    if "IMPLEMENTATION" not in code:
        errors.append("Falta seção IMPLEMENTATION")
    return errors


def clean_generated_code(raw: str) -> str:
    """Remove possíveis blocos markdown do output do Claude."""
    # Remove ```abap ... ``` ou ``` ... ```
    raw = re.sub(r"^```(?:abap)?\s*\n", "", raw.strip(), flags=re.MULTILINE)
    raw = re.sub(r"\n```\s*$", "", raw.strip(), flags=re.MULTILINE)
    return raw.strip()


def generate_class(
    client: anthropic.Anthropic,
    city: str,
    uf: str,
    ibge_code: str,
    eft_text: str,
    architecture: str,
    examples: str,
) -> str:
    """Chama a API do Claude e retorna o código ABAP gerado."""
    system_prompt = build_system_prompt(architecture, examples)
    user_prompt = build_user_prompt(city, uf, ibge_code, eft_text)

    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=4096,
        system=system_prompt,
        messages=[{"role": "user", "content": user_prompt}],
    )

    return response.content[0].text


def process_eft_file(
    txt_path: Path,
    ibge_data: dict,
    client: anthropic.Anthropic,
    architecture: str,
    examples: str,
    force: bool,
) -> dict:
    """
    Processa um arquivo .txt de EFT.
    Retorna dict com resultado: {status, city, uf, ibge_code, output_file, error}
    """
    result = {
        "file": txt_path.name,
        "status": "error",
        "city": None,
        "uf": None,
        "ibge_code": None,
        "output_file": None,
        "error": None,
    }

    # 1. Parsear município + UF do nome do arquivo
    parsed = parse_eft_filename(txt_path.stem)
    if not parsed:
        result["error"] = f"Não conseguiu parsear município/UF do nome: '{txt_path.stem}'"
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
        print(f"    [AVISO] Match fuzzy: '{city}' → '{matched_name}' ({ibge_code})")

    # 3. Verificar se já existe
    uf_lower = uf.lower()
    out_filename = f"#s4tax#nfse_{uf_lower}{ibge_code}.clas.abap"
    out_path = OUTPUT_DIR / out_filename

    if out_path.exists() and not force:
        print(f"  [PULAR] {out_filename} já existe. Use --force para regenerar.")
        result["status"] = "skipped"
        result["output_file"] = str(out_path)
        return result

    # 4. Gerar classe via Claude
    eft_text = txt_path.read_text(encoding="utf-8")
    class_name = f"/s4tax/nfse_{uf_lower}{ibge_code}"
    tax_address = f"{uf.upper()} {ibge_code}"

    print(f"  Gerando: {out_filename} (Claude API) ...")
    try:
        raw_code = generate_class(client, city, uf, ibge_code, eft_text, architecture, examples)
        code = clean_generated_code(raw_code)
    except Exception as e:
        result["error"] = f"Erro na chamada ao Claude: {e}"
        return result

    # 5. Validar código gerado
    errors = validate_generated_code(code, class_name, tax_address)
    if errors:
        result["error"] = f"Validação falhou: {'; '.join(errors)}"
        # Salva mesmo assim com sufixo .invalid para revisão manual
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
    return result


def main():
    print("=== Etapa 3: Geração de Classes ABAP ===\n")
    load_env(["ANTHROPIC_API_KEY"])

    if not IBGE_FILE.exists():
        print(
            f"ERRO: {IBGE_FILE} não encontrado. "
            "Execute primeiro: python 1_scrape_ibge.py"
        )
        sys.exit(1)

    if not INPUT_DIR.exists():
        print(f"ERRO: Pasta {INPUT_DIR} não encontrada.")
        sys.exit(1)

    force = "--force" in sys.argv
    only = None
    if "--only" in sys.argv:
        idx = sys.argv.index("--only")
        if idx + 1 < len(sys.argv):
            only = sys.argv[idx + 1]

    # Carregar dados IBGE
    with open(IBGE_FILE, encoding="utf-8") as f:
        ibge_data = json.load(f)

    # Carregar arquitetura e exemplos (carregados uma vez)
    print("Carregando contexto de arquitetura e exemplos...")
    architecture = load_nfse_architecture()
    examples = load_few_shot_examples()

    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    # Listar arquivos EFT para processar
    txt_files = list(INPUT_DIR.glob("*.txt"))
    if not txt_files:
        print(f"Nenhum arquivo .txt encontrado em {INPUT_DIR}")
        sys.exit(0)

    if only:
        only_norm = normalize(only)
        txt_files = [
            f for f in txt_files
            if only_norm in normalize(f.stem)
        ]
        if not txt_files:
            print(f"ERRO: Nenhum arquivo encontrado com '{only}' no nome.")
            sys.exit(1)

    print(f"Processando {len(txt_files)} arquivo(s) de EFT...\n")

    results = []
    for txt_path in sorted(txt_files):
        print(f"→ {txt_path.name}")
        r = process_eft_file(txt_path, ibge_data, client, architecture, examples, force)
        results.append(r)
        if r.get("error"):
            print(f"  [ERRO] {r['error']}")
        print()

    # Relatório final
    created = [r for r in results if r["status"] == "created"]
    skipped = [r for r in results if r["status"] == "skipped"]
    errors = [r for r in results if r["status"] == "error"]

    print("=" * 60)
    print(f"RELATÓRIO: {len(created)} criados | {len(skipped)} pulados | {len(errors)} erros")
    print("=" * 60)

    if created:
        print("\nCriados:")
        for r in created:
            print(f"  ✓ {r['city']} ({r['uf']}) → {Path(r['output_file']).name}")

    if errors:
        print("\nErros:")
        for r in errors:
            print(f"  ✗ {r['file']}: {r['error']}")

    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
