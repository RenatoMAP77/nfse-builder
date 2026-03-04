"""
run_municipios.py — Orquestrador do pipeline de criação de classes municipais NFS-e

Pipeline:
  1. Scraping IBGE      → ibge_codes.json
  2. Conversão DOCX→TXT → EFTs_text/*.txt  (com OCR de imagens via GPT-4o)
  3. Geração ABAP       → municipios_novos/*.clas.abap  (via Claude API)

Uso:
  python automation/run_municipios.py [opções]

Opções:
  --skip-ibge          Pula a etapa 1 (usa ibge_codes.json existente)
  --skip-convert       Pula a etapa 2 (usa EFTs_text/ existente)
  --only "Caçador SC"  Processa apenas esse município nas etapas 2 e 3
  --force              Reprocessa arquivos mesmo que já existam
  --dry-run            Mostra o que seria feito sem executar nada
  --deploy             Após gerar, executa também o deploy para SAP (etapa 4)
  --transport XXX      Número do transporte SAP para o deploy (padrão: $TMP)
  --yes                Pula confirmações interativas no deploy

Variáveis de ambiente necessárias:
  OPENAI_API_KEY       Para OCR de imagens (etapa 2)
  ANTHROPIC_API_KEY    Para geração ABAP (etapa 3)

Exemplo de uso completo:
  # Primeira execução (faz tudo):
  python automation/run_municipios.py

  # Execuções subsequentes (IBGE já em cache, força regenerar apenas as classes):
  python automation/run_municipios.py --skip-ibge --force

  # Processar apenas um município:
  python automation/run_municipios.py --skip-ibge --only "Caçador SC"

  # Pipeline completo + deploy para SAP:
  python automation/run_municipios.py --skip-ibge --deploy --transport SRTK123456 --yes
"""
import os
import subprocess
import sys
from pathlib import Path

# Carrega variáveis de ambiente (.env ou prompt interativo)
sys.path.insert(0, str(Path(__file__).parent))
from _env import load_env

SCRIPT_DIR = Path(__file__).parent
BASE_DIR = SCRIPT_DIR.parent

STEP1 = SCRIPT_DIR / "1_scrape_ibge.py"
STEP2 = SCRIPT_DIR / "2_convert_efts.py"
STEP3 = SCRIPT_DIR / "3_generate_classes.py"
STEP4 = SCRIPT_DIR / "4_deploy_to_sap.py"


def banner(text: str):
    print(f"\n{'=' * 60}")
    print(f"  {text}")
    print(f"{'=' * 60}")


def prompt_env_keys(dry_run: bool, skip_convert: bool):
    """
    Carrega as chaves de API necessárias via _env.py.
    Em dry-run, não solicita nada (usa só o que já está no ambiente).
    Os subprocessos herdam os valores de os.environ automaticamente.
    """
    if dry_run:
        return

    required = ["ANTHROPIC_API_KEY"]
    if not skip_convert:
        required.insert(0, "OPENAI_API_KEY")

    print("\nVerificando chaves de API...\n")
    load_env(required)
    print()


def run_step(
    label: str,
    script: Path,
    extra_args: list[str],
    dry_run: bool,
) -> bool:
    """
    Executa um script como subprocesso.
    Retorna True se sucesso.
    """
    banner(label)
    cmd = [sys.executable, str(script)] + extra_args
    print(f"Executando: {' '.join(cmd)}\n")

    if dry_run:
        print("  [DRY-RUN] Não executado.")
        return True

    result = subprocess.run(cmd, check=False)
    if result.returncode != 0:
        print(f"\n[ERRO] {label} falhou com código {result.returncode}.")
        return False
    return True


def main():
    args = sys.argv[1:]

    skip_ibge = "--skip-ibge" in args
    skip_convert = "--skip-convert" in args
    dry_run = "--dry-run" in args
    force = "--force" in args
    deploy = "--deploy" in args
    yes = "--yes" in args

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
    print(f"  Base: {BASE_DIR}")
    print(f"  EFTs: {BASE_DIR / 'EFTs_municipios'}")
    print(f"  Saída: {BASE_DIR / 'municipios_novos'}")
    if only:
        print(f"  Filtro: '{only}' apenas")
    if dry_run:
        print("  MODO: DRY-RUN (nenhuma ação executada)")
    print()

    # Carrega/solicita chaves de API
    prompt_env_keys(dry_run, skip_convert)

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
    # Etapa 2: Conversão DOCX → TXT
    # -----------------------------------------------------------------------
    if not skip_convert:
        conv_args = []
        if only:
            conv_args += ["--only", only]
        if force:
            conv_args.append("--force")
        ok = run_step("ETAPA 2: Conversão DOCX → TXT (OCR via GPT-4o)", STEP2, conv_args, dry_run)
        if not ok:
            print("\nPipeline abortado na etapa 2.")
            sys.exit(1)
    else:
        efts_text_dir = BASE_DIR / "EFTs_text"
        txt_count = len(list(efts_text_dir.glob("*.txt"))) if efts_text_dir.exists() else 0
        print(f"\n[PULAR] Etapa 2: usando {txt_count} arquivo(s) .txt existente(s) em EFTs_text/.")

    # -----------------------------------------------------------------------
    # Etapa 3: Geração das classes ABAP via Claude
    # -----------------------------------------------------------------------
    gen_args = []
    if only:
        gen_args += ["--only", only]
    if force:
        gen_args.append("--force")

    ok = run_step("ETAPA 3: Geração de classes ABAP (Claude API)", STEP3, gen_args, dry_run)
    if not ok:
        print("\nPipeline abortado na etapa 3.")
        sys.exit(1)

    # -----------------------------------------------------------------------
    # Etapa 4 (opcional): Deploy SAP
    # -----------------------------------------------------------------------
    if deploy:
        deploy_args = ["--transport", transport]
        if only:
            deploy_args += ["--only", only.lower().replace(" ", "")]
        if yes:
            deploy_args.append("--yes")

        ok = run_step("ETAPA 4: Deploy para SAP via ADT", STEP4, deploy_args, dry_run)
        if not ok:
            print("\nDeploy finalizado com erros.")
            sys.exit(1)
    else:
        banner("PRÓXIMOS PASSOS")
        municipios_dir = BASE_DIR / "municipios_novos"
        generated = list(municipios_dir.glob("*.clas.abap")) if municipios_dir.exists() else []
        valids = [f for f in generated if not f.name.endswith(".invalid")]
        invalids = [f for f in generated if f.name.endswith(".invalid")]

        print(f"  Arquivos gerados em: {municipios_dir}")
        print(f"  Classes válidas: {len(valids)}")
        if invalids:
            print(f"  Classes para revisar (.invalid): {len(invalids)}")

        print()
        print("  Para fazer deploy ao SAP, execute:")
        print(f"    python automation/4_deploy_to_sap.py")
        print()
        print("  Ou para copiar ao repositório e importar via abapGit:")
        repo_src = (
            BASE_DIR
            / "repositorios"
            / "orbitspot-s4tax_nfse-8bd75d03315f412fd631edb4e617f4afde972e01"
            / "src"
        )
        print(f"    Copiar de: {municipios_dir}")
        print(f"    Copiar para: {repo_src}")

    banner("CONCLUÍDO")


if __name__ == "__main__":
    main()
