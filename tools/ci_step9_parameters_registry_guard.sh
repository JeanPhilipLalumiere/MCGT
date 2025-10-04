#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail

REPORT=".ci-out/parameters_registry_report.txt"
PYLOG=".ci-out/parameters_registry_py.log"
REGISTRY=".ci-out/parameters_registry.json"
: >"$REPORT"

log() { echo "INFO:  $*" | tee -a "$REPORT"; }
err() { echo "ERROR: $*" | tee -a "$REPORT"; }

log "Génère/valide le registre des paramètres…"

python - <<'PY' 2>&1 | tee -a ".ci-out/parameters_registry_py.log"
import json, re, sys, os, datetime, configparser, io
from pathlib import Path

ROOT = Path(".").resolve()
CONF_DIR = ROOT/"zz-configuration"
SCHEMA_DIR = ROOT/"zz-schemas"
REGISTRY = ROOT/".ci-out"/"parameters_registry.json"

def iso_now():
    return datetime.datetime.utcnow().replace(microsecond=0).isoformat()+"Z"

def norm_key(k: str) -> str:
    k = k.strip().replace(" ", "_").replace("-", "_")
    return re.sub(r"__+", "_", k.lower())

def guess_type(v):
    if isinstance(v, bool): return "bool"
    if isinstance(v, int): return "int"
    if isinstance(v, float): return "float"
    if isinstance(v, (list, tuple)): return "list"
    if v is None: return "null"
    if isinstance(v, str):
        vl = v.strip().lower()
        if vl in ("true","false"): return "bool"
        try: int(v.strip()); return "int"
        except: pass
        try: float(v.strip()); return "float"
        except: pass
        return "string"
    if isinstance(v, dict):
        if "value" in v and ("unit" in v or "units" in v):
            t = guess_type(v["value"])
            return {"type": t, "wrapped": "value_with_unit"}
        return "object"
    return "unknown"

def flatten_json(d, prefix=""):
    out = {}
    for k, v in d.items():
        kk = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict) and not ("value" in v and ("unit" in v or "units" in v)):
            out.update(flatten_json(v, kk))
        else:
            out[kk] = v
    return out

def parse_ini_with_fallback(path: Path):
    """
    Retourne une liste de tuples (section, key, value).
    Si le fichier n'a pas de section, on insère [default] artificiellement.
    """
    text = path.read_text(encoding="utf-8", errors="replace")
    # has a bracket section?
    has_section = re.search(r'^\s*\[.+?\]\s*$', text, re.M) is not None
    if not has_section:
        # Inject a default section header at top for configparser
        text = "[default]\n" + text

    cp = configparser.ConfigParser()
    try:
        cp.read_file(io.StringIO(text))
        rows = []
        for sect in cp.sections():
            for key, val in cp.items(sect):
                rows.append((sect, key, val))
        # If we injected default and CP didn't expose it as section, also collect defaults:
        for key, val in cp.defaults().items():
            rows.append(("default", key, val))
        return rows
    except configparser.Error:
        # fallback ultra-simple: key = value lines, ignore comments
        rows = []
        for line in text.splitlines():
            line = line.strip()
            if not line or line.startswith(("#",";","!")): continue
            if "=" in line:
                k, v = line.split("=", 1)
                rows.append(("default", k.strip(), v.strip()))
        return rows

def load_config_entries():
    entries = {}
    # JSON
    for p in sorted(CONF_DIR.glob("*.json")):
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                flat = flatten_json(data)
                for k,v in flat.items():
                    nk = norm_key(k)
                    info = entries.setdefault(nk, {"sources": set(), "types": set(), "units": set(), "values": []})
                    info["sources"].add(str(p.relative_to(ROOT)))
                    t = guess_type(v)
                    if isinstance(t, dict) and t.get("wrapped")=="value_with_unit":
                        info["types"].add(t["type"])
                        unit = (v.get("unit") or v.get("units"))
                        if isinstance(unit,str): info["units"].add(unit)
                        info["values"].append(v.get("value"))
                    else:
                        info["types"].add(t if isinstance(t,str) else json.dumps(t))
                        info["values"].append(v)
            else:
                print(f"[WARN] JSON config '{p}': top-level is not an object")
        except Exception as e:
            print(f"[WARN] JSON config '{p}': {e}")
    # INI (robuste)
    for p in sorted(CONF_DIR.glob("*.ini")):
        try:
            rows = parse_ini_with_fallback(p)
            stem = p.stem
            for sect, key, val in rows:
                nk = norm_key(f"{stem}.{sect}.{key}")
                info = entries.setdefault(nk, {"sources": set(), "types": set(), "units": set(), "values": []})
                # type inference
                v = val
                t = None
                vl = str(v).strip().lower()
                if vl in ("true","false"):
                    t="bool"; v=(vl=="true")
                else:
                    try: v_int=int(str(v).strip()); t="int"; v=v_int
                    except:
                        try: v_f=float(str(v).strip()); t="float"; v=v_f
                        except: t="string"
                info["sources"].add(str(p.relative_to(ROOT)))
                info["types"].add(t)
                info["values"].append(v)
        except Exception as e:
            print(f"[WARN] INI config '{p}': {e}")
    # freeze sets
    for k,v in entries.items():
        v["sources"]=sorted(v["sources"])
        v["types"]=sorted(v["types"])
        v["units"]=sorted(v["units"])
    return entries

