import re, time, pathlib

STAMP = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
ROOT = pathlib.Path(".")

TARGETS = [
  "zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py",
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
    """Retourne l'index où on peut insérer les __future__ (après shebang/encoding/commentaires vides)."""
    i=0
    while i < len(lines):
        s = lines[i].lstrip()
        if s.startswith("#!") or s.startswith("# -*-") or s.startswith("#"):
            i += 1; continue
        if s.strip()=="":
            i += 1; continue
        break
    return i

def move_future_to_top(lines):
    fut_idxs = [i for i,l in enumerate(lines) if l.lstrip().startswith("from __future__ import")]
    if not fut_idxs: return False
    futures = [lines[i] for i in fut_idxs]
    # supprime occurrences (du bas vers le haut)
    for i in reversed(fut_idxs):
        del lines[i]
    # insertion après préambule
    ins = header_limit(lines)
    # évite doublons exacts
    exist = set()
    k=ins
    while k < len(lines) and lines[k].lstrip().startswith("from __future__ import"):
        exist.add(lines[k].strip()); k+=1
    for f in futures:
        if f.strip() not in exist:
            lines.insert(ins, f if f.endswith("\n") else f+"\n")
            ins += 1
    return True

OPENERS = ("def","class","if","elif","for","while","try","with","else","except","finally")

def ensure_block_at(lines, i):
    L = lines[i].rstrip("\n")
    s = L.lstrip()
    if not s.endswith(":"): return False
    head = s.split(":",1)[0].strip().split()[0] if s.split(":",1)[0].strip() else ""
    if head not in OPENERS: return False
    base = indent_of(L)
    j = i+1
    while j < len(lines):
        t = lines[j].lstrip()
        if t=="" or t.startswith("#"):
            j += 1; continue
        break
    if j>=len(lines) or indent_of(lines[j]) <= base:
        lines.insert(i+1, " "*(base+4) + "pass  # auto-rescue v3c: missing block\n")
        return True
    return False

def fix_continue_break_return_at_module(lines, i):
    s = lines[i].lstrip()
    kw = s.split()[0]
    base = indent_of(lines[i])
    if base==0 and kw in ("continue","break","return"):
        lines[i] = "pass  # auto-rescue v3c: {} at module level\n".format(kw)
        return True
    return False

def comment_line(lines, i, reason="generic"):
    base = indent_of(lines[i]); s = lines[i].lstrip().rstrip("\n")
    lines[i] = " "*base + f"# auto-rescue v3c ({reason}): " + s + "\n"

def fix_once(path: pathlib.Path):
    src = norm_eol(read(path))
    ok, err = compile_src(src, str(path))
    if ok: return False
    lines = src.splitlines(True)
    changed = False

    # Toujours tenter de remonter les __future__ au début
    changed = move_future_to_top(lines) or changed

    if err and getattr(err, "lineno", None):
        i = max(1, err.lineno) - 1
        if i >= len(lines): i = len(lines)-1
        msg = getattr(err, "msg", str(err))
        s = lines[i].lstrip()

        if "from __future__ imports must occur at the beginning" in msg:
            # On vient déjà de déplacer; si recompilation échoue encore, commente la ligne fautive
            comment_line(lines, i, "future-not-top")
            changed = True

        elif "not properly in loop" in msg:
            # continue/break hors boucle
            changed = fix_continue_break_return_at_module(lines, i) or changed
            if not changed: comment_line(lines, i, "continue/break") ; changed = True

        elif "expected an indented block" in msg:
            changed = ensure_block_at(lines, i) or changed

        elif s.startswith("return") and indent_of(lines[i])==0:
            lines[i] = "pass  # auto-rescue v3c: return at module level\n"; changed = True

        else:
            # Cas divers (unmatched, invalid syntax résiduelle) → commenter la ligne fautive
            comment_line(lines, i, "syntax")
            changed = True
    else:
        # pas de lineno → commenter dernière ligne
        comment_line(lines, len(lines)-1, "no-lineno")
        changed = True

    if changed:
        bak = path.with_suffix(path.suffix + f".rescue3c.{STAMP}.bak")
        write(bak, src)
        write(path, "".join(lines))
    return changed

def rescue_all():
    processed=0; compiled_ok=0
    for rel in TARGETS:
        p = ROOT / rel
        if not p.exists(): continue
        # boucle bornée
        for _ in range(40):
            ch = fix_once(p)
            ok,_ = compile_src(read(p), str(p))
            if ok:
                compiled_ok += 1
                break
            if not ch:
                # dernière chance : si bloc manquant probable, tente ensure_block sur la ligne d'avant
                break
        processed += 1
    print(f"[RESCUE3c] processed={processed} compiled_ok={compiled_ok}")

if __name__ == "__main__":
    rescue_all()
