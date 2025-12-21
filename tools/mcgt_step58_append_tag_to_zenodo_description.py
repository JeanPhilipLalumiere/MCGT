#!/usr/bin/env python
from pathlib import Path

TAG = "v0.3.0-zenodo-snapshot-20251130T204410Z"


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    desc_path = root / "zz-zenodo" / "zenodo_description_v0.3.0.txt"

    if not desc_path.is_file():
        raise SystemExit(f"[ERROR] Fichier introuvable : {desc_path}")

    text = desc_path.read_text(encoding="utf-8")

    if TAG in text:
        print("[INFO] Le tag est déjà mentionné dans la description. Rien à faire.")
        return

    extra = (
        "\n\nCe snapshot correspond au tag Git "
        f"`{TAG}` dans le dépôt public MCGT (branche `main`).\n"
    )

    new_text = text.rstrip() + extra
    desc_path.write_text(new_text, encoding="utf-8")
    print(f"[INFO] Tag ajouté dans {desc_path}")


if __name__ == "__main__":
    main()
