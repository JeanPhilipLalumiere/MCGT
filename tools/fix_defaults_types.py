import re, yaml, pathlib
p = pathlib.Path("config/defaults.yml")
if not p.exists():
    raise SystemExit("config/defaults.yml absent — génère-le d'abord.")
data = yaml.safe_load(p.read_text(encoding="utf-8"))

def strip_outer_quotes(s: str):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        return s[1:-1]
    return s

for kind in ("yaml_key","frontmatter_key","env_var"):
    bucket = data.get(kind, {}) or {}
    for k,v in list(bucket.items()):
        # si la valeur est une chaîne qui elle-même contient un wrapping de quotes, on retire
        if isinstance(v, str) and re.match(r"^(['\"]).*\1$", v.strip()):
            inner = strip_outer_quotes(v)
            bucket[k] = inner
        # normalisations par clé
        if kind == "yaml_key" and k == "python-version":
            bucket[k] = str(bucket[k])  # toujours chaîne "3.12"
        if kind == "yaml_key" and k == "timeout-minutes":
            # force entier si possible
            try:
                bucket[k] = int(str(bucket[k]).strip())
            except Exception:
                pass
    data[kind] = bucket

p.write_text(yaml.safe_dump(data, sort_keys=True, allow_unicode=True), encoding="utf-8")
print("[fix-defaults] normalized", p)
