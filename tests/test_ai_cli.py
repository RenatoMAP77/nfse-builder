import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parents[1] / "src" / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import ai_cli


class AiCliTests(unittest.TestCase):
    def test_claude_is_default(self):
        self.assertEqual("claude", ai_cli.validate_provider(""))
        self.assertEqual(["claude", "--print"], ai_cli.build_command("claude"))

    def test_claude_model_is_forwarded(self):
        self.assertEqual(
            ["claude", "--print", "--model", "sonnet"],
            ai_cli.build_command("claude", "sonnet"),
        )

    def test_codex_command_is_non_interactive_and_read_only(self):
        command = ai_cli.build_command("codex", "gpt-test")
        self.assertEqual("codex", command[0])
        self.assertIn("--ephemeral", command)
        self.assertIn("read-only", command)
        self.assertIn("gpt-test", command)
        self.assertEqual("-", command[-1])

    def test_codex_image_is_attached(self):
        command = ai_cli.build_command("codex", image_path="image.png")
        self.assertIn("--image", command)
        self.assertTrue(command[command.index("--image") + 1].endswith("image.png"))

    @patch("ai_cli.shutil.which", return_value="codex")
    @patch("ai_cli.subprocess.run")
    def test_call_ai_passes_prompt_on_stdin(self, run, _which):
        run.return_value = subprocess.CompletedProcess([], 0, "answer\n", "")
        output = ai_cli.call_ai("prompt", provider="codex", timeout=9)
        self.assertEqual("answer", output)
        self.assertEqual("prompt", run.call_args.kwargs["input"])
        self.assertEqual(9, run.call_args.kwargs["timeout"])

    @patch("ai_cli.shutil.which", return_value=None)
    def test_missing_provider_fails(self, _which):
        with self.assertRaisesRegex(RuntimeError, "codex CLI"):
            ai_cli.call_ai("prompt", provider="codex")

    @patch("ai_cli.shutil.which", return_value="codex")
    @patch("ai_cli.subprocess.run")
    def test_nonzero_exit_fails_without_fallback(self, run, _which):
        run.return_value = subprocess.CompletedProcess([], 1, "", "authentication failed")
        with self.assertRaisesRegex(RuntimeError, "authentication failed"):
            ai_cli.call_ai("prompt", provider="codex")
        self.assertEqual(1, run.call_count)

    @patch("ai_cli.shutil.which", return_value="codex")
    @patch("ai_cli.subprocess.run", side_effect=subprocess.TimeoutExpired("codex", 5))
    def test_timeout_is_propagated(self, _run, _which):
        with self.assertRaises(subprocess.TimeoutExpired):
            ai_cli.call_ai("prompt", provider="codex", timeout=5)

    def test_invalid_provider_fails(self):
        with self.assertRaisesRegex(ValueError, "Provedor invalido"):
            ai_cli.validate_provider("other")

    def test_option_value_requires_value(self):
        with self.assertRaisesRegex(ValueError, "requer um valor"):
            ai_cli.option_value(["--provider"], "--provider")


if __name__ == "__main__":
    unittest.main()
