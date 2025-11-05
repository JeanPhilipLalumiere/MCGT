from __future__ import annotations
import os, sys, time, shutil, subprocess, argparse, hashlib
from pathlib import Path

STAMP = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())

TARGETS = [
    Path("_attic_untracked/migrate_staging/20251028T203441Z/tools/apply_figure_renames_and_fix_refs.py"),
    Path("release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__init__.py"),
    Path("release_zenodo_codeonly/v0.3.x/mcgt/mcgt/phase.py"),
    Path("release_zenodo_codeonly/v0.3.x/mcgt/mcgt/scalar_perturbations.py"),
    Path("tools/scan_assets_budget.py"),
    Path("zz-manifests/diag_consistency.py"),
    Path("zz-schemas/validate_csv_table.py"),
    Path("zz-tools/patch_ch09_defaults_v2.py"),
    Path("zz-tools/patch_ch09_defaults_v4.py"),
    Path("zz-tools/patch_ch09_defaults_v5.py"),
    Path("zz-tools/patch_ch09_defaults_v6.py"),
]

def sh(*cmd, check=True, cwd=None, env=None, capture=False, text=True):
    if capture:
        return subprocess.run(cmd, check=check, cwd=cwd, env=env, text=text,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return subprocess.run(cmd, check=check, cwd=cwd, env=env, text=text)

def find_repo_root() -> Path:
    try:
        out = sh("git", "rev-parse", "--show-toplevel", capture=True).stdout.strip()
        p = Path(out)
        if p.exists():
            return p
    except Exception:
        pass
    cur = Path.cwd()
    for p in (cur, *cur.parents):
        if (p / ".git").exists():
            return p
    return cur

ROOT = find_repo_root()
SANDBOX = ROOT / f"_autofix_sandbox/{STAMP}"

def copy_minimal():
    if SANDBOX.exists():
        shutil.rmtree(SANDBOX)
    SANDBOX.mkdir(parents=True, exist_ok=True)
    for rel in TARGETS:
        src = ROOT / rel
        if not src.exists():
            continue
        dst = SANDBOX / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)

def normalize_ascii(p: Path):
    txt = p.read_text(encoding="utf-8", errors="ignore")
    repl = {
        "’": "'", "‘": "'", "“": '"', "”": '"',
        "–": "-", "—": "-", "−": "-",
        "…": "...", "→": "->", "←": "<-", "↔": "<->",
        "©": "(c)", "®": "(R)", "∈": " in ",
    }
    for k, v in repl.items():
        txt = txt.replace(k, v)
    lines = txt.splitlines(True)
    head = "".join(lines[:2])
    if "# -*- coding:" not in head and "coding=" not in head and not head.startswith("#!"):
        lines.insert(0, "# -*- coding: utf-8 -*-\n")
    p.write_text("".join(lines), encoding="utf-8")

def move_future_to_top(p: Path):
    import re
    s = p.read_text(encoding="utf-8", errors="ignore")
    fut = re.compile(r'^\s*from\s+__future__\s+import\s+(.+?)\s*(#.*)?$', re.M)
    found = fut.findall(s)
    if not found:
        return
    s2 = fut.sub("", s)
    DOC = r'\A((?:#![^\n]*\n)?(?:(?:#.*\n)|(?:\#.*\r\n))*\s*(?P<doc>(?s:(""".*?"""|\'\'\'.*?\'\'\'))\s*)?)'
    m = re.match(DOC, s2)
    head = m.group(0) if m else ""
    body = s2[len(head):]
    specs: list[str] = []
    for grp, _ in found:
        for part in grp.split(","):
            spec = part.strip()
            if spec and spec not in specs:
                specs.append(spec)
    if "annotations" in specs:
        specs.remove("annotations")
        specs = ["annotations"] + specs
    fut_line = f"from __future__ import {', '.join(specs)}\n"
    p.write_text(head + fut_line + body, encoding="utf-8")

