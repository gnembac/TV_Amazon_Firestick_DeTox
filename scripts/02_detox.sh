#!/bin/sh
# STEP 2: Disables packages from a list (pm disable-user - NEVER deletes), animations off, screen-off timeout 5 min.
# Usage:   sh scripts/02_detox.sh <STICK_IP> <LIST> [--apply]      (without --apply: dry run only)
# Example: sh scripts/02_detox.sh 192.168.1.50 lists/disable_stage1.txt --apply
# Always do a dry run first. After applying: reboot and test voice search and every app you use.
set -u
[ -n "${2:-}" ] || { echo "Usage: sh 02_detox.sh <STICK_IP> <LIST> [--apply]" >&2; exit 1; }
TV="$1:5555"; LIST="$2"; APPLY="${3:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"; NEVERF="$HERE/../lists/never.txt"
[ -f "$LIST" ] || { echo "List not found: $LIST" >&2; exit 1; }
adb connect "$TV" >/dev/null
[ "$(adb -s "$TV" get-state 2>/dev/null)" = device ] || { echo "No access to $TV" >&2; exit 1; }
LOG="changes_$(date +%Y%m%d_%H%M%S).md"

NEVER=$(grep -vE '^\s*(#|$)' "$NEVERF")
INSTALLED=$(adb -s "$TV" shell pm list packages | tr -d '\r' | sed 's/package://')
PERSIST=$(adb -s "$TV" shell 'for p in $(pm list packages | sed s/package://); do dumpsys package $p | grep -m1 pkgFlags | grep -q PERSISTENT && echo $p; done' | tr -d '\r')

echo "# Changed packages - undo with: adb -s $TV shell pm enable <package>" > "$LOG"
for p in $(grep -vE '^\s*(#|$)' "$LIST"); do
  echo "$INSTALLED" | grep -Fxq "$p" || { echo "- $p not installed, skipped"; continue; }
  skip=
  for n in $NEVER; do case "$p" in *"$n"*) skip=1;; esac; done
  [ -n "$skip" ] && { echo "- $p is on the never-list, skipped"; continue; }
  echo "$PERSIST" | grep -Fxq "$p" && { echo "- $p is PERSISTENT, skipped"; continue; }
  if [ "$APPLY" = "--apply" ]; then
    if out=$(adb -s "$TV" shell pm disable-user --user 0 "$p" 2>&1) && ! echo "$out" | grep -qi "exception"; then
      echo "$p | adb -s $TV shell pm enable $p" >> "$LOG"; echo "disabled: $p"
    else
      echo "- $p: not possible (protected?), skipped"; echo "# $p skipped (protected)" >> "$LOG"
    fi
  else
    echo "[dry run] would disable: $p"
  fi
done

if [ "$APPLY" = "--apply" ]; then
  {
    echo "# Settings before (to restore):"
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do
      v=$(adb -s "$TV" shell settings get global $k | tr -d '\r')
      if [ "$v" = null ]; then echo "settings delete global $k"; else echo "settings put global $k $v"; fi
    done
    echo "settings put system screen_off_timeout $(adb -s "$TV" shell settings get system screen_off_timeout | tr -d '\r')"
  } >> "$LOG"
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do
    adb -s "$TV" shell settings put global $k 0
  done
  adb -s "$TV" shell settings put system screen_off_timeout 300000   # 5 minutes
  echo "Log: $LOG  -> now reboot and test (voice search, Prime Video, Music, YouTube)."
fi
