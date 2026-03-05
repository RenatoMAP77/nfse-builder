"""
3_generate_classes.py
Gera arquivos .clas.abap para municípios usando o claude CLI local.
Lê os .txt de "EFTs txt/" (ou --efts-dir), busca o código IBGE em ibge_codes.json
e chama o claude CLI para gerar o código ABAP.

Uso:
  python 3_generate_classes.py [--only "Caçador SC"] [--force] [--efts-dir CAMINHO]
  --only: processa apenas o município/UF informado (ex: "Caçador SC")
  --force: regera mesmo se o .clas.abap já existir
  --efts-dir: pasta com os .txt de EFT (padrão: <raiz>/EFTs txt)

Não requer nenhuma variável de ambiente — usa claude CLI local.
"""
import difflib
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

SCRIPT_DIR  = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent.parent          # claude_abap/

OUTPUT_DIR  = SCRIPT_DIR / "Municipios Prontos"
IBGE_FILE   = SCRIPT_DIR / "ibge_codes.json"
NFSE_MD     = PROJECT_DIR / "nfse-municipios.md"
CLAUDE_MD   = PROJECT_DIR / "CLAUDE.md"
LISTA_MD    = SCRIPT_DIR / "Municipios Prontos" / "lista_prontos.md"

# Exemplos few-shot preferidos (buscados dinamicamente no repo)
FEW_SHOT_PREFERRED = [
    "#s4tax#nfse_rj3304557.clas.abap",
    "#s4tax#nfse_ce2304400.clas.abap",
]

# Regex para extrair (cidade, UF) do nome do arquivo EFT
FILENAME_PATTERNS = [
    re.compile(r"NFSe?\s+(.+?)\s+-\s+([A-Z]{2})", re.IGNORECASE),
    re.compile(r"NFSe?_(.+?)_([A-Z]{2})(?:\.txt)?$", re.IGNORECASE),
]


# ---------------------------------------------------------------------------
# Claude CLI helper
# ---------------------------------------------------------------------------

def call_claude(prompt: str, timeout: int = 180) -> str:
    """Chama o claude CLI via stdin (evita limite de tamanho do argumento no Windows)."""
    if not shutil.which("claude"):
        raise RuntimeError(
            "claude CLI não encontrado no PATH. "
            "Execute: npm install -g @anthropic-ai/claude-code"
        )
    # Remove CLAUDECODE para permitir chamada aninhada a partir do Claude Code
    env = os.environ.copy()
    env.pop("CLAUDECODE", None)
    result = subprocess.run(
        ["claude", "--print"],
        input=prompt,
        env=env,
        capture_output=True, text=True, encoding="utf-8", timeout=timeout
    )
    if result.returncode != 0:
        raise RuntimeError(f"claude CLI erro: {result.stderr[:500]}")
    return result.stdout.strip()


# ---------------------------------------------------------------------------
# Helpers de normalização e busca IBGE
# ---------------------------------------------------------------------------

def normalize(name: str) -> str:
    nfkd = unicodedata.normalize("NFKD", name)
    return "".join(c for c in nfkd if not unicodedata.combining(c)).lower().strip()


def parse_eft_filename(stem: str) -> tuple[str, str] | None:
    """Extrai (cidade, UF) do nome do arquivo sem extensão. None se falhar."""
    for pattern in FILENAME_PATTERNS:
        m = pattern.search(stem)
        if m:
            city = m.group(1).strip().replace("_", " ")
            uf = m.group(2).upper()
            return city, uf
    return None


def find_ibge_code(ibge_data: dict, city: str, uf: str) -> tuple[str | None, str | None]:
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


def find_repo_src() -> Path | None:
    candidates = list(PROJECT_DIR.glob("repositorios/orbitspot-s4tax_nfse-*/src"))
    return candidates[0] if candidates else None


def load_few_shot_examples(repo_src: Path | None) -> str:
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

1. Herdar SEMPRE de `/s4tax/nfse_default`
2. Declarar `CONSTANTS tax_address TYPE string VALUE '{tax_addr}'.`
3. Sobrescrever APENAS os métodos que o EFT indica comportamento diferente
4. Sempre chamar `super->método( )` primeiro em cada override (exceto `get_reasons_cancellation`)
5. NUNCA usar inline declarations, VALUE #(), NEW #(), COND #() — compatibilidade ABAP < 7.40
6. Sem prefixos húngaros em variáveis (sem lo_, lv_, lt_ etc.)
7. `get_reasons_cancellation` é de interface: declarar como `/s4tax/infse_data~get_reasons_cancellation REDEFINITION`
8. Retornar SOMENTE o código ABAP — sem markdown, sem texto antes ou depois
9. Começar com `CLASS {class_name} DEFINITION` e terminar com `ENDCLASS.`
"""


def clean_generated_code(raw: str, city: str, uf: str) -> str:
    """
    Limpa o output do Claude:
    - Remove blocos markdown (```abap ... ```)
    - Remove qualquer texto antes de 'CLASS /s4tax/'
    - Remove qualquer texto após 'ENDCLASS.'
    - Garante o comentário '\" Cidade/UF' após CREATE PUBLIC.
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


