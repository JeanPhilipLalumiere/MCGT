from pathlib import Path
import json

def test_no_tex_in_manifest():
    man = json.loads(Path("zz-manifests/manifest_master.json").read_text(encoding="utf-8"))
    entries = man.get("entries", man if isinstance(man, list) else [])
    if isinstance(entries, dict):
        pairs = [{"path": k, **v} for k, v in entries.items()]
    else:
        pairs = entries
    offenders = [e.get("path","") for e in pairs if str(e.get("path","")).endswith(".tex")]
    assert not offenders, f".tex présents dans manifest: {offenders[:10]}"
