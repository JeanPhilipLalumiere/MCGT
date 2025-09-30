#!/usr/bin/env bash
# Auto-fix ciblé pour .github/workflows/publish_testonly.yml
# Fenêtre OUVERTE à la fin.

set -u -o pipefail
WF=".github/workflows/publish_testonly.yml"
FIXBR="ci/testpypi-workflow-rmid"

final_loop(){ echo; echo "=== Fenêtre OUVERTE — [Entrée]=quitter  [sh]=shell ==="; while true; do read -r -p "> " a||true; case "${a:-}" in sh) /bin/bash -i;; "") break;; *) echo "?";; esac; done; }

[ -f "$WF" ] || { echo "ERROR: $WF introuvable"; final_loop; exit 0; }

echo "== Normalisation (BOM/CRLF/TABS) =="
# Enlever BOM
tail -c +1 "$WF" > "$WF.tmp" && mv "$WF.tmp" "$WF"
# CRLF -> LF
sed -i 's/\r$//' "$WF"
# Tabs -> 2 spaces
expand -t 2 "$WF" > "$WF.tmp" && mv "$WF.tmp" "$WF"

echo "== ruamel.yaml patch =="
python3 - "$WF" "$FIXBR" <<'PY'
import sys, io, re
from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap, CommentedSeq

yaml = YAML()
yaml.preserve_quotes = True

wf_path = sys.argv[1]
fixbr   = sys.argv[2]

data = yaml.load(open(wf_path, 'r', encoding='utf-8'))

if not isinstance(data, dict):
    data = CommentedMap()

# 1) supprimer clés top-level parasites (_xxx)
for k in list(data.keys()):
    if isinstance(k, str) and k.startswith('_'):
        del data[k]

# 2) on: workflow_dispatch + push (branche fixe + paths)
on = data.get('on', CommentedMap())
if isinstance(on, list):
    # convertir en mapping
    m = CommentedMap()
    for v in on:
        if isinstance(v, str):
            m[v] = None
    on = m
elif not isinstance(on, dict) and on is not None:
    on = CommentedMap()

# ensure workflow_dispatch
if 'workflow_dispatch' not in on:
    on['workflow_dispatch'] = None

# ensure push with branches+paths
push = on.get('push')
if push is None or push is True:
    push = CommentedMap()
if not isinstance(push, dict):
    push = CommentedMap()

def ensure_list(v):
    if v is None:
        return CommentedSeq()
    if isinstance(v, list):
        return CommentedSeq(v)
    return CommentedSeq([v])

push['branches'] = ensure_list(push.get('branches'))
if fixbr not in push['branches']:
    push['branches'].append(fixbr)

push['paths'] = ensure_list(push.get('paths'))
if '.ci_poke/**' not in push['paths']:
    push['paths'].append('.ci_poke/**')

on['push'] = push
data['on'] = on

# 3) jobs sanity
jobs = data.get('jobs', CommentedMap())
if jobs is None or not isinstance(jobs, dict):
    jobs = CommentedMap()
data['jobs'] = jobs

for jn, job in list(jobs.items()):
    if not isinstance(job, dict):
        job = CommentedMap()
        jobs[jn] = job
    # runs-on default
    if 'runs-on' not in job:
        job['runs-on'] = 'ubuntu-latest'
    # steps list
    steps = job.get('steps', CommentedSeq())
    if steps is None or not isinstance(steps, list):
        steps = CommentedSeq()
    # remove download-artifact run-id
    for st in steps:
        if isinstance(st, dict):
            uses = st.get('uses', '')
            if isinstance(uses, str) and 'actions/download-artifact' in uses:
                with_ = st.get('with')
                if isinstance(with_, dict) and 'run-id' in with_:
                    del with_['run-id']
    job['steps'] = steps

yaml.dump(data, open(wf_path, 'w', encoding='utf-8'))
PY

echo "== Commit & push sur branche fixe =="
git checkout -B "$FIXBR" >/dev/null 2>&1 || true
git add "$WF"
git -c user.name="Local CI" -c user.email="local@ci" -c commit.gpgSign=false commit -m "ci: autofix publish_testonly.yml" --no-verify >/dev/null 2>&1 || true
git push -u origin "$FIXBR" >/dev/null 2>&1 || true

echo "OK."
final_loop
