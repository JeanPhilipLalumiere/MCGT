from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = ROOT / "scripts"
CLASSIC_RESET = 'plt.style.use("classic")'
STYLE_REAPPLY = "apply_manuscript_defaults()"


def test_classic_style_resets_reapply_manuscript_defaults():
    violations: list[str] = []

    for path in SCRIPTS_DIR.rglob("*.py"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        start = 0
        while True:
            idx = text.find(CLASSIC_RESET, start)
            if idx == -1:
                break
            tail = text[idx:]
            if STYLE_REAPPLY not in tail:
                violations.append(f"{path.relative_to(ROOT)}: classic style reset without manuscript reapply")
            start = idx + len(CLASSIC_RESET)

    assert not violations, "Manuscript style guard violations detected:\n" + "\n".join(
        sorted(violations)
    )
