# CONTRIBUTING

## Dépendances & contraintes de sécurité

Runtime :
```bash
PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements.txt
```

Développement :
```bash
PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements-dev.txt
```

Audit :
```bash
pip-audit -r requirements.txt && pip-audit -r requirements-dev.txt
```
