# File: repo_step1b_echo_missing_and_candidates.sh
# Path: ~/MCGT/repo_step1b_echo_missing_and_candidates.sh
#!/usr/bin/env bash
set -uo pipefail
set +e

# -- Garde-fou anti-fermeture de fenêtre --
cleanup() { echo; read -rp "[PAUSE] Entrée pour quitter... " _; }
trap cleanup EXIT

# Utilitaires
latest_dir() { ls -1dt "/tmp/$1"_* 2>/dev/null | head -n1; }

C="$(latest_dir mcgt_deepC)"
D="$(latest_dir mcgt_deepD)"
T="$(latest_dir mcgt_triage_step1)"

echo "=== CONTEXT ==="
echo "DeepC: ${C:-<not found>}"
echo "DeepD: ${D:-<not found>}"
echo "Triage: ${T:-<not found>}"
echo

out="/tmp/mcgt_echo_step1_$(date -u +%Y%m%dT%H%M%S)"
mkdir -p "$out"

mscan="$C/manifest_scan.tsv"
unref="$C/unreferenced.tsv"

echo "=== 1) MISSING (à partir de manifest_scan.tsv) ==="
if [[ -f "$mscan" ]]; then
  # Figures PNG manquantes
  awk -F'\t' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next}
              $h["role"]=="figure" && $h["status"]=="missing" {print $h["path"]}' "$mscan" \
    | sort | tee "$out/missing_figures_png.txt"

  # requirements.txt manquants
  awk -F'\t' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next}
              $h["status"]=="missing" && $h["path"] ~ /\/requirements\.txt$/ {print $h["path"]}' "$mscan" \
    | sort | tee "$out/missing_requirements.txt"

  # *.lock.json manquants (config)
  awk -F'\t' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next}
              $h["status"]=="missing" && $h["path"] ~ /\.lock\.json$/ {print $h["path"]}' "$mscan" \
    | sort | tee "$out/missing_lockjson.txt"

  # Autres "missing"
  awk -F'\t' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next}
              $h["status"]=="missing" && $h["path"] !~ /\/requirements\.txt$/ && $h["path"] !~ /\.lock\.json$/ && $h["role"]!="figure" \
              {print $h["path"]}' "$mscan" | sort | tee "$out/missing_other.txt"

  echo
  echo "--- Comptes ---" | tee "$out/missing_counts.txt"
  for f in figures_png requirements lockjson other; do
    c=$(wc -l < "$out/missing_${f}.txt" 2>/dev/null || echo 0)
    printf "%-24s %4d\n" "missing_${f}" "$c" | tee -a "$out/missing_counts.txt"
  done
else
  echo "Fichier introuvable: $mscan"
fi
echo

echo "=== 2) UNREFERENCED (groupé par top-level) ==="
if [[ -f "$unref" ]]; then
  awk -F'\t' 'NR>1{split($1,a,"/"); top=a[1]; cnt[top]++} END{for(k in cnt) printf "%-16s %5d\n", k, cnt[k]}' "$unref" \
    | sort | tee "$out/unreferenced_by_top.txt"
  echo
  echo "--- Liste complète (premiers 300) ---"
  sed -n '1,300p' "$unref" | tee "$out/unreferenced_head300.tsv"
else
  echo "Fichier introuvable: $unref"
fi
echo

echo "=== 3) LISTES TRIAGE EXISTANTES (si présentes) ==="
if [[ -n "${T:-}" && -d "$T" ]]; then
  for f in missing_figures_png.txt add_candidates.txt drop_candidates.txt; do
    p="$T/$f"
    if [[ -f "$p" ]]; then
      echo "--- $p ---"
      wc -l "$p"
      sed -n '1,200p' "$p"
      echo
      cp -f "$p" "$out/"
    fi
  done
else
  echo "Répertoire triage introuvable."
fi
echo

echo "=== 4) DUPLICATIONS CSV vs CSV.GZ (diagnostic) ==="
if [[ -f "$D/data_inventory.tsv" ]]; then
  awk -F'\t' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next}
              $h["path"] ~ /\.csv(\.gz)?$/ {base=$h["path"]; gsub(/\.gz$/,"",base); seen[base]++; lines[base]=lines[base] $h["path"] "\n"}
              END{for(b in seen) if(seen[b]>1){printf ">> %s\n%s\n", b, lines[b]}}' "$D/data_inventory.tsv" \
    | tee "$out/csv_vs_gz_pairs.txt"
else
  echo "Fichier introuvable: $D/data_inventory.tsv"
fi
echo

echo "=== 5) TODO (proposition) ===" | tee "$out/TODO_NEXT.md"
cat >> "$out/TODO_NEXT.md" <<'EOF'
- [ ] Verrouiller politiques: *.lock.json = EXCLUS ; *.csv.gz = assets release (ou IGNORE)
- [ ] Ajouter _common/*.py au manifeste (ADD)
- [ ] Régénérer 7 PNG manquants (chap09–10), puis rescanner hashes
- [ ] Générer requirements.txt (candidats) par chapitre
- [ ] Nettoyer unreferenced: DROP .broken.*, décider pour scripts CI/outils
- [ ] Re-générer manifest_publication.json + SHA256SUMS_publication.txt
EOF
echo "Écrit: $out/TODO_NEXT.md"
