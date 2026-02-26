# Contribuer à ΨTMG

## Pré-requis
- Git, Python 3.11+, `pre-commit` installé (`pipx install pre-commit` ou `pip install pre-commit`).
- (Optionnel) GitHub CLI `gh` pour déclencher/suivre la CI localement.

## Première installation
```bash
pre-commit install            # installe les hooks côté client
pre-commit run -a             # vérifie tout une première fois
```

## Commandes utiles
- `make check` — lance tous les hooks localement (même que la CI).
- `make hooks` — installe les hooks `pre-commit`.
- `make ci` — déclenche `ci-pre-commit.yml` via GitHub CLI (si installé).

## Règles d'hygiène (résumé)
- Fin de ligne **LF**, UTF-8, pas de BOM ni CRLF, pas d’onglets.
- Pas de bit **+x** sur YAML/MD/TXT/JSON/TOML et workflows; scripts avec shebang **oui**.
- Dans les workflows: `run-name` doit être **quoté** dès qu'il contient ${{ … }}.

_(Les hooks locaux refusent automatiquement les violations et proposent des auto-fix quand possible.)_
