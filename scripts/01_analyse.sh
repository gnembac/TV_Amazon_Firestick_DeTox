#!/bin/sh
# STEP 1: READ ONLY - changes nothing on the Fire TV Stick.
# Usage: sh scripts/01_analyse.sh <STICK_IP> [OUTPUT_DIR]
# Prerequisite: Developer options > ADB debugging = ON, authorization dialog accepted on the TV.
export MSYS_NO_PATHCONV=1   # Git Bash on Windows would rewrite /data into C:/Program Files/Git/data
set -u
[ -n "${1:-}" ] || { echo "Usage: sh 01_analyse.sh <STICK_IP> [OUT_DIR]" >&2; exit 1; }
TV="$1:5555"
OUT="${2:-analysis_$(date +%Y%m%d_%H%M%S)}"
adb connect "$TV" >/dev/null
[ "$(adb -s "$TV" get-state 2>/dev/null)" = device ] || {
  echo "No access to $TV (accept the dialog on the TV? toggle ADB debugging OFF/ON?)" >&2; exit 1; }
mkdir -p "$OUT"
sh_() { adb -s "$TV" shell "$@" | tr -d '\r'; }

{ sh_ getprop ro.product.model; sh_ getprop ro.build.version.release; sh_ getprop ro.build.version.sdk; } > "$OUT/model.txt"
sh_ cat /proc/meminfo                       > "$OUT/ram_meminfo.txt"
sh_ dumpsys meminfo                         > "$OUT/ram_dumpsys_meminfo.txt"
sh_ top -b -n 1 -m 25                       > "$OUT/cpu_top.txt"
sh_ df -h /data                             > "$OUT/storage.txt"
sh_ dumpsys activity services               > "$OUT/running_services.txt"
sh_ dumpsys netstats                        > "$OUT/network_netstats.txt"
sh_ dumpsys connectivity                    > "$OUT/network_connectivity.txt"
sh_ pm list packages -f                     > "$OUT/packages_all.txt"
sh_ pm list packages -3                     > "$OUT/packages_user.txt"
sh_ pm list packages -d                     > "$OUT/packages_already_disabled.txt"
{ for k in window_animation_scale transition_animation_scale animator_duration_scale; do
    echo "global $k=$(sh_ settings get global $k)"; done
  echo "system screen_off_timeout=$(sh_ settings get system screen_off_timeout)"
  echo "global private_dns_mode=$(sh_ settings get global private_dns_mode)"
  echo "global private_dns_specifier=$(sh_ settings get global private_dns_specifier)"; } > "$OUT/settings_before.txt"
# Tip: also record cold-start times by hand BEFORE changing anything (3 runs per app):
#   adb shell am force-stop <pkg>; adb shell am start -W -n <pkg>/<activity>      (TotalTime in ms)
# PERSISTENT packages cannot be disabled stably:
for p in $(sh_ pm list packages | sed 's/package://'); do
  sh_ dumpsys package "$p" | grep -m1 pkgFlags | grep -q PERSISTENT && echo "$p"
done > "$OUT/packages_persistent.txt"
echo "Done. Results in $OUT/"
