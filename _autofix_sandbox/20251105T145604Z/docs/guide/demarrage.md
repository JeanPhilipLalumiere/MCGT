# Démarrage

## Installation rapide
```bash
python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U pip
[ -f requirements.txt ] && PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements.txt
```

## Commandes utiles
```bash
make docs-build   # génère ./site
make docs-serve   # sert la doc en local
```
