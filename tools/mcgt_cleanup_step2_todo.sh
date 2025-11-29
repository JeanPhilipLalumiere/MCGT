#!/usr/bin/env bash
# Étape 2 : Générer TODO_CLEANUP.md à partir du dernier scan de nettoyage
# - Lecture seule sur le repo (hors création/modif de TODO_CLEANUP.md)
# - Utilise /tmp/mcgt_cleanup_step1_* (ou chemin passé en argument)

set -Eeuo pipefail

echo "[INFO] Génération de TODO_CLEANUP.md (étape 2 — plan de nettoyage)"

# Vérification de base : racine du repo
if [ ! -d ".git" ] || [ ! -f "pyproject.toml" ]; then
  echo "[ERREUR] Ce script doit être lancé depuis la racine du dépôt MCGT."
  exit 1
fi

###############################################################################
# 1. Localisation du répertoire de scan
###############################################################################

if [ "${1-}" != "" ]; then
  SCAN_DIR="$1"
  echo "[INFO] SCAN_DIR fourni en argument : ${SCAN_DIR}"
else
  # On prend le dernier /tmp/mcgt_cleanup_step1_*
  SCAN_DIR="$(ls -d /tmp/mcgt_cleanup_step1_* 2>/dev/null | sort | tail -n1 || true)"
  if [ -z "${SCAN_DIR}" ]; then
    echo "[ERREUR] Aucun répertoire /tmp/mcgt_cleanup_step1_* trouvé."
    echo "        Lance d'abord tools/mcgt_cleanup_step1.sh"
    exit 1
  fi
  echo "[INFO] SCAN_DIR détecté automatiquement : ${SCAN_DIR}"
fi

# Vérification des fichiers attendus
for f in git_status_short.txt untracked_files.txt junk_dirs.txt junk_files_sorted_by_size.txt; do
  if [ ! -f "${SCAN_DIR}/${f}" ]; then
    echo "[ERREUR] Fichier manquant dans ${SCAN_DIR} : ${f}"
    exit 1
  fi
done

###############################################################################
# 2. Statistiques de base
###############################################################################

nb_untracked="$(wc -l < "${SCAN_DIR}/untracked_files.txt" | tr -d ' ')"
nb_junk_dirs="$(wc -l < "${SCAN_DIR}/junk_dirs.txt" | tr -d ' ')"
nb_junk_files="$(wc -l < "${SCAN_DIR}/junk_files_sorted_by_size.txt" | tr -d ' ')"

echo "[INFO] Fichiers non suivis   : ${nb_untracked}"
echo "[INFO] Dossiers 'junk'       : ${nb_junk_dirs}"
echo "[INFO] Fichiers 'junk'      : ${nb_junk_files}"

# On ne garde que les N plus gros pour le plan (mais la liste complète reste dans /tmp)
TOP_N="${TOP_N:-50}"

###############################################################################
# 3. Construction de TODO_CLEANUP.md
###############################################################################

OUTFILE="TODO_CLEANUP.md"
echo "[INFO] Écriture de ${OUTFILE}"

cat > "${OUTFILE}" <<EOF
# TODO_CLEANUP — Plan de nettoyage MCGT

Ce fichier a été généré automatiquement par \`tools/mcgt_cleanup_step2_todo.sh\`
à partir du scan : \`${SCAN_DIR}\`.

AUCUN fichier n'a encore été supprimé ou déplacé.  
Cette liste sert de base pour les décisions humaines (supprimer / attic / conserver).

---

## 1. Résumé quantitatif du scan

- Fichiers non suivis (untracked) : **${nb_untracked}**
- Répertoires techniques "junk" détectés : **${nb_junk_dirs}**
- Fichiers "junk" (tmp, bak, logs, etc.) détectés : **${nb_junk_files}**

---

## 2. Répertoires "junk" à examiner

Source : \`${SCAN_DIR}/junk_dirs.txt\`

> **Action attendue (humaine)** :  
> - Décider quels répertoires peuvent être **supprimés** en toute sécurité  
> - Quels répertoires doivent être **déplacés vers un attic/**  
> - Quels répertoires doivent en fait être **conservés** et éventuellement documentés.

Liste brute :

\`\`\`text
EOF

cat "${SCAN_DIR}/junk_dirs.txt" >> "${OUTFILE}"

cat >> "${OUTFILE}" <<EOF
\`\`\`

---

## 3. Fichiers "junk" les plus volumineux (TOP ${TOP_N})

Source : \`${SCAN_DIR}/junk_files_sorted_by_size.txt\`  
Format : \`<taille_en_octets>  <chemin>\`

> **Action attendue (humaine)** :  
> Pour chaque fichier listé ci-dessous :
> - Vérifier s'il s'agit d'un artefact purement temporaire / historique  
> - Si oui, le marquer pour **suppression**  
> - Sinon, envisager un déplacement vers **attic/** ou une meilleure intégration (manifest, doc).

\`\`\`text
EOF

head -n "${TOP_N}" "${SCAN_DIR}/junk_files_sorted_by_size.txt" >> "${OUTFILE}"

cat >> "${OUTFILE}" <<EOF
\`\`\`

---

## 4. Fichiers non suivis (untracked)

Source : \`${SCAN_DIR}/untracked_files.txt\`

> **Action attendue (humaine)** :  
> - Décider pour chaque fichier s'il doit être :  
>   - **Ajouté au dépôt** (git add + manifest/documentation)  
>   - **Ignoré** (ajout à .gitignore ou équivalent)  
>   - **Supprimé** ou déplacé dans un répertoire d'archives (attic/).

\`\`\`text
EOF

cat "${SCAN_DIR}/untracked_files.txt" >> "${OUTFILE}"

cat >> "${OUTFILE}" <<EOF
\`\`\`

---

## 5. Plan d'action (à remplir à la main)

### 5.1. À supprimer (candidats évidents)

- [ ] ...

### 5.2. À déplacer vers \`attic/\` (archives historiques)

- [ ] ...

### 5.3. À conserver et documenter (manifests, README, etc.)

- [ ] ...

---

## 6. Notes supplémentaires

- Ce fichier doit rester **humainement éditable** : complète, corrige, et coche les éléments une fois traités.
- Après chaque vague de nettoyage, penser à :  
  - Mettre à jour les manifests (\`manifest_master.json\`, \`manifest_publication.json\`)  
  - Adapter \`README-REPRO\` si nécessaire  
  - Vérifier que la CI et les scripts de repro passent toujours.

EOF

echo "[INFO] ${OUTFILE} généré."
echo "[INFO] Étape suivante : ouvrir ${OUTFILE}, commencer à cocher et catégoriser."