def validate(code: str, class_name: str, tax_address: str) -> list[str]:
    errors = []
    if f"CLASS {class_name} DEFINITION" not in code:
        errors.append(f"Falta 'CLASS {class_name} DEFINITION'")
    if "INHERITING FROM /s4tax/nfse_default" not in code:
        errors.append("Falta herança de /s4tax/nfse_default")
    if tax_address not in code:
        errors.append(f"Falta constante tax_address '{tax_address}'")
    if "IMPLEMENTATION" not in code:
        errors.append("Falta seção IMPLEMENTATION")
    if code.count("ENDCLASS.") < 2:
        errors.append("Falta ENDCLASS. da IMPLEMENTATION (esperados 2)")
    return errors


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
            # Atualiza coluna "Ultima modificação" (4ª coluna)
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
    force: bool,
) -> dict:
    """Processa um .txt de EFT e gera o .clas.abap correspondente."""
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

    if out_path.exists() and not force:
        print(f"  [PULAR] {out_filename} já existe. Use --force para regenerar.")
        result["status"] = "skipped"
        result["output_file"] = str(out_path)
        return result

    # 4. Gerar classe via claude CLI
    eft_text = txt_path.read_text(encoding="utf-8")
    class_name  = f"/s4tax/nfse_{uf_lower}{ibge_code}"
    tax_address = f"{uf.upper()} {ibge_code}"

    print(f"  Gerando: {out_filename} (claude CLI) ...")
    try:
        prompt = build_generation_prompt(
            city, uf, ibge_code, eft_text, architecture, claude_md, examples
        )
        raw_code = call_claude(prompt, timeout=180)
        code = clean_generated_code(raw_code, city, uf)
    except Exception as e:
        result["error"] = f"Erro na chamada ao claude CLI: {e}"
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

    return result


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("=== Etapa 3: Geração de Classes ABAP ===\n")

    if not shutil.which("claude"):
        print("ERRO: claude CLI não encontrado.")
        print("  Instale com: npm install -g @anthropic-ai/claude-code")
        sys.exit(1)

    # Diretório dos .txt (pode ser sobrescrito via --efts-dir)
    input_dir = SCRIPT_DIR / "EFTs txt"
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
        print("  Execute primeiro: python 1_scrape_ibge.py")
        sys.exit(1)

    force = "--force" in sys.argv
    only = None
    if "--only" in sys.argv:
        idx = sys.argv.index("--only")
        if idx + 1 < len(sys.argv):
            only = sys.argv[idx + 1]

    # Carregamento de contexto
    print("Carregando contexto (arquitetura, CLAUDE.md, exemplos)...")
    architecture = load_text_file(NFSE_MD, "nfse-municipios.md")
    claude_md    = load_text_file(CLAUDE_MD, "CLAUDE.md")
    repo_src     = find_repo_src()
    examples     = load_few_shot_examples(repo_src)
    print(f"  Arquitetura: {'OK' if architecture else 'NÃO ENCONTRADO'}")
    print(f"  CLAUDE.md:   {'OK' if claude_md else 'NÃO ENCONTRADO'}")
    print(f"  Exemplos:    {len([e for e in [examples] if e])} carregados")

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
        r = process_eft_file(txt_path, ibge_data, architecture, claude_md, examples, force)
        results.append(r)
        if r.get("error"):
            print(f"  [ERRO] {r['error']}")
        print()

    # Relatório final
    created = [r for r in results if r["status"] == "created"]
    skipped = [r for r in results if r["status"] == "skipped"]
    errors  = [r for r in results if r["status"] == "error"]

    print("=" * 60)
    print(f"RELATÓRIO: {len(created)} criado(s) | {len(skipped)} pulado(s) | {len(errors)} erro(s)")
    print("=" * 60)

    if created:
        print("\nCriados:")
        for r in created:
            print(f"  [OK] {r['city']} ({r['uf']}) -> {Path(r['output_file']).name}")

    if skipped:
        print("\nPulados (já existiam):")
        for r in skipped:
            print(f"  [PULAR] {r['city']} ({r['uf']})")

    if errors:
        print("\nErros:")
        for r in errors:
            print(f"  [ERRO] {r['file']}: {r['error']}")

    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
