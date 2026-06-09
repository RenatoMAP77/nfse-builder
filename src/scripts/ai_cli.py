"""Shared adapter for non-interactive Claude and Codex CLI calls."""
import os
import shutil
import subprocess
from pathlib import Path

VALID_PROVIDERS = ("claude", "codex")
DEFAULT_PROVIDER = "claude"


def validate_provider(provider: str) -> str:
    provider = (provider or DEFAULT_PROVIDER).lower()
    if provider not in VALID_PROVIDERS:
        raise ValueError(
            f"Provedor invalido: '{provider}'. Use: {', '.join(VALID_PROVIDERS)}"
        )
    return provider


def build_command(provider: str, model: str | None = None, image_path: str | None = None) -> list:
    provider = validate_provider(provider)

    if provider == "claude":
        command = ["claude", "--print"]
        if image_path:
            command += ["--dangerously-skip-permissions", "--tools", "Read"]
        if model:
            command += ["--model", model]
        return command

    command = [
        "codex",
        "--ask-for-approval", "never",
        "exec",
        "--ephemeral",
        "--sandbox", "read-only",
        "--color", "never",
    ]
    if model:
        command += ["--model", model]
    if image_path:
        command += ["--image", str(Path(image_path).resolve())]
    command.append("-")
    return command


def clean_environment() -> dict:
    """Allow nested CLI calls when the pipeline runs inside Claude Code or Codex."""
    env = os.environ.copy()
    env.pop("CLAUDECODE", None)
    env.pop("CODEX_THREAD_ID", None)
    return env


def check_provider(provider: str) -> str:
    """Validate that the selected CLI exists and return its version string."""
    provider = validate_provider(provider)
    if not shutil.which(provider):
        install_hint = (
            "npm install -g @anthropic-ai/claude-code"
            if provider == "claude"
            else "npm install -g @openai/codex"
        )
        raise RuntimeError(
            f"'{provider}' CLI nao encontrado no PATH. Instale com: {install_hint}"
        )

    result = subprocess.run(
        [provider, "--version"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=10,
        env=clean_environment(),
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"{provider} CLI instalado mas nao funcionando: {result.stderr[:300]}"
        )
    return result.stdout.strip()


def call_ai(
    prompt: str,
    provider: str = DEFAULT_PROVIDER,
    model: str | None = None,
    image_path: str | None = None,
    timeout: int = 120,
) -> str:
    """Run the selected AI CLI and return only its final text response."""
    provider = validate_provider(provider)
    if not shutil.which(provider):
        raise RuntimeError(f"{provider} CLI nao encontrado no PATH.")

    effective_prompt = prompt
    if provider == "claude" and image_path:
        effective_prompt = (
            f"{prompt}\n\n"
            f"Use a ferramenta Read para ler o arquivo de imagem: "
            f"{Path(image_path).resolve()}"
        )

    result = subprocess.run(
        build_command(provider, model, image_path),
        input=effective_prompt,
        env=clean_environment(),
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=timeout,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout)[:500]
        raise RuntimeError(f"{provider} CLI erro: {detail}")
    return result.stdout.strip()


def option_value(args: list, option: str, default=None):
    """Return the value following an option, failing clearly when it is missing."""
    if option not in args:
        return default
    index = args.index(option)
    if index + 1 >= len(args) or args[index + 1].startswith("--"):
        raise ValueError(f"Opcao {option} requer um valor.")
    return args[index + 1]
