#!/usr/bin/env bash
set -euo pipefail
start=${1:-68}; end=${2:-80}
echo "— Contexte Makefile lignes $start..$end (affichage ^I pour tab, $ pour fin) —"
nl -ba -w3 -s': ' Makefile | sed -n "${start},${end}p" | sed -e 's/\t/^I/g' -e 's/$/$/'
