"""
run_municipios.py — Orquestrador do pipeline de criação de classes municipais NFS-e

Pipeline:
  1. Scraping IBGE      → ibge_codes.json
  2. Conversão EFT→TXT  → "EFTs txt/"  (PDF/DOCX via claude CLI)
  3. Geração ABAP       → "Municipios Prontos/"  (via claude CLI)

Uso:
  python run_municipios.py [opções]

Opções:
  --skip-ibge           Pula scraping do IBGE (usa ibge_codes.json existente)
  --skip-convert        Pula conversão EFT e usa "EFTs txt/" existente
  --use-existing-efts   Pula conversão EFT e usa a pasta pré-convertida:
                          <raiz>/EFTs txt/
  --only "Cidade UF"    Processa apenas esse município
  --force               Reprocessa arquivos existentes
  --dry-run             Mostra o que faria, sem executar
  --deploy              Executa também deploy SAP (chama 4_deploy_to_sap.py se existir)
  --transport XXX       Número do transporte SAP (padrão: $TMP)
  --yes                 Pula confirmações no deploy

Não requer variáveis de ambiente — toda IA usa o claude CLI local.
Certifique-se de que 'claude' está no PATH: npm install -g @anthropic-ai/claude-code
"""
import shutil
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent

STEP1 = SCRIPT_DIR / "1_scrape_ibge.py"
STEP2 = SCRIPT_DIR / "2_convert_efts.py"
STEP3 = SCRIPT_DIR / "3_generate_classes.py"
STEP4 = SCRIPT_DIR / "4_deploy_to_sap.py"

# Pasta com .txt já prontos (pré-convertidos)
PREBUILT_EFTS_DIR = SCRIPT_DIR / "EFTs txt"
LISTA_MD = SCRIPT_DIR / "Municipios Prontos" / "lista_prontos.md"


# ---------------------------------------------------------------------------
# Verificação de pré-requisitos
# ---------------------------------------------------------------------------

def check_prerequisites():
    if not shutil.which("claude"):
        print("ERRO: 'claude' CLI não encontrado.")
        print("  Instale com: npm install -g @anthropic-ai/claude-code")
        sys.exit(1)
    result = subprocess.run(
        ["claude", "--version"], capture_output=True, text=True, timeout=10
    )
    if result.returncode != 0:
        print("ERRO: claude CLI instalado mas não funcionando corretamente.")
        sys.exit(1)
    print(f"  claude CLI: OK ({result.stdout.strip()})")


# ---------------------------------------------------------------------------
# Resolução da pasta de EFTs em texto
# ---------------------------------------------------------------------------

def resolve_efts_text_dir(args: list[str]) -> tuple[Path, str]:
    """
    Retorna (pasta_dos_txt, descrição) conforme as flags passadas.
    Prioridade: --use-existing-efts > --skip-convert > conversão normal
    """
    if "--use-existing-efts" in args:
        if not PREBUILT_EFTS_DIR.exists():
            print(f"ERRO: Pasta de EFTs pré-convertidas não encontrada:")
            print(f"  {PREBUILT_EFTS_DIR}")
            sys.exit(1)
        txt_count = len([
            f for f in PREBUILT_EFTS_DIR.glob("*.txt")
            if f.name != "README.md"
        ])
        return PREBUILT_EFTS_DIR, f"usando pasta pré-convertida ({txt_count} arquivo(s))"

    if "--skip-convert" in args:
        efts_text = SCRIPT_DIR / "EFTs txt"
        txt_count = len([
            f for f in efts_text.glob("*.txt") if f.name != "README.md"
        ]) if efts_text.exists() else 0
        return efts_text, f"usando 'EFTs txt/' existente ({txt_count} arquivo(s))"

    # Conversão normal (etapa 2)
    return SCRIPT_DIR / "EFTs txt", "converter EFTs (etapa 2)"


# ---------------------------------------------------------------------------
# Execução de etapas
# ---------------------------------------------------------------------------

def banner(text: str):
    print(f"\n{'=' * 60}")
    print(f"  {text}")
    print(f"{'=' * 60}")


