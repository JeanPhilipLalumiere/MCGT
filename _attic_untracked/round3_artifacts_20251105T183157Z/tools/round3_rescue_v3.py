import re, time, pathlib

ROOT = pathlib.Path(".")
STAMP = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())

def read(p): return p.read_text(encoding="utf-8", errors="replace")
def write(p, s): p.write_text(s, encoding="utf-8")

OPENERS = ("def","class","if","elif","for","while","try","with","else","except","finally")

def normalize_eols(s:str)->str:
    s = s.replace("\r\n","\n").replace("\r","\n")
    return s

def compile_source(src:str, fname:str):
    try:
        compile(src, fname, "exec")
        return True, None
    except SyntaxError as e:
        return False, e

def line_indent(s:str)->int:
    n=0
    for ch in s:
        if ch==" ": n+=1
        elif ch=="\t": n+=4
        else: break
    return n

def ensure_body_if_needed(lines, i):
    # Si la ligne i est un ouvreur nécessitant un bloc, et que la suivante utile
    # n'est pas plus indentée → insérer un 'pass'
    L = lines[i].rstrip("\n")
    s = L.lstrip()
    if not s.endswith(":"): return False
    kw = s.split(":",1)[0].strip().split()
    if not kw: return False
    head = kw[0]
    if head not in OPENERS: return False
    base = line_indent(L)
    # chercher prochaine ligne non vide/non commentaire
    j = i+1
    while j < len(lines):
        t = lines[j].lstrip()
        if t=="" or t.startswith("#"):
            j += 1; continue
        break
    if j>=len(lines): 
        lines.insert(i+1, " "*(base+4) + "pass  # auto-rescue: missing block\n")
        return True
    # si la prochaine n'est pas plus indentée → insérer pass
    if line_indent(lines[j]) <= base:
        lines.insert(i+1, " "*(base+4) + "pass  # auto-rescue: missing block\n")
        return True
    return False

def fix_once(path:pathlib.Path)->bool:
    src = normalize_eols(read(path))
    ok, err = compile_source(src, str(path))
    if ok: return False  # rien à faire

    lines = src.splitlines(True)
    if not err or not getattr(err, "lineno", None):
        # Fallback: commenter la dernière ligne pour débloquer
        if lines:
            lines[-1] = "# auto-rescue: commented (no lineno)\n"
        write(path, "".join(lines))
        return True

    i = max(1, err.lineno) - 1
    if i >= len(lines): i = len(lines)-1
    L = lines[i].rstrip("\n")
    s = L.lstrip()
    base = line_indent(L)
    changed = False

    # 1) Orphelins except/finally → if False:
    if s.startswith(("except","finally")):
        lines[i] = " "*base + "if False:  # auto-rescue: orphan " + s.split(":",1)[0] + "\n"
        changed = True

    # 2) Orphelin else → if True:
    elif s.startswith("else:"):
        lines[i] = " "*base + "if True:  # auto-rescue: orphan else\n"
        changed = True

    # 3) Return au niveau module
    elif s.startswith("return") and base == 0:
        lines[i] = " "*base + "pass  # auto-rescue: return at module level\n"
        changed = True

    # 4) Corps manquant après ouvreur → insérer pass (utilise message du compilateur)
    elif "expected an indented block" in str(err):
        # si l'erreur pointe sur la ligne qui ouvre
        if s.endswith(":"):
            ensure_body_if_needed(lines, i)
            changed = True

    # 5) Parenthèses incohérentes / invalid syntax générique → commenter
    elif ("unmatched" in str(err) or "invalid syntax" in str(err)
          or "expected 'except' or 'finally' block" in str(err)
          or "expected an indented block" in str(err)):
        # Cas très fréquent: else: / except: déjà traités plus haut
        # Sinon, commenter la ligne fautive
        lines[i] = " "*base + "# auto-rescue: commented → " + s + "\n"
        changed = True

    # 6) Après modification, vérifier si la ligne i est un ouvreur sans corps → pass
    if i < len(lines) and lines[i].lstrip().rstrip().endswith(":"):
        changed = ensure_body_if_needed(lines, i) or changed

    if changed:
        bak = path.with_suffix(path.suffix + f".rescue3.{STAMP}.bak")
        write(bak, src)
        write(path, "".join(lines))
        return True

    # Fallback ultime: commenter la ligne
    lines[i] = " "*base + "# auto-rescue(fallback): " + s + "\n"
    bak = path.with_suffix(path.suffix + f".rescue3.{STAMP}.bak")
    write(bak, src)
    write(path, "".join(lines))
    return True

def rescue_all():
    targets = sorted(ROOT.glob("zz-scripts/**/*.py"))
    touched = 0
    for p in targets:
        # boucle de réparation bornée
        for _ in range(25):
            changed = fix_once(p)
            ok, _ = compile_source(read(p), str(p))
            if ok: break
            if not changed: break
        ok, _ = compile_source(read(p), str(p))
        if not ok:
            # on laisse un marqueur pour finir manuellement
            print("[FAIL]", p)
        else:
            touched += 1
    print(f"[RESCUE3] processed={len(targets)} compiled_ok={touched}")

if __name__ == "__main__":
    rescue_all()
