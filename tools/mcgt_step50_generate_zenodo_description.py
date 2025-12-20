#!/usr/bin/env python3
from pathlib import Path


def main() -> None:
    # Repo root = parent de tools/
    root = Path(__file__).resolve().parent.parent
    out_dir = root / "zz-zenodo"
    out_dir.mkdir(exist_ok=True)

    description = """Toolkit de publication et de reproductibilité pour le Modèle de la Courbure Gravitationnelle du Temps (MCGT). Cette version v0.3.0 fournit un snapshot cohérent des figures, données et scripts associés aux chapitres 01–10, avec manifests JSON alignés, inventaires de fichiers (FRONT/BACKSTAGE) et garde-fous automatisés (diagnostic de cohérence et tests smoke).

Les pipelines de reproduction sont stabilisés pour le chapitre des phases d’ondes gravitationnelles (CH09) et en développement pour le chapitre bootstrap des métriques sur p95 (CH10). Les textes LaTeX des chapitres sont pour l’instant fournis sous forme de squelettes/placeholders ; une version ultérieure intégrera la monographie complète et la structure finale des chapitres.

Ce dépôt Zenodo archive le tarball de publication correspondant au dépôt GitHub MCGT (branche main, série 0.3.x) et sert de point d’ancrage pour le DOI utilisé dans les travaux scientifiques fondés sur MCGT.
"""

    out_path = out_dir / "zenodo_description_v0.3.0.txt"
    out_path.write_text(description, encoding="utf-8")

    print(f"[INFO] Description Zenodo v0.3.0 écrite dans {out_path}")
    print("[INFO] Tu peux copier-coller ce bloc dans le champ 'Description' de Zenodo.")


if __name__ == "__main__":
    main()
