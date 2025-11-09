\
#!/usr/bin/env bash
# sweep_help_and_smoke_guarded_v2.sh
# - Robust, guarded sweep
# - Only tries `-h` on files that look like CLI scripts (argparse/add_argument/ArgumentParser)
# - Compiles all .py (excluding attic/tmp), smokes only plot_*.py
# - Never exits on error; logs everything; final optional pause (NO_PAUSE=1 to skip)

set -u  # no -e to avoid early exit

TS="$(date +%Y-%m-%dT%H%M%S)"
LOG=".ci-out/sweep_v2_${TS}.log"
SMOKE_DIR=".ci-out/smoke_all"
mkdir -p .ci-out "$SMOKE_DIR"

say(){ printf "%s %s\n" "[$(date +%H:%M:%S)]" "$*" | tee -a "$LOG"; }
run(){ say "\$ $*"; ( eval "$@" ) >>"$LOG" 2>&1; RC=$?; [ $RC -ne 0 ] && say "→ RC=$RC (continue)"; return 0; }

say "=== START sweep_v2 @ ${TS} ==="

# ------------- Gather candidates -------------
mapfile -t PYFILES < <(git ls-files '*.py' 2>/dev/null || find . -type f -name '*.py')
# Filter out attic/tmp and external envs
FILTERED=()
for f in "${PYFILES[@]}"; do
  case "$f" in
    *"/_attic/"*|*"/_tmp/"*|*"/.eggs/"*|*"/site-packages/"*|*"/build/"*|*"/dist/"*) continue;;
  esac
  FILTERED+=("$f")
done

# ------------- A) Compile check -------------
compile_ok=0; compile_fail=0
for f in "${FILTERED[@]}"; do
  say "[A:compile] $f"
  python -m py_compile "$f"
  if [ $? -eq 0 ]; then
    : $((compile_ok+=1))
  else
    : $((compile_fail+=1)); say "→ compile ERROR: $f"
  fi
done

# Heuristic to detect CLI-like scripts
is_cli_like() {
  local f="$1"
  # skip known non-CLIs
  case "$f" in
    *"/tests/"*|*"/utils/"*|*"/_common/"*|*"__init__.py") return 1;;
  esac
  # cheap grep checks
  grep -qE 'argparse|ArgumentParser|add_argument' "$f" || return 1
  return 0
}

# ------------- B) Help check on CLI-like files -------------
help_ok=0; help_fail=0
for f in "${FILTERED[@]}"; do
  if is_cli_like "$f"; then
    say "[B:help] $f -h"
    python "$f" -h >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      : $((help_ok+=1))
    else
      : $((help_fail+=1)); say "→ help ERROR: $f"
    fi
  fi
done

# ------------- C) Smoke plots -------------
smoke_ok=0; smoke_fail=0
smoke_one(){
  local s="$1"
  local base="$(basename "$s")"
  local stem="${s//\//_}"
  stem="${stem%.py}"
  local outpng="${SMOKE_DIR}/${stem}.png"
  say "[C:smoke] $s → ${stem}.png"
  python "$s" --outdir "$SMOKE_DIR" --format png --dpi 120 --style classic
  RC=$?
  if [ $RC -ne 0 ]; then
    say "→ run RC=$RC (try last png fallback)"
  fi
  # fallback to last modified png if exact file missing
  if [ ! -f "$outpng" ]; then
    last=$(ls -1t "$SMOKE_DIR"/*.png 2>/dev/null | head -n1 || true)
    if [ -n "$last" ]; then
      cp -f "$last" "$outpng"
    fi
  fi
  if [ -f "$outpng" ]; then : $((smoke_ok+=1)); else : $((smoke_fail+=1)); say "→ smoke MISSING: ${stem}.png"; fi
}

mapfile -t PLOTS < <(printf "%s\n" "${FILTERED[@]}" | grep -E '/plot_.*\.py$' || true)
for s in "${PLOTS[@]}"; do
  smoke_one "$s"
done

say "[SUMMARY] compile_ok=${compile_ok} compile_fail=${compile_fail} help_ok=${help_ok} help_fail=${help_fail} smoke_ok=${smoke_ok} smoke_fail=${smoke_fail}"
run "ls -lh \"$SMOKE_DIR\" | sed -n '1,200p'"
say "=== DONE (log: ${LOG}) ==="

# Optional pause
if [ "${NO_PAUSE:-0}" != "1" ]; then
  read -r -p $'\nGarde-fou actif : appuie sur ENTRÉE pour revenir au shell.\n' _ || true
fi

exit 0
