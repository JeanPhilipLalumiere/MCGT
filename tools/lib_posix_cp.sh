# helper POSIX: safe_cp SRC DEST
# conserve le comportement "ne pas écraser si DEST existe"
safe_cp() {
  src="$1"; dest="$2"
  if [ -e "$dest" ]; then
    return 0
  fi
  cp "$src" "$dest"
}
export -f safe_cp 2>/dev/null || true
