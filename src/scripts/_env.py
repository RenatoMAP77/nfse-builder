"""
_env.py
Gerenciador de variáveis de ambiente para a automação de municípios NFS-e.

Fluxo:
  1. Carrega o arquivo .env (se existir) via python-dotenv
  2. Para cada chave necessária:
     - Se já está definida no sistema (ex: via PowerShell/shell): usa diretamente
     - Se está no .env: pergunta se quer usar o valor do .env ou digitar um novo
     - Se não está em lugar nenhum: pede para digitar no terminal
"""
import getpass
import os
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).parent.parent.parent   # nfse-builder/
ENV_FILE = ROOT_DIR / ".env"


def _mask(value: str) -> str:
    """Mascara a chave para exibição."""
    if len(value) <= 8:
        return "****"
    return value[:6] + "..." + value[-4:]


def _load_dotenv() -> dict:
    """Carrega o .env sem sobrescrever variáveis já definidas no sistema."""
    env_values = {}
    if not ENV_FILE.exists():
        return env_values

    try:
        from dotenv import dotenv_values
        env_values = dict(dotenv_values(ENV_FILE))
    except ImportError:
        # Fallback manual se python-dotenv não estiver instalado
        with open(ENV_FILE, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, val = line.partition("=")
                val = val.strip().strip('"').strip("'")
                env_values[key.strip()] = val

    return env_values


def load_env(required_keys: list, silent: bool = False) -> None:
    """
    Garante que todas as chaves em `required_keys` estejam em os.environ.

    Parâmetros:
      required_keys: lista de nomes de variáveis de ambiente necessárias
      silent: se True, não exibe prompts (usa só o que já está no ambiente)
    """
    dot_values = _load_dotenv()
    missing = []

    for key in required_keys:
        # Caso 1: já definida no ambiente do sistema
        if os.environ.get(key):
            if not silent:
                print(f"  {key}: usando valor do ambiente do sistema ({_mask(os.environ[key])})")
            continue

        # Caso 2: está no .env
        if key in dot_values and dot_values[key]:
            env_val = dot_values[key]
            if silent:
                os.environ[key] = env_val
                continue

            print(f"\n  {key} encontrada no .env: {_mask(env_val)}")
            choice = input("  Usar este valor? [S/n] ").strip().lower()
            if choice in ("", "s", "sim", "y", "yes"):
                os.environ[key] = env_val
                continue

        # Caso 3: não encontrada — pedir no terminal
        missing.append(key)

    if missing and not silent:
        print()
        for key in missing:
            print(f"  Digite o valor de {key}:")
            value = getpass.getpass(f"  {key}: ").strip()
            if not value:
                print(f"\nERRO: {key} é obrigatória e não foi fornecida.")
                sys.exit(1)
            os.environ[key] = value

            # Oferece salvar no .env
            save = input(f"  Salvar {key} no .env para próximas execuções? [s/N] ").strip().lower()
            if save in ("s", "sim", "y", "yes"):
                _append_to_env(key, value)
                print(f"  Salvo em {ENV_FILE}")

    elif missing and silent:
        print(f"\nERRO: Variáveis não configuradas: {', '.join(missing)}")
        print(f"  Configure no arquivo {ENV_FILE} ou no ambiente do sistema.")
        sys.exit(1)


def _append_to_env(key: str, value: str) -> None:
    """Adiciona ou atualiza uma chave no arquivo .env."""
    lines = []
    found = False

    if ENV_FILE.exists():
        with open(ENV_FILE, encoding="utf-8") as f:
            lines = f.readlines()

        for i, line in enumerate(lines):
            if line.strip().startswith(key + "=") or line.strip().startswith(key + " ="):
                lines[i] = f"{key}={value}\n"
                found = True
                break

    if not found:
        # Adiciona no final
        if lines and not lines[-1].endswith("\n"):
            lines.append("\n")
        lines.append(f"{key}={value}\n")

    ENV_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(ENV_FILE, "w", encoding="utf-8") as f:
        f.writelines(lines)


def interactive_setup() -> None:
    """
    Interativo de configuração inicial do .env.
    Chamado quando o usuário roda: python src/scripts/_env.py
    """
    print("\n=== Configuração de variáveis de ambiente (.env) ===\n")

    if ENV_FILE.exists():
        print(f"  Arquivo .env encontrado: {ENV_FILE}")
        dot_values = _load_dotenv()
        print(f"  Chaves configuradas: {', '.join(dot_values.keys()) or '(nenhuma)'}")
        print()

    keys = {
        "SAP_URL": "URL do servidor SAP (ex: http://10.0.0.1:8000)",
        "SAP_USER": "Usuario SAP",
        "SAP_PASSWORD": "Senha SAP",
        "SAP_CLIENT": "Mandante SAP (ex: 400)",
    }

    for key, description in keys.items():
        print(f"  {key}")
        print(f"    {description}")
        current = os.environ.get(key) or _load_dotenv().get(key, "")
        if current:
            print(f"    Valor atual: {_mask(current)}")
            skip = input("    Manter valor atual? [S/n] ").strip().lower()
            if skip in ("", "s", "sim", "y", "yes"):
                print()
                continue

        value = getpass.getpass(f"    Digite o valor: ").strip()
        if value:
            _append_to_env(key, value)
            print(f"    Salvo.\n")
        else:
            print(f"    Deixado em branco.\n")

    print(f"Configuração salva em: {ENV_FILE}")
    print("Não esqueça de adicionar .env ao .gitignore!\n")


if __name__ == "__main__":
    interactive_setup()
