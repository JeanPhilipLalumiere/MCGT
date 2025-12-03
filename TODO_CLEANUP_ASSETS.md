# TODO CLEANUP – Assets MCGT (généré automatiquement)

Ce fichier résume les candidats au nettoyage à partir de CHAPTER_GUIDE_PAYLOAD.tsv et ASSETS_EXTRA_ALL.tsv.

- Lignes payload (CHAPTER_GUIDE_PAYLOAD.tsv) : 299
- Lignes extras  (ASSETS_EXTRA_ALL.tsv)      : 3039

## Résumé par chapitre

### Chapitre 01

- Payload (à garder) : 25
- Extras (candidats nettoyage) : 222
  - SANDBOX_OR_ATTIC : 117
  - BACKUP_OR_RESCUE : 97
  - BYTECODE : 7
  - ENV_REQUIREMENTS_DUP : 1

### Chapitre 02

- Payload (à garder) : 28
- Extras (candidats nettoyage) : 275
  - SANDBOX_OR_ATTIC : 150
  - BACKUP_OR_RESCUE : 115
  - BYTECODE : 9
  - ENV_REQUIREMENTS_DUP : 1

### Chapitre 03

- Payload (à garder) : 29
- Extras (candidats nettoyage) : 233
  - SANDBOX_OR_ATTIC : 161
  - BACKUP_OR_RESCUE : 61
  - BYTECODE : 10
  - ENV_REQUIREMENTS_DUP : 1

### Chapitre 04

- Payload (à garder) : 12
- Extras (candidats nettoyage) : 125
  - SANDBOX_OR_ATTIC : 79
  - BACKUP_OR_RESCUE : 40
  - BYTECODE : 5
  - ENV_REQUIREMENTS_DUP : 1

### Chapitre 05

- Payload (à garder) : 17
- Extras (candidats nettoyage) : 137
  - SANDBOX_OR_ATTIC : 84
  - BACKUP_OR_RESCUE : 47
  - BYTECODE : 5
  - ENV_REQUIREMENTS_DUP : 1

### Chapitre 06

- Payload (à garder) : 31
- Extras (candidats nettoyage) : 234
  - SANDBOX_OR_ATTIC : 127
  - BACKUP_OR_RESCUE : 99
  - BYTECODE : 7
  - ENV_REQUIREMENTS_DUP : 1

### Chapitre 07

- Payload (à garder) : 40
- Extras (candidats nettoyage) : 351
  - SANDBOX_OR_ATTIC : 201
  - BACKUP_OR_RESCUE : 136
  - BYTECODE : 14
  - ENV_REQUIREMENTS_DUP : 0

### Chapitre 08

- Payload (à garder) : 35
- Extras (candidats nettoyage) : 305
  - SANDBOX_OR_ATTIC : 206
  - BACKUP_OR_RESCUE : 83
  - BYTECODE : 15
  - ENV_REQUIREMENTS_DUP : 1

### Chapitre 09

- Payload (à garder) : 31
- Extras (candidats nettoyage) : 408
  - SANDBOX_OR_ATTIC : 217
  - BACKUP_OR_RESCUE : 176
  - BYTECODE : 14
  - ENV_REQUIREMENTS_DUP : 1

### Chapitre 10

- Payload (à garder) : 51
- Extras (candidats nettoyage) : 749
  - SANDBOX_OR_ATTIC : 380
  - BACKUP_OR_RESCUE : 348
  - BYTECODE : 21
  - ENV_REQUIREMENTS_DUP : 0

## Définitions des classes de nettoyage

- SANDBOX_OR_ATTIC : fichiers dans _autofix_sandbox/, _tmp/, attic/, _attic_untracked/, zz-out/ (logs, runs intermédiaires, copies sandbox).
- BACKUP_OR_RESCUE : fichiers de sauvegarde ou variantes (suffixes .bak, .pass, .broken, .rescue, .r10., .tmp, etc.).
- BYTECODE : fichiers compilés Python (.pyc).
- ENV_REQUIREMENTS_DUP : fichiers requirements.txt redondants dédiés à des environnements locaux.