def sandbox_sanitize_and_compile() -> int:
    bad = 0
    for rel in TARGETS:
        f = SANDBOX / rel
        if not f.exists() or f.suffix != ".py":
            continue
        normalize_ascii(f)
        move_future_to_top(f)
        try:
            compile(f.read_text(encoding="utf-8", errors="ignore"), str(f), "exec")
        except Exception as e:
            print(f"[SANDBOX-ERR] {f.relative_to(SANDBOX)} :: {type(e).__name__}: {e}")
            bad += 1
    print(f"[SANDBOX] compile summary: bad={bad}")
    return bad

def sha256_bytes(b: bytes) -> str:
    h = hashlib.sha256(); h.update(b); return h.hexdigest()

def is_ignored(rel: Path) -> bool:
    # 0 si ignoré, 1 sinon
    r = sh("git", "-C", str(ROOT), "check-ignore", "-n", "--", str(rel),
           check=False, capture=True)
    return r.returncode == 0

def apply_and_commit(commit_msg: str, no_verify: bool, force_ignored: bool) -> int:
    changed: list[str] = []
    backups: list[Path] = []
    for rel in TARGETS:
        src = SANDBOX / rel
        dst = ROOT / rel
        if not src.exists():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        after = src.read_bytes()
        before = dst.read_bytes() if dst.exists() else b""
        if sha256_bytes(before) != sha256_bytes(after):
            if dst.exists():
                bak = dst.with_suffix(dst.suffix + f".autofix.{STAMP}.bak")
                bak.parent.mkdir(parents=True, exist_ok=True)
                bak.write_bytes(before)
                backups.append(bak)
                print(f"[BACKUP] {dst} -> {bak.name}")
            dst.write_bytes(after)
            changed.append(rel.as_posix())
            print(f"[APPLY]  {rel}")
        else:
            print(f"[SKIP]   {rel} (identique)")

    if not changed:
        print("[APPLY] aucun changement à committer.")
        return 0

    normal, ignored = [], []
    for p in changed:
        (ignored if is_ignored(Path(p)) else normal).append(p)

    if normal:
        sh("git", "-C", str(ROOT), "add", "--", *normal)

    if ignored and force_ignored:
        print(f"[FORCE-ADD] fichiers ignorés par .gitignore → add -f ({len(ignored)})")
        sh("git", "-C", str(ROOT), "add", "-f", "--", *ignored)
    elif ignored:
        print("[SKIP-IGNORED] non ajoutés (présents dans .gitignore):")
        for p in ignored:
            print(f" - {p}")

    # Rien à indexer ?
    diff = sh("git", "-C", str(ROOT), "diff", "--cached", "--name-only", capture=True).stdout.strip()
    if not diff:
        print("[ABORT] index vide (tout ignoré ou identique) — aucun commit.")
        return 0

    env = os.environ.copy()
    env["MCGT_UNSEAL"] = "1"
    cmd = ["git", "-C", str(ROOT), "commit", "-m", commit_msg]
    if no_verify:
        cmd.append("--no-verify")
    sh(*cmd, env=env)
    print(f"[COMMIT] OK → '{commit_msg}'")
    return 0

def main():
    ap = argparse.ArgumentParser(description="Autofix sandbox: sanitize + apply + commit (non-interactif)")
    ap.add_argument("--apply", action="store_true", help="Appliquer et committer automatiquement")
    ap.add_argument("--commit", default=f"autofix(sandbox): ascii + future placement ({STAMP})",
                    help="Message de commit")
    ap.add_argument("--no-verify", action="store_true", help="Désactiver les hooks pre-commit")
    ap.add_argument("--force-ignored", action="store_true",
                    help="Forcer l'ajout des fichiers ignorés par .gitignore (git add -f)")
    args = ap.parse_args()

    print(f"[INFO] repo root = {ROOT}")
    copy_minimal()
    bad = sandbox_sanitize_and_compile()
    if bad:
        print("[ABORT] Erreurs de compilation dans le sandbox — aucune modification appliquée.")
        sys.exit(1)

    if args.apply:
        sys.exit(apply_and_commit(args.commit, args.no_verify, args.force_ignored))
    else:
        print("[READY] Sandbox prêt. Lance avec --apply pour appliquer et committer.")
        print(f"        SANDBOX = {SANDBOX}")
        sys.exit(0)

if __name__ == "__main__":
    main()
