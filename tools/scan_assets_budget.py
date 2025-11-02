#!/usr/bin/env python3
import os, sys, json, hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CFG  = ROOT/".github"/"assets_budget.yml"

# Extensions surveillées (images/doc figures)
EXTS = {".png",".jpg",".jpeg",".webp",".svg",".pdf",".tif",".tiff"}

def load_cfg():
    # YML minimal sans dépendance PyYAML : on tolère K: V simples, sinon défauts généreux.
    defaults = {
        "max_file_mb": 50,     # par fichier
        "max_dir_mb":  300,    # par dossier (agrégé)
        "paths": ["zz-figures","chapters","chapter","figures","assets"]
    }
    if not CFG.exists():
        return defaults
    data = defaults.copy()
    try:
        for line in CFG.read_text(encoding="utf-8").splitlines():
            s=line.strip()
            if not s or s.startswith("#"): 
                continue
            if ":" in s and not s.startswith("-"):
                k,v = s.split(":",1)
                k=k.strip(); v=v.strip()
                if k in ("max_file_mb","max_dir_mb"):
                    data[k] = int(v)
                elif k=="paths":
                    # laisser la section paths se remplir via lignes suivantes commençant par '-'
                    data["paths"] = []
            elif s.startswith("-"):
                p=s[1:].strip().strip('"').strip("'")
                if p: data.setdefault("paths",[]).append(p)
    except Exception:
        pass
    if not data.get("paths"):
        data["paths"]=defaults["paths"]
    return data

def human(sz):
    for u in ("B","KB","MB","GB"):
        if sz < 1024 or u=="GB":
            return f"{sz:.1f} {u}"
        sz/=1024

def scan(paths, max_file, max_dir):
    violations=[]
    total_dirs=0
    for base in paths:
        base_path = ROOT/base
        if not base_path.exists():
            continue
        for dirpath, _, files in os.walk(base_path):
            total_dirs+=1
            dirsum=0
            for f in files:
                p=Path(dirpath)/f
                if p.suffix.lower() not in EXTS: 
                    continue
                sz = p.stat().st_size
                dirsum += sz
                if sz > max_file*1024*1024:
                    violations.append({
                        "type":"file",
                        "path":str(p.relative_to(ROOT)),
                        "size_bytes":sz
                    })
            if dirsum > max_dir*1024*1024:
                violations.append({
                    "type":"dir",
                    "path":str(Path(dirpath).relative_to(ROOT)),
                    "size_bytes":dirsum
                })
    return violations,total_dirs

def main():
    cfg = load_cfg()
    viols, ndirs = scan(cfg["paths"], cfg["max_file_mb"], cfg["max_dir_mb"])
    print(f"[INFO] scanned_dirs={ndirs} paths={cfg['paths']} "
          f"limits={{file:{cfg['max_file_mb']}MB, dir:{cfg['max_dir_mb']}MB}}")
    if not viols:
        print("::notice title=assets-budgets::OK — aucune violation.")
        return 0
    print("::group::assets-budgets violations")
    for v in viols:
        if v["type"]=="file":
            print(f"::error title=Oversize file:: {v['path']} ({human(v['size_bytes'])})")
        else:
            print(f"::error title=Oversize dir::  {v['path']} total={human(v['size_bytes'])}")
    print("::endgroup::")
    return 1

if __name__=="__main__":
    sys.exit(main())
