#!/bin/sh
# SCHRITT 1: NUR LESEN - verändert nichts am Fire TV Stick.
# Aufruf: sh scripts/01_analyse.sh <STICK_IP> [AUSGABEORDNER]
# Voraussetzung: Entwickleroptionen > ADB-Debugging = AN
set -u
[ -n "${1:-}" ] || { echo "Usage: sh 01_analyse.sh <STICK_IP> [OUT_DIR]" >&2; exit 1; }
TV="$1:5555"
OUT="${2:-analyse_$(date +%Y%m%d_%H%M%S)}"
adb connect "$TV" >/dev/null
[ "$(adb -s "$TV" get-state 2>/dev/null)" = device ] || { echo "Kein Zugriff auf $TV (Dialog am TV bestätigen? ADB kurz AUS/AN?)" >&2; exit 1; }
mkdir -p "$OUT"
sh_() { adb -s "$TV" shell "$@" | tr -d '\r'; }

{ sh_ getprop ro.product.model; sh_ getprop ro.build.version.release; sh_ getprop ro.build.version.sdk; } > "$OUT/modell.txt"
sh_ cat /proc/meminfo                       > "$OUT/ram_meminfo.txt"
sh_ dumpsys meminfo                         > "$OUT/ram_dumpsys_meminfo.txt"
sh_ top -b -n 1 -m 25                       > "$OUT/cpu_top.txt"
sh_ df -h /data                             > "$OUT/speicher.txt"
sh_ dumpsys activity services               > "$OUT/laufende_dienste.txt"
sh_ dumpsys netstats                        > "$OUT/netzwerk_netstats.txt"
sh_ dumpsys connectivity                    > "$OUT/netzwerk_connectivity.txt"
sh_ pm list packages -f                     > "$OUT/pakete_alle.txt"
sh_ pm list packages -3                     > "$OUT/pakete_nutzer.txt"
sh_ pm list packages -d                     > "$OUT/pakete_bereits_deaktiviert.txt"
{ for k in window_animation_scale transition_animation_scale animator_duration_scale; do
    echo "global $k=$(sh_ settings get global $k)"; done
  echo "system screen_off_timeout=$(sh_ settings get system screen_off_timeout)"
  echo "global private_dns_mode=$(sh_ settings get global private_dns_mode)"
  echo "global private_dns_specifier=$(sh_ settings get global private_dns_specifier)"; } > "$OUT/vorher_einstellungen.txt"
# Referenz fuer spaeter: Kaltstartzeiten (3 Laeufe) ausfuehren Sie bei Bedarf von Hand:
#   adb shell am force-stop <pkg>; adb shell am start -W -n <pkg>/<activity>   (TotalTime in ms)
# PERSISTENT-Pakete (lassen sich nicht stabil deaktivieren)
for p in $(sh_ pm list packages | sed 's/package://'); do
  sh_ dumpsys package "$p" | grep -m1 pkgFlags | grep -q PERSISTENT && echo "$p"
done > "$OUT/pakete_persistent.txt"
echo "Fertig. Ergebnisse in $OUT/"
