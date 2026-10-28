#!/usr/bin/env bash
# Réactive les paquets désactivés par disable.sh (state/disabled.txt), ou ceux d'une liste donnée.
#
# Usage : TV_HOST=192.168.1.50 ./restore.sh              # tout ce que disable.sh a désactivé
#         TV_HOST=192.168.1.50 ./restore.sh debloat.txt  # toute la liste
#         TV_HOST=192.168.1.50 ./restore.sh "" com.google.android.apps.tv.launcherx  # + paquets en plus
set -euo pipefail
cd "$(dirname "$0")"
LIST="${1:-state/disabled.txt}"
[ -n "$LIST" ] || LIST=state/disabled.txt
shift || true
command -v adb >/dev/null || { echo "adb introuvable : installez Android platform-tools." >&2; exit 1; }
if [ -n "${TV_HOST:-}" ]; then
  adb connect "$TV_HOST:${TV_PORT:-5555}" >/dev/null
  export ANDROID_SERIAL="$TV_HOST:${TV_PORT:-5555}"
fi
PKGS="$( { [ -f "$LIST" ] && sed -e 's/#.*//' -e 's/[[:space:]]//g' "$LIST"; printf '%s\n' "$@"; } | grep -v '^$' || true)"
[ -n "$PKGS" ] || { echo "Rien à restaurer ($LIST introuvable ou vide)." >&2; exit 1; }
for p in $PKGS; do
  [[ "$p" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$ ]] || { echo "Nom invalide : $p" >&2; continue; }
  out=$(adb shell pm enable --user 0 "$p" 2>&1 | tr -d '\r')
  echo "$p : $out"
done
echo "Terminé. Redémarrez : adb reboot"
