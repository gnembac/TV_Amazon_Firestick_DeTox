#!/bin/sh
# STEP 3: READ ONLY - verify after a reboot that the packages of a list are still disabled and time your apps.
# Usage: sh scripts/03_verify.sh <STICK_IP> <LIST> [pkg/activity ...]
# Example: sh scripts/03_verify.sh 192.168.1.50 lists/disable_aftss_fireos7.txt \
#   com.amazon.firetv.youtube/dev.cobalt.app.MainActivity com.amazon.firebat/com.amazon.pyrocore.IgnitionActivity
# Wait 5-8 minutes after a cold boot before timing apps, otherwise the numbers are too high.
export MSYS_NO_PATHCONV=1
set -u
[ -n "${2:-}" ] || { echo "Usage: sh 03_verify.sh <STICK_IP> <LIST> [pkg/activity ...]" >&2; exit 1; }
TV="$1:5555"; LIST="$2"; shift 2
adb connect "$TV" >/dev/null
[ "$(adb -s "$TV" get-state 2>/dev/null)" = device ] || { echo "No access to $TV" >&2; exit 1; }
DIS=$(adb -s "$TV" shell pm list packages -d | tr -d '\r' | sed 's/package://')
INST=$(adb -s "$TV" shell pm list packages | tr -d '\r' | sed 's/package://')
for p in $(grep -vE '^\s*(#|$)' "$LIST"); do
  echo "$INST" | grep -Fxq "$p" || continue
  echo "$DIS" | grep -Fxq "$p" && echo "OK    still disabled: $p" || echo "BACK  re-enabled by Fire OS: $p"
done
adb -s "$TV" shell grep -E 'MemAvailable|SwapFree' /proc/meminfo | tr -d '\r'
for a in "$@"; do
  pk=${a%%/*}
  for i in 1 2 3; do
    adb -s "$TV" shell am force-stop "$pk"; sleep 3
    echo "$pk: $(adb -s "$TV" shell am start -W -n "$a" | tr -d '\r' | grep TotalTime)"; sleep 5
  done
  adb -s "$TV" shell am force-stop "$pk"
done
adb -s "$TV" shell input keyevent KEYCODE_HOME
echo "Crashes since boot: $(adb -s "$TV" logcat -d -b crash 2>/dev/null | grep -c 'FATAL EXCEPTION')"
