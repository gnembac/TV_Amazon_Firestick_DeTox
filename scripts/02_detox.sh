#!/bin/sh
# SCHRITT 2: Deaktiviert Pakete aus einer Liste (pm disable-user - KEIN Löschen!), Animationen aus, Standby 5 Min.
# Aufruf: sh scripts/02_detox.sh <STICK_IP> <LISTE> [--apply]     (ohne --apply: nur Trockenlauf)
# Beispiel: sh scripts/02_detox.sh 192.168.1.50 lists/disable_stage1.txt --apply
# Wichtig: Immer erst Trockenlauf. Nach dem Anwenden neu starten und Sprachsuche, Prime, YouTube, Music testen.
set -u
[ -n "${2:-}" ] || { echo "Usage: sh 02_detox.sh <STICK_IP> <LISTE> [--apply]" >&2; exit 1; }
TV="$1:5555"; LIST="$2"; APPLY="${3:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"; NEVERF="$HERE/../lists/never.txt"
[ -f "$LIST" ] || { echo "Liste fehlt: $LIST" >&2; exit 1; }
adb connect "$TV" >/dev/null
[ "$(adb -s "$TV" get-state 2>/dev/null)" = device ] || { echo "Kein Zugriff auf $TV" >&2; exit 1; }
LOG="geaendert_$(date +%Y%m%d_%H%M%S).md"

NEVER=$(grep -vE '^\s*(#|$)' "$NEVERF")
INSTALLED=$(adb -s "$TV" shell pm list packages | tr -d '\r' | sed 's/package://')
PERSIST=$(adb -s "$TV" shell 'for p in $(pm list packages | sed s/package://); do dumpsys package $p | grep -m1 pkgFlags | grep -q PERSISTENT && echo $p; done' | tr -d '\r')

echo "# Geänderte Pakete - Rückgängig: adb -s $TV shell pm enable <paket>" > "$LOG"
for p in $(grep -vE '^\s*(#|$)' "$LIST"); do
  echo "$INSTALLED" | grep -Fxq "$p" || { echo "- $p nicht installiert, übersprungen"; continue; }
  skip=
  for n in $NEVER; do case "$p" in *"$n"*) skip=1;; esac; done
  [ -n "$skip" ] && { echo "- $p auf Never-Liste, übersprungen"; continue; }
  echo "$PERSIST" | grep -Fxq "$p" && { echo "- $p ist PERSISTENT, übersprungen"; continue; }
  if [ "$APPLY" = "--apply" ]; then
    if out=$(adb -s "$TV" shell pm disable-user --user 0 "$p" 2>&1) && ! echo "$out" | grep -qi "exception"; then
      echo "$p | adb -s $TV shell pm enable $p" >> "$LOG"; echo "deaktiviert: $p"
    else
      echo "- $p: nicht möglich (geschützt?), übersprungen"; echo "# $p übersprungen (geschützt)" >> "$LOG"
    fi
  else
    echo "[Trockenlauf] würde deaktivieren: $p"
  fi
done

if [ "$APPLY" = "--apply" ]; then
  {
    echo "# Einstellungen vorher (zum Zurücksetzen):"
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do
      v=$(adb -s "$TV" shell settings get global $k | tr -d '\r')
      if [ "$v" = null ]; then echo "settings delete global $k"; else echo "settings put global $k $v"; fi
    done
    echo "settings put system screen_off_timeout $(adb -s "$TV" shell settings get system screen_off_timeout | tr -d '\r')"
  } >> "$LOG"
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do
    adb -s "$TV" shell settings put global $k 0
  done
  adb -s "$TV" shell settings put system screen_off_timeout 300000   # 5 Min
  echo "Protokoll: $LOG  -> jetzt neu starten und testen (Sprachsuche, Prime, YouTube, Music)."
fi
