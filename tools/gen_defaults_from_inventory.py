import collections
import csv
import pathlib
import re
import sys

import yaml

tsv = pathlib.Path(".ci-out/params/params-inventory.tsv")
if not tsv.exists():
    print("no inventory: run tools/scan_params.sh first", file=sys.stderr)
    sys.exit(2)

# Quelles clés on canonise ? (ajoute-en ici selon tes besoins)
YL = {"python-version"}  # on laisse 'timeout-minutes' de côté pour éviter le bruit
FM = set()  # ex: {"chapter", "dataset"} si tu veux
EV = set()  # ex: {"SEED"} si tu veux


def norm_scalar(s: str):
    s = (s or "").strip()
    # retire guillemets d'encadrement simples/doubles si symétriques
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ("'", '"'):
        s = s[1:-1]
    # convertit en int si entier pur (on ne touche pas aux floats comme 3.12)
    if re.fullmatch(r"[0-9]+", s):
        try:
            return int(s)
        except Exception:
            pass
    return s


freq = {"yaml_key": {}, "frontmatter_key": {}, "env_var": {}}
with tsv.open(encoding="utf-8") as fh:
    rdr = csv.DictReader(fh, delimiter="\t")
    for row in rdr:
        path = row["FILE"]
        if "/.ci-archive/" in path:
            continue
        kind = row["KIND"]
        name = row["NAME"]
        val = norm_scalar(row["SAMPLE_VALUE"])
        if kind == "yaml_key" and name not in YL:
            continue
        if kind == "frontmatter_key" and name not in FM:
            continue
        if kind == "env_var" and name not in EV:
            continue
        freq.setdefault(kind, {}).setdefault(name, collections.Counter())[val] += 1


def pick_majority(counter: collections.Counter):
    if not counter:
        return None
    return counter.most_common(1)[0][0]


defaults = {"yaml_key": {}, "frontmatter_key": {}, "env_var": {}}
for kind, bucket in freq.items():
    for name, counter in bucket.items():
        val = pick_majority(counter)
        if val is not None:
            defaults[kind][name] = val

# ajoute/force des canons explicites si tu veux :
defaults["yaml_key"].setdefault("python-version", "3.12")

yaml.safe_dump(defaults, sys.stdout, sort_keys=True, allow_unicode=True)
