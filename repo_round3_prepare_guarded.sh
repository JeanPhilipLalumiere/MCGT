# repo_round3_prepare_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round3_prep_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: ${LOG}"; echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; CUR="$(git rev-parse --abbrev-ref HEAD)"; echo "branche=${CUR}"
BR="chore/round3-cli-homog"
if ! git rev-parse --verify "$BR" >/dev/null 2>&1; then
  git switch -c "$BR"
else
  git switch "$BR"
fi

mkdir -p tools zz-manifests

cat > tools/check_cli_common.py <<'PY'
from __future__ import annotations
import ast, sys, re
from pathlib import Path
from typing import Dict, List, Tuple

ROOT = Path(".")
COMMON = ["--out","--dpi","--format","--transparent","--style","--verbose"]

def find_py_scripts() -> List[Path]:
    # Producteurs attendus
    globs = [
        "zz-scripts/chapter*/plot_*.py",
        "zz-scripts/chapter*/generate_*.py",
    ]
    out = []
    for g in globs:
        out.extend(sorted(ROOT.glob(g)))
    return [p for p in out if p.is_file()]

def parse_args_in_file(p: Path) -> Dict[str, Dict[str,str]]:
    """
    Retourne {flag: {default:str, present:'1/0'}} pour les COMMON.
    Heuristique : cherche parse_args()/ArgumentParser et add_argument.
    """
    txt = p.read_text(encoding="utf-8", errors="ignore")
    try:
        tree = ast.parse(txt)
    except SyntaxError:
        return {f: {"present":"0","default":""} for f in COMMON}

    # heuristique: collecter add_argument('--x', default=..., ...)
    found: Dict[str, Dict[str,str]] = {f: {"present":"0","default":""} for f in COMMON}
    class V(ast.NodeVisitor):
        def visit_Call(self, node: ast.Call):
            try:
                if isinstance(node.func, ast.Attribute) and node.func.attr == "add_argument":
                    if node.args and isinstance(node.args[0], ast.Constant) and isinstance(node.args[0].value,str):
                        flag = node.args[0].value
                        if flag in COMMON:
                            found[flag]["present"] = "1"
                            # chercher kw 'default='
                            for kw in node.keywords or []:
                                if kw.arg == "default":
                                    val = kw.value
                                    if isinstance(val, ast.Constant):
                                        found[flag]["default"] = repr(val.value)
                                    else:
                                        # best-effort
                                        found[flag]["default"] = "<expr>"
            except Exception:
                pass
            self.generic_visit(node)
    V().visit(tree)
    return found

rows: List[Tuple[str,str,str,str,str,str,str]] = []
for p in find_py_scripts():
    info = parse_args_in_file(p)
    row = [
        str(p),
        *(info[f]["present"] for f in ["--out","--dpi","--format","--transparent","--style","--verbose"]),
    ]
    # défauts concat best-effort
    defaults = ";".join(f"{k}={info[k]['default']}" for k in ["--out","--dpi","--format","--transparent","--style","--verbose"])
    rows.append((str(p),
                 info["--out"]["present"], info["--dpi"]["present"], info["--format"]["present"],
                 info["--transparent"]["present"], info["--style"]["present"], info["--verbose"]["present"],
                ))

# Écrit le CSV TODO (présence des flags)
outp = Path("zz-manifests/TODO_round3_cli.csv")
outp.write_text(
    "path,has_out,has_dpi,has_format,has_transparent,has_style,has_verbose\n" +
    "\n".join(",".join(r) for r in rows) + "\n",
    encoding="utf-8"
)
print(f"[OK] Wrote: {outp}")
PY

echo "== RUN CHECKER =="
python tools/check_cli_common.py

echo "== GIT ADD/COMMIT =="
git add tools/check_cli_common.py zz-manifests/TODO_round3_cli.csv || true
if git diff --cached --quiet; then
  echo "[NOTE] Rien à committer."
else
  git commit -m "round3: audit CLI communs (out/dpi/format/transparent/style/verbose) + TODO CSV"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
fi

echo "== SUGGESTION PR =="
echo "Ouvre une PR dédiée (Round-3 CLI homogénéisation) ou ajoute en draft à #36 si tu préfères fusion séquencée."
