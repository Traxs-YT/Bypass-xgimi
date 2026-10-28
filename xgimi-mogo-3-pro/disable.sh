#!/usr/bin/env bash
# Désactive (pm disable-user --user 0) chaque paquet listé dans un fichier debloat, après confirmation.
# Rien n'est désinstallé. Chaque paquet réellement désactivé est noté dans state/disabled.txt pour restore.sh.
#
# Usage : TV_HOST=192.168.1.50 ./disable.sh debloat.txt   (DRY_RUN=1 pour seulement afficher)
set -euo pipefail
LIST="${1:?usage: disable.sh <liste debloat>}"
cd "$(dirname "$0")"
command -v adb >/dev/null || { echo "adb introuvable : installez Android platform-tools." >&2; exit 1; }

# Paquets indispensables au projecteur : refusés même s'ils apparaissent dans la liste.
PROTECTED="com.xgimi.autokst com.xgimi.windowsystem com.xgimi.tof com.xgimi.misckey
com.xgimi.uiconfiguration com.xgimi.xrmservice com.xgimi.xgimiservice com.xgimi.autoinstall
com.xgimi.overseas.xgimiatvbootwizard com.mediatek.tvinput com.mediatek.tv.service
com.google.android.tv.inputplayer com.nbcast.wirelessscreen"

PKGS=$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$LIST" | grep -v '^$' || true)
[ -n "$PKGS" ] || { echo "Liste vide : $LIST" >&2; exit 1; }
for p in $PKGS; do
  [[ "$p" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$ ]] || { echo "Nom de paquet invalide : $p" >&2; exit 1; }
  for k in $PROTECTED; do
    [ "$p" = "$k" ] && { echo "Refusé : $p est indispensable au projecteur (keystone/focus/HDMI/mirroring)." >&2; exit 1; }
  done
done

if [ -n "${TV_HOST:-}" ]; then
  adb connect "$TV_HOST:${TV_PORT:-5555}" >/dev/null
  export ANDROID_SERIAL="$TV_HOST:${TV_PORT:-5555}"
fi
MODEL=$(adb shell getprop ro.product.device | tr -d '\r')
SDK=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
echo "Appareil : $MODEL (SDK $SDK)"
if [ "$MODEL" != "altai" ] && [ -z "${FORCE_MODEL:-}" ]; then
  echo "Cette liste a été testée sur la MoGo 3 Pro (device altai), pas sur '$MODEL'." >&2
  echo "Relancez avec FORCE_MODEL=1 si vous savez ce que vous faites." >&2
  exit 1
fi

INSTALLED=$(adb shell pm list packages | tr -d '\r' | sed 's/^package://')
ENABLED=$(adb shell pm list packages -e | tr -d '\r' | sed 's/^package://')
TODO=()
echo
for p in $PKGS; do
  if ! grep -qx "$p" <<<"$INSTALLED"; then echo "  absent         $p"
  elif ! grep -qx "$p" <<<"$ENABLED"; then echo "  déjà désactivé $p"
  else echo "  À DÉSACTIVER   $p"; TODO+=("$p"); fi
done
echo
[ ${#TODO[@]} -gt 0 ] || { echo "Rien à faire."; exit 0; }
[ -n "${DRY_RUN:-}" ] && { echo "DRY_RUN : aucune modification."; exit 0; }
read -r -p "Désactiver ces ${#TODO[@]} paquets ? [o/N] " ok
[[ "$ok" =~ ^[oOyY]$ ]] || { echo "Annulé."; exit 0; }

mkdir -p state
for p in "${TODO[@]}"; do
  out=$(adb shell pm disable-user --user 0 "$p" 2>&1 | tr -d '\r')
  if grep -q "disabled-user" <<<"$out"; then
    echo "OK    $p"
    grep -qx "$p" state/disabled.txt 2>/dev/null || echo "$p" >> state/disabled.txt
  else
    echo "ÉCHEC $p : $out"
  fi
done
echo
echo "Terminé. Redémarrez (adb reboot) puis vérifiez keystone, autofocus, HDMI, USB et la télécommande."
echo "Annuler : ./restore.sh"