def run_step(label: str, script: Path, extra_args: list[str], dry_run: bool) -> bool:
    """Executa um script como subprocesso. Retorna True se sucesso."""
    banner(label)
    cmd = [sys.executable, str(script)] + extra_args
    print(f"Executando: {' '.join(str(c) for c in cmd)}\n")

    if dry_run:
        print("  [DRY-RUN] Não executado.")
        return True

    result = subprocess.run(cmd, check=False)
    if result.returncode != 0:
        print(f"\n[ERRO] {label} falhou com código {result.returncode}.")
        return False
    return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    args = sys.argv[1:]

    skip_ibge    = "--skip-ibge" in args
    skip_convert = "--skip-convert" in args or "--use-existing-efts" in args
    dry_run      = "--dry-run" in args
    force        = "--force" in args
    deploy       = "--deploy" in args
    yes          = "--yes" in args

    only = None
    if "--only" in args:
        idx = args.index("--only")
        if idx + 1 < len(args):
            only = args[idx + 1]

    transport = "$TMP"
    if "--transport" in args:
        idx = args.index("--transport")
        if idx + 1 < len(args):
            transport = args[idx + 1]

    # Cabeçalho
    print("\n" + "=" * 60)
    print("  AUTOMAÇÃO — Classes Municipais NFS-e")
    print("=" * 60)
    print(f"  Base:  {SCRIPT_DIR}")
    print(f"  Saída: {SCRIPT_DIR / 'Municipios Prontos'}")
    if only:
        print(f"  Filtro: '{only}' apenas")
    if dry_run:
        print("  MODO: DRY-RUN (nenhuma ação executada)")
    print()

    # Verificar claude CLI
    if not dry_run:
        print("Verificando pré-requisitos...")
        check_prerequisites()
        print()

    # Resolver pasta dos TXTs
    efts_dir, efts_desc = resolve_efts_text_dir(args)
    print(f"  EFTs txt: {efts_desc}")

    # -----------------------------------------------------------------------
    # Etapa 1: Scraping IBGE
    # -----------------------------------------------------------------------
    if not skip_ibge:
        ibge_args = ["--force"] if force else []
        ok = run_step("ETAPA 1: Scraping IBGE", STEP1, ibge_args, dry_run)
        if not ok:
            print("\nPipeline abortado na etapa 1.")
            sys.exit(1)
    else:
        ibge_file = SCRIPT_DIR / "ibge_codes.json"
        if not ibge_file.exists() and not dry_run:
            print("\nERRO: --skip-ibge informado mas ibge_codes.json não existe.")
            print("  Execute sem --skip-ibge primeiro.")
            sys.exit(1)
        print("\n[PULAR] Etapa 1: usando ibge_codes.json existente.")

    # -----------------------------------------------------------------------
    # Etapa 2: Conversão EFT → TXT
    # -----------------------------------------------------------------------
    if not skip_convert:
        conv_args = []
        if only:
            conv_args += ["--only", only]
        if force:
            conv_args.append("--force")
        ok = run_step("ETAPA 2: Conversão EFT → TXT (claude CLI)", STEP2, conv_args, dry_run)
        if not ok:
            print("\nPipeline abortado na etapa 2.")
            sys.exit(1)
    else:
        txt_count = len([
            f for f in efts_dir.glob("*.txt") if f.name != "README.md"
        ]) if efts_dir.exists() else 0
        print(f"\n[PULAR] Etapa 2: {efts_desc}.")

    # -----------------------------------------------------------------------
    # Etapa 3: Geração das classes ABAP via claude CLI
    # -----------------------------------------------------------------------
    gen_args = ["--efts-dir", str(efts_dir)]
    if only:
        gen_args += ["--only", only]
    if force:
        gen_args.append("--force")

    ok = run_step("ETAPA 3: Geração de classes ABAP (claude CLI)", STEP3, gen_args, dry_run)
    if not ok:
        print("\nPipeline abortado na etapa 3.")
        sys.exit(1)

    # -----------------------------------------------------------------------
    # Etapa 4 (opcional): Deploy SAP
    # -----------------------------------------------------------------------
    if deploy:
        if not STEP4.exists():
            print(f"\n[AVISO] {STEP4} não encontrado — deploy pulado.")
        else:
            deploy_args = ["--transport", transport]
            if only:
                deploy_args += ["--only", only.lower().replace(" ", "")]
            if yes:
                deploy_args.append("--yes")

            ok = run_step("ETAPA 4: Deploy para SAP via ADT", STEP4, deploy_args, dry_run)
            if not ok:
                print("\nDeploy finalizado com erros.")
                sys.exit(1)

    # -----------------------------------------------------------------------
    # Relatório final
    # -----------------------------------------------------------------------
    banner("CONCLUÍDO")
    output_dir = SCRIPT_DIR / "Municipios Prontos"
    generated = list(output_dir.glob("*.clas.abap")) if output_dir.exists() else []
    valids   = [f for f in generated if not f.name.endswith(".invalid")]
    invalids = [f for f in generated if f.name.endswith(".invalid")]

    print(f"  Arquivos gerados em: {output_dir}")
    print(f"  Classes válidas:     {len(valids)}")
    if invalids:
        print(f"  Para revisar (.invalid): {len(invalids)}")
        for f in invalids:
            print(f"    - {f.name}")

    if LISTA_MD.exists():
        print(f"\n  Registro de municípios: {LISTA_MD}")

    if not deploy:
        print()
        print("  Para fazer deploy ao SAP, execute:")
        print(f"    python {STEP4.name}")
        print()
        print("  Ou adicione --deploy na próxima execução.")


if __name__ == "__main__":
    main()