def walk_schema_collect(node, current_file, hints):
    """
    Parcourt récursivement tout objet JSON et récolte:
      - properties (si dict)
      - enum / min / max
    """
    if isinstance(node, dict):
        props = node.get("properties") or {}
        if isinstance(props, dict):
            for k, spec in props.items():
                nk = norm_key(k)
                h = hints.setdefault(nk, {"schemas": set(), "type": set(), "enum": set(),
                                          "minimum": None, "maximum": None, "description": None})
                h["schemas"].add(str(current_file))
                t = spec.get("type")
                if isinstance(t, list):
                    for tt in t: h["type"].add(tt)
                elif isinstance(t, str):
                    h["type"].add(t)
                if isinstance(spec.get("enum"), list):
                    for e in spec["enum"]:
                        if isinstance(e,(str,int,float)):
                            h["enum"].add(str(e))
                # numeric bounds (grab multiple aliases loosely)
                for kmm in ("minimum","exclusiveMinimum","min","minInclusive"):
                    if kmm in spec and isinstance(spec[kmm], (int,float)):
                        h["minimum"] = spec[kmm] if h["minimum"] is None else min(h["minimum"], spec[kmm])
                for kmx in ("maximum","exclusiveMaximum","max","maxInclusive"):
                    if kmx in spec and isinstance(spec[kmx], (int,float)):
                        h["maximum"] = spec[kmx] if h["maximum"] is None else max(h["maximum"], spec[kmx])
                if not h["description"] and isinstance(spec.get("description"), str):
                    h["description"] = spec["description"].strip()
        # recurse into all values
        for v in node.values():
            walk_schema_collect(v, current_file, hints)
    elif isinstance(node, list):
        for v in node:
            walk_schema_collect(v, current_file, hints)

def extract_schema_hints():
    hints = {}
    for p in sorted(SCHEMA_DIR.glob("*.json")):
        try:
            s = json.loads(p.read_text(encoding="utf-8"))
            walk_schema_collect(s, p.relative_to(ROOT), hints)
        except Exception as e:
            print(f"[WARN] schema '{p}': {e}")
            continue
    # freeze sets
    for k,v in hints.items():
        v["schemas"]=sorted(v["schemas"])
        v["type"]=sorted(v["type"])
        v["enum"]=sorted(v["enum"])
    return hints

def val_type_name(v):
    if isinstance(v,bool): return "bool"
    if isinstance(v,int): return "int"
    if isinstance(v,float): return "float"
    if isinstance(v,str): return "string"
    if v is None: return "null"
    if isinstance(v,(list,tuple)): return "list"
    if isinstance(v,dict): return "object"
    return "unknown"

conf = load_config_entries()
hints = extract_schema_hints()

# Build registry
keys = {}
for k, info in conf.items():
    r = {
        "sources": info["sources"],
        "type": info["types"][0] if len(info["types"])==1 else info["types"],
        "units": info["units"] or None,
        "example_values": info["values"][:3],
    }
    if k in hints:
        r["schema"] = {
            "schemas": hints[k]["schemas"],
            "type": hints[k]["type"] or None,
            "enum": hints[k]["enum"] or None,
            "minimum": hints[k]["minimum"],
            "maximum": hints[k]["maximum"],
            "description": hints[k]["description"],
        }
    keys[k]=r

REGISTRY.parent.mkdir(parents=True, exist_ok=True)
out = {
    "generated_at": iso_now(),
    "keys_count": len(keys),
    "keys": keys
}
REGISTRY.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

# Lightweight validation: compare config values vs schema enums/ranges/types
issues = []
for k, info in conf.items():
    if k not in hints: continue
    h = hints[k]
    for v in info["values"]:
        vt = val_type_name(v)
        # type check: allow int/float if schema says number/integer appropriately
        if h["type"]:
            if vt == "int" and any(t in h["type"] for t in ("integer","number")):
                pass
            elif vt == "float" and any(t in h["type"] for t in ("number",)):
                pass
            elif vt not in h["type"]:
                issues.append({"severity":"ERROR","code":"TYPE_MISMATCH","key":k,"value_type":vt,"schema_type":list(h["type"])})
        # enum check
        if h["enum"]:
            if str(v) not in h["enum"]:
                issues.append({"severity":"ERROR","code":"ENUM_MISMATCH","key":k,"value":str(v),"enum":list(h["enum"])})
        # range check
        if isinstance(v,(int,float)):
            if h["minimum"] is not None and v < h["minimum"]:
                issues.append({"severity":"ERROR","code":"MIN_VIOLATION","key":k,"value":v,"minimum":h["minimum"]})
            if h["maximum"] is not None and v > h["maximum"]:
                issues.append({"severity":"ERROR","code":"MAX_VIOLATION","key":k,"value":v,"maximum":h["maximum"]})

summary = {
    "registry_path": str(REGISTRY.relative_to(ROOT)),
    "keys_count": len(keys),
    "schema_hints": len(hints),
    "issues_total": len(issues),
    "errors": sum(1 for x in issues if x["severity"]=="ERROR"),
}
print(json.dumps({"summary": summary, "issues_preview": issues[:50]}, indent=2, ensure_ascii=False))
# exit non-zero only if errors > 0 and FAIL_ON_ERRORS=1
fail = int(os.environ.get("FAIL_ON_ERRORS","0"))
if fail and summary["errors"]>0:
    sys.exit(1)
PY

status=$?
if [[ $status -ne 0 ]]; then
  err "Le générateur/validateur a échoué (voir $PYLOG)."
  exit 1
fi

log "Registre généré: $REGISTRY"
