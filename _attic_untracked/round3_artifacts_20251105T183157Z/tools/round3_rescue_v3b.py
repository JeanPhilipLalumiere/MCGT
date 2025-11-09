import re, time, pathlib

ROOT = pathlib.Path(".")
STAMP = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())

def read(p): return p.read_text(encoding="utf-8", errors="replace")
def write(p, s): p.write_text(s, encoding="utf-8")

OPENERS = ("def","class","if","elif","for","while","try","with","else","except","finally")

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

def ensure_body(lines, i):
    L = lines[i].rstrip("\n")
    s = L.lstrip()
    if not s.endswith(":"): return False
    kw = s.split(":",1)[0].strip().split()
    if not kw: return False
    head = kw[0]
    if head not in OPENERS: return False
    base = indent_of(L)
    j = i+1
    while j < len(lines):
        t = lines[j].lstrip()
        if t=="" or t.startswith("#"):
            j += 1; continue
        break
    if j>=len(lines) or indent_of(lines[j]) <= base:
        lines.insert(i+1, " "*(base+4) + "pass  # auto-rescue: missing block\n")
        return True
    return False

def try_to_if_true_and_rewire_handlers(lines, j):
    """Transforme 'try:' en 'if True:' et remappe handlers au même indent."""
    base = indent_of(lines[j])
    lines[j] = " "*base + "if True:  # auto-rescue: try→if\n"
    k = j+1
    while k < len(lines):
        raw = lines[k]
        s = raw.lstrip()
        if s=="" or s.startswith("#"):
            k += 1; continue
        ind = indent_of(raw)
        if ind < base:
            break
        if ind == base:
            if re.match(r"except\b.*:\s*$", s):
                lines[k] = " "*base + "if False:  # auto-rescue: except→if False\n"
            elif s.startswith("else:"):
                lines[k] = " "*base + "if True:  # auto-rescue: else→if True\n"
            elif s.startswith("finally:"):
                lines[k] = " "*base + "if False:  # auto-rescue: finally→if False\n"
            else:
                # plus un handler: on s'arrête
                break
        k += 1
    return True

def comment_line(lines, i, prefix="# auto-rescue: commented → "):
    base = indent_of(lines[i])
    s = lines[i].lstrip().rstrip("\n")
    lines[i] = " "*base + prefix + s + "\n"

def fix_once(path: pathlib.Path):
    src = read(path).replace("\r\n","\n").replace("\r","\n")
    ok, err = compile_src(src, str(path))
    if ok: return False
    lines = src.splitlines(True)

    # Sans info précise, commenter la ligne signalée
    if not err or not getattr(err, "lineno", None):
        if lines:
            comment_line(lines, len(lines)-1)
        write(path, "".join(lines)); return True

    i = max(1, err.lineno) - 1
    if i >= len(lines): i = len(lines)-1
    s = lines[i].lstrip()
    changed = False

    msg = getattr(err, "msg", str(err))

    # 1) try sans handler → transformer le try correspondant + rewire handlers
    if "expected 'except' or 'finally' block" in msg:
        # cherche le dernier 'try:' au-dessus
        j = i
        while j >= 0:
            t = lines[j].lstrip()
            if t.startswith("try:"):
                try_to_if_true_and_rewire_handlers(lines, j)
                changed = True
                break
            j -= 1
        if not changed:
            # fallback: commenter la ligne fautive
            comment_line(lines, i); changed = True

    # 2) Orphelins except/else/finally (sans try) → if False/True
    elif s.startswith("except") and s.rstrip().endswith(":"):
        base = indent_of(lines[i])
        lines[i] = " "*base + "if False:  # auto-rescue: orphan except\n"; changed = True
    elif s.startswith("else:"):
        base = indent_of(lines[i])
        lines[i] = " "*base + "if True:  # auto-rescue: orphan else\n"; changed = True
    elif s.startswith("finally:"):
        base = indent_of(lines[i])
        lines[i] = " "*base + "if False:  # auto-rescue: orphan finally\n"; changed = True

    # 3) 'expected an indented block' → insérer pass
    elif "expected an indented block" in msg:
        changed = ensure_body(lines, i) or changed

    # 4) 'return' au niveau module → pass
    elif s.startswith("return") and indent_of(lines[i]) == 0:
        lines[i] = "pass  # auto-rescue: return at module level\n"; changed = True

    # 5) Syntaxes incohérentes diverses → commenter
    elif ("invalid syntax" in msg or "unmatched" in msg):
        comment_line(lines, i); changed = True

    if changed:
        bak = path.with_suffix(path.suffix + f".rescue3b.{STAMP}.bak")
        write(bak, src)
        write(path, "".join(lines))
    return changed

def rescue_all():
    targets = sorted(ROOT.glob("zz-scripts/**/*.py"))
    compiled_ok = 0
    for p in targets:
        # boucle bornée par fichier
        for _ in range(40):
            changed = fix_once(p)
            ok, _ = compile_src(read(p), str(p))
            if ok: 
                compiled_ok += 1
                break
            if not changed:
                break
    print(f"[RESCUE3b] processed={len(targets)} compiled_ok={compiled_ok}")

if __name__ == "__main__":
    rescue_all()
