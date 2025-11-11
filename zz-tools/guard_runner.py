# zz-tools/guard_runner.py
#!/usr/bin/env python3
import os, json, re, sys, pathlib

# Entrées (env)
AUTHORITY = os.environ.get("AUTHORITY_MANIFESTS", "").strip()
OUTPUT = os.environ.get("OUTPUT", "diag_report.json")
IGNORE_RE = os.environ.get("IGNORE_PATHS_REGEX", "")
ALLOW_MISS_RE = os.environ.get("ALLOW_MISSING_REGEX", "")

root = pathlib.Path(".")
issues = []

def add_issue(code, path, severity, message):
    issues.append({"code": code, "path": path, "severity": severity, "message": message})

def load_manifest(path_str):
    p = root / path_str
    if not p.exists():
        add_issue("MANIFEST_MISSING", path_str, "WARN", "manifest not found")
        return None
    try:
        with p.open("rb") as f:
            return json.load(f)
    except Exception as e:
        add_issue("JSON_INVALID", path_str, "ERROR", f"invalid json: {e}")
        return None

def norm_paths_from_manifest(man):
    if not isinstance(man, dict):
        return []
    files = man.get("files")
    if files is None:
        add_issue("SCHEMA_INVALID", "<manifest>", "WARN", "missing 'files' list; soft schema")
        return []
    out = []
    for it in files:
        if isinstance(it, dict) and "path" in it:
            out.append(str(it["path"]))
        elif isinstance(it, str):
            out.append(it)
    return out

# Compile regex
ignore_rx = re.compile(IGNORE_RE) if IGNORE_RE else None
allow_miss_rx = re.compile(ALLOW_MISS_RE) if ALLOW_MISS_RE else None

# Détermine la liste de manifests d'autorité
manifests = []
if AUTHORITY:
    for seg in AUTHORITY.split(","):
        seg = seg.strip()
        if seg:
            manifests.append(seg)
else:
    # Défaut conservateur
    manifests = ["zz-manifests/manifest_master.json", "zz-manifests/manifest_publication.json"]

# Évalue UNIQUEMENT les manifests d'autorité (pas de scan global du dossier)
all_paths = []
for mf in manifests:
    man = load_manifest(mf)
    if man is None:
        continue
    paths = norm_paths_from_manifest(man)
    all_paths.extend(paths)

# Déduplication
seen = set()
all_paths = [p for p in all_paths if not (p in seen or seen.add(p))]

# Vérifie l’existence des fichiers listés (avec filtres)
for p in all_paths:
    if ignore_rx and ignore_rx.search(p):
        continue
    if allow_miss_rx and allow_miss_rx.search(p):
        continue
    if not (root / p).exists():
        add_issue("FILE_MISSING", p, "ERROR", "not found")

# Écrit le diag
out = {"issues": issues}
with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

# Impression courte en stdout (utile dans les logs)
print(json.dumps({"total_issues": len(issues)}, ensure_ascii=False))
