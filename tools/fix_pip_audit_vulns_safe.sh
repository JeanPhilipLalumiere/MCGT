# tools/fix_pip_audit_vulns_safe.sh
#!/usr/bin/env bash
# NE FERME JAMAIS LA FENÊTRE — met à niveau requests & jupyterlab, crée PR, relance CI
set -u -o pipefail; set +e

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

REQ_MIN="2.32.4"
JLAB_MIN="4.4.8"
BR_BASE="${1:-main}"

REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_DIR" || exit 1

printf '\n\033[1m== FIX PIP-AUDIT VULNS (requests / jupyterlab) ==\033[0m\n'
info "Repo: $REPO_DIR • Base: $BR_BASE"

# 0) Sécurité branche: si on est sur main, créer une branche de fix
CUR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
if [ "$CUR" = "$BR_BASE" ]; then
  NEW="fix/security-pins-$(date -u +%Y%m%dT%H%M%SZ)"
  info "Sur $BR_BASE → je crée la branche $NEW"
  git fetch origin "$BR_BASE" >/dev/null 2>&1 || true
  git checkout -b "$NEW" "origin/$BR_BASE" 2>/dev/null || git checkout -b "$NEW"
  CUR="$NEW"
  ok "Branche: $CUR"
else
  info "Branche courante: $CUR"
fi

# 1) Sauvegarde pyproject.toml si présent
CHANGED=0
if [ -f pyproject.toml ]; then
  cp -p pyproject.toml "pyproject.toml.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  ok "Backup pyproject.toml"
  # Édition via Python pour élever les bornes minimales
  python3 - "$REQ_MIN" "$JLAB_MIN" <<'PY' 2>/dev/null || true
import io, os, re, sys
req_min, jlab_min = sys.argv[1], sys.argv[2]
path = "pyproject.toml"
if not os.path.exists(path):
    sys.exit(0)
txt = open(path, "r", encoding="utf-8").read()

def bump(spec, name, floor):
    # remplace versions exactes ou >= existantes par >= floor si floor plus haut
    # cas simples: "name==x.y.z", "name ~= x.y", "name>=x.y.z", "name>=a,<b"
    pat = re.compile(rf'(^\s*["\']?{re.escape(name)}\s*([<>=!~].*?)?["\']?\s*,?\s*$)', re.M)
    def repl(m):
        line = m.group(1)
        # si aucune contrainte -> ajoute >=floor
        if name not in line:
            return line
        # simplification: force >=floor et conserve éventuels <MAJOR+1 si présent
        # essaye de conserver un upper bound si <5 déjà présent
        if "<" in line:
            parts = line.split("<", 1)
            upper = "<" + parts[1].split(",")[0].strip().strip('"\'')

            return re.sub(rf'{re.escape(name)}\s*([<>=!~].*)?',
                          f'{name}>={floor}, {upper}',
                          line)
        return re.sub(rf'{re.escape(name)}\s*([<>=!~].*)?',
                      f'{name}>={floor}',
                      line)
    return pat.sub(repl, spec)

new = bump(txt, "requests", req_min)
new = bump(new, "jupyterlab", jlab_min)

if new != txt:
    open(path, "w", encoding="utf-8").write(new)
    print("PYPROJECT_UPDATED")
PY
  if grep -q "PYPROJECT_UPDATED" <<<"$(tail -n 1 pyproject.toml 2>/dev/null || true)"; then
    # Nettoie l'éventuel marqueur imprimé par erreur (rare)
    sed -i '/PYPROJECT_UPDATED/d' pyproject.toml
  fi
  if ! git diff --quiet -- pyproject.toml; then
    CHANGED=1
    ok "pyproject.toml mis à jour (requests>=${REQ_MIN}, jupyterlab>=${JLAB_MIN})"
  else
    info "Aucun changement détecté dans pyproject.toml (paquets non listés ici ?)."
  fi
else
  warn "pyproject.toml absent."
fi

# 2) Si rien n’a changé, ajoute un constraints pour forcer la résolution
if [ "$CHANGED" -eq 0 ]; then
  mkdir -p constraints
  CON="constraints/security-pins.txt"
  {
    echo "# généré automatiquement — bornes minimales sûres"
    echo "requests>=$REQ_MIN"
    echo "jupyterlab>=$JLAB_MIN"
  } > "$CON"
  ok "Constraints ajouté → $CON"

  # Patch best-effort: si un workflow installe via pip, ajouter -c constraints/security-pins.txt (non bloquant si échec)
  WFPATCH=0
  for wf in .github/workflows/*.yml .github/workflows/*.yaml; do
    [ -f "$wf" ] || continue
    if grep -Eq 'pip install( .*)?( -r | [a-zA-Z0-9_.-]+)' "$wf"; then
      sed -i -E 's#pip install(.*)#pip install\1 -c constraints/security-pins.txt#g' "$wf" || true
      WFPATCH=1
    fi
  done
  [ "$WFPATCH" -eq 1 ] && ok "Workflows patchés (pip install … -c constraints/security-pins.txt)" || info "Aucun workflow pip à patcher détecté (OK)."
fi

# 3) Commit
if ! git diff --quiet; then
  git add pyproject.toml constraints/ .github/workflows 2>/dev/null || true
  git commit -m "sec: raise floors for requests>=${REQ_MIN} & jupyterlab>=${JLAB_MIN} (fix GHSA-9hjg-9r4m-mvj7, GHSA-vvfj-2jqx-52jm)" \
    >/dev/null 2>&1 || warn "Commit non créé (rien à ajouter ?)"
else
  warn "Aucun diff à committer (peut-être déjà corrigé)."
fi

# 4) Push + PR (best-effort)
if git rev-parse --abbrev-ref HEAD | grep -q '^fix/security-pins-'; then
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" >/dev/null 2>&1 && ok "Pushed branche $(git rev-parse --abbrev-ref HEAD)" || warn "Push impossible."
  if command -v gh >/dev/null 2>&1; then
    gh pr create -B "$BR_BASE" -t "sec(deps): raise floors for requests & jupyterlab" \
      -b "Fixes pip-audit: requests>=${REQ_MIN} (GHSA-9hjg-9r4m-mvj7), jupyterlab>=${JLAB_MIN} (GHSA-vvfj-2jqx-52jm)." \
      >/dev/null 2>&1 && ok "PR créée (ouvre l’onglet Pull Requests)" || warn "Création PR échouée (ouvre manuellement)."
  fi
else
  info "Sur une branche non-main déjà existante — PR à créer manuellement si besoin."
fi

# 5) Relance CI best-effort (build + ci-accel + pip-audit sur la branche courante)
if command -v gh >/dev/null 2>&1; then
  BRR="$(git rev-parse --abbrev-ref HEAD)"
  gh workflow run .github/workflows/build-publish.yml -r "$BRR" >/dev/null 2>&1 && ok "dispatch build-publish@$BRR" || warn "dispatch KO build-publish"
  gh workflow run .github/workflows/ci-accel.yml -r "$BRR"        >/dev/null 2>&1 && ok "dispatch ci-accel@$BRR"      || warn "dispatch KO ci-accel"
  gh workflow run .github/workflows/pip-audit.yml -r "$BRR"       >/dev/null 2>&1 && ok "dispatch pip-audit@$BRR"     || warn "dispatch KO pip-audit"
else
  warn "gh absent/non connecté — relance manuelle via l’UI."
fi

echo
ok "Terminé. Surveille la PR/CI. Cette fenêtre RESTE OUVERTE."
