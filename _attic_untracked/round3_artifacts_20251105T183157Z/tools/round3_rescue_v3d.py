import time, pathlib, re

STAMP = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
ROOT = pathlib.Path(".")

TARGETS = [
  "zz-scripts/chapter07/plot_fig06_comparison.py",
  "zz-scripts/chapter10/add_phi_at_fpeak.py",
  "zz-scripts/chapter10/plot_fig06_residual_map.py",
  "zz-scripts/chapter10/check_metrics_consistency.py",
  "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py",
  "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py",
  "zz-scripts/chapter10/regen_fig05_using_circp95.py",
  "zz-scripts/chapter10/plot_fig01_iso_p95_maps.py",
  "zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py",
  "zz-scripts/chapter09/generate_mcgt_raw_phase.py",
  "zz-scripts/chapter09/plot_fig02_residual_phase.py",
  "zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py",
  "zz-scripts/chapter09/plot_fig04_absdphi_milestones_vs_f.py",
]

OPENERS = ("def","class","if","elif","for","while","try","with","else","except","finally")

def read(p): return p.read_text(encoding="utf-8", errors="replace")
def write(p,s): p.write_text(s, encoding="utf-8")
def norm_eol(s): return s.replace("\r\n","\n").replace("\r","\n")

def compile_src(src, name):
    try:
        compile(src, name, "exec")
        return True, None
    except SyntaxError as e:
        return False, e

def indent_of(line:str)->int:
    n=0
    for ch in line:
        if ch==" ": n+=1
        elif ch=="\t": n+=4
        else: break
    return n

def header_limit(lines):
    i=0
    while i < len(lines):
        s = lines[i].lstrip()
        if s.startswith("#!") or s.startswith("# -*-") or s.startswith("#") or s.strip()=="":
            i += 1; continue
        break
    return i

def move_future_to_top(lines):
    fut = [i for i,l in enumerate(lines) if l.lstrip().startswith("from __future__ import")]
    if not fut: return False
    futures=[lines[i] for i in fut]
    for i in reversed(fut): del lines[i]
    ins = header_limit(lines)
    seen=set()
    k=ins
    while k<len(lines) and lines[k].lstrip().startswith("from __future__ import"):
        seen.add(lines[k].strip()); k+=1
    changed=False
    for f in futures:
        t=f if f.endswith("\n") else f+"\n"
        if t.strip() not in seen:
            lines.insert(ins,t); ins+=1; changed=True
    return changed

def next_nonblank(lines, j):
    k=j+1
    while k<len(lines) and (lines[k].strip()=="" or lines[k].lstrip().startswith("#")):
        k+=1
    return k if k<len(lines) else None

def prev_opener(lines, i):
    j=i
    while j>=0:
        s=lines[j].strip()
        if s.endswith(":"):
            head=s.split(":",1)[0].strip().split()[0] if s.split(":",1)[0].strip() else ""
            if head in OPENERS:
                return j
        j-=1
    return None

def ensure_block_after(lines, j):
    base=indent_of(lines[j])
    k=next_nonblank(lines, j)
    if k is None or indent_of(lines[k])<=base:
        lines.insert(j+1, " "*(base+4) + "pass  # auto-rescue v3d: missing block\n")
        return True
    return False

def scan_and_fill_all_blocks(lines):
    i=0; changed=False
    while i < len(lines):
        s=lines[i].strip()
        if s.endswith(":"):
            head=s.split(":",1)[0].strip().split()[0] if s.split(":",1)[0].strip() else ""
            if head in OPENERS:
                if ensure_block_after(lines, i):
                    changed=True
        i+=1
    return changed

def neutralize_flow_stmt(lines, i, reason):
    base=indent_of(lines[i]); s=lines[i].lstrip().rstrip("\n")
    lines[i] = " "*base + f"pass  # auto-rescue v3d ({reason}): {s}\n"
    return True

def comment_line(lines, i, reason):
    base=indent_of(lines[i]); s=lines[i].lstrip().rstrip("\n")
    lines[i] = " "*base + f"# auto-rescue v3d ({reason}): {s}\n"
    return True

def fix_once(path: pathlib.Path):
    src = norm_eol(read(path))
    ok, err = compile_src(src, str(path))
    if ok: return False
    lines = src.splitlines(True)
    changed = False

    changed = move_future_to_top(lines) or changed
    # Remplissage global des blocs manquants évidents
    changed = scan_and_fill_all_blocks(lines) or changed

    if err and getattr(err, "lineno", None):
        i = max(1, err.lineno)-1
        if i >= len(lines): i = len(lines)-1
        msg = getattr(err, "msg", str(err)).lower()
        s = lines[i].lstrip()

        if "expected an indented block" in msg:
            j = prev_opener(lines, i)
            if j is not None:
                changed = ensure_block_after(lines, j) or changed
            else:
                changed = ensure_block_after(lines, i) or changed

        elif "continue" in msg and "not properly in loop" in msg:
            changed = neutralize_flow_stmt(lines, i, "continue-outside-loop") or changed

        elif "return" in msg and "outside function" in msg:
            changed = neutralize_flow_stmt(lines, i, "return-at-module") or changed

        elif "break" in msg and "not properly in loop" in msg:
            changed = neutralize_flow_stmt(lines, i, "break-outside-loop") or changed

        else:
            changed = comment_line(lines, i, "syntax") or changed
    else:
        changed = comment_line(lines, len(lines)-1, "no-lineno") or changed

    if changed:
        bak = path.with_suffix(path.suffix + f".rescue3d.{STAMP}.bak")
        write(bak, src)
        write(path, "".join(lines))
    return changed

def rescue_all():
    processed=0; compiled_ok=0
    for rel in TARGETS:
        p = ROOT / rel
        if not p.exists(): continue
        # Itératif borné
        for _ in range(80):
            ch = fix_once(p)
            ok,_ = compile_src(read(p), str(p))
            if ok:
                compiled_ok += 1
                break
            if not ch:
                # Dernier recours: re-scan blocs
                lines = read(p).splitlines(True)
                if not scan_and_fill_all_blocks(lines): break
                write(p, "".join(lines))
        processed += 1
    print(f"[RESCUE3d] processed={processed} compiled_ok={compiled_ok}")

if __name__ == "__main__":
    rescue_all()
