#!/bin/sh
# Re-enables ALL disabled packages and resets animations and private DNS.
# Usage: sh scripts/undo.sh <STICK_IP>
set -u
[ -n "${1:-}" ] || { echo "Usage: sh undo.sh <STICK_IP>" >&2; exit 1; }
TV="$1:5555"
adb connect "$TV" >/dev/null
[ "$(adb -s "$TV" get-state 2>/dev/null)" = device ] || { echo "No access to $TV" >&2; exit 1; }
for p in $(adb -s "$TV" shell pm list packages -d | tr -d '\r' | sed 's/package://'); do
  adb -s "$TV" shell pm enable "$p" >/dev/null && echo "enabled: $p"
done
adb -s "$TV" shell settings put global window_animation_scale 1.0
adb -s "$TV" shell settings put global transition_animation_scale 1.0
adb -s "$TV" shell settings delete global animator_duration_scale
adb -s "$TV" shell settings delete global private_dns_specifier
adb -s "$TV" shell settings put global private_dns_mode opportunistic
echo "Done. Reboot the stick now."
