#!/bin/sh
# Aktiviert ALLE deaktivierten Pakete wieder und setzt Animationen/Private DNS zurück.
# Aufruf: sh scripts/undo.sh <STICK_IP>
set -u
[ -n "${1:-}" ] || { echo "Usage: sh undo.sh <STICK_IP>" >&2; exit 1; }
TV="$1:5555"
adb connect "$TV" >/dev/null
[ "$(adb -s "$TV" get-state 2>/dev/null)" = device ] || { echo "Kein Zugriff auf $TV" >&2; exit 1; }
for p in $(adb -s "$TV" shell pm list packages -d | tr -d '\r' | sed 's/package://'); do
  adb -s "$TV" shell pm enable "$p" >/dev/null && echo "aktiviert: $p"
done
adb -s "$TV" shell settings put global window_animation_scale 1.0
adb -s "$TV" shell settings put global transition_animation_scale 1.0
adb -s "$TV" shell settings delete global animator_duration_scale
adb -s "$TV" shell settings delete global private_dns_specifier
adb -s "$TV" shell settings put global private_dns_mode opportunistic
echo "Fertig. Danach neu starten."
