# PSX library (robust pause) — source me from your scripts
#   . tools/lib_psx.sh
#   psx_install "Étape X — Description"
psx_install() {
  _psx_label="${1:-Run}"
  : "${WAIT_ON_EXIT:=1}"
  trap 'psx__pause "$_psx_label"' EXIT
}
_psx_prompt() {
  if [ -r /dev/tty ]; then
    printf "PSX — Appuie sur Entrée pour fermer cette fenêtre…" > /dev/tty
    IFS= read -r _ < /dev/tty
    printf "\n" > /dev/tty
  elif [ -t 0 ]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
    echo
  else
    echo "PSX — Aucun TTY détecté; la fenêtre restera ouverte (Ctrl+C pour fermer)."
    tail -f /dev/null
  fi
}
psx__pause() {
  rc=$?
  echo
  if [ "$rc" -eq 0 ]; then
    echo "✅ ${_psx_label:-Run} — OK (exit: $rc)"
  else
    echo "❌ ${_psx_label:-Run} — KO (exit: $rc)"
  fi
  if [ "${WAIT_ON_EXIT}" = "1" ] && [ -z "${CI:-}" ]; then
    _psx_prompt
  fi
  return $rc
}
