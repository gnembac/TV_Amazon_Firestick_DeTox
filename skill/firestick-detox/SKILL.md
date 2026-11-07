---
name: firestick-detox
description: Analysiert und entschlackt einen Amazon Fire TV Stick per ADB (nur pm disable-user, nichts wird gelöscht) mit Never-Liste, Undo-Protokoll und Messung vorher/nachher. Verwenden, wenn ein Fire TV Stick langsam ist, abstürzt, Werbekacheln/Tracking-Dienste hat oder wenn "Fire TV debloat", "Firestick schneller machen", "Fire OS Hintergrunddienste" oder ADB-Aufräumen genannt wird.
---

# Fire TV Stick Detox (Fire OS, ADB)

Ziel: Einen alten Fire TV Stick (z. B. 1,7 GB RAM) länger nutzbar machen, ohne Alexa, Bluetooth, HDMI-CEC
oder die Einstellungen zu beschädigen. Alles ist reversibel.

## Grundregeln (nicht verhandeln)
1. **Nur deaktivieren**: `pm disable-user --user 0 <paket>`. Niemals `pm uninstall`, `pm clear` oder Werksreset vorschlagen.
2. **Erst messen, dann ändern.** Vorher-Werte speichern: `/proc/meminfo`, `top`, `dumpsys meminfo`, `pm list packages`, Startzeiten (`am start -W`).
3. **Risiko vor der ersten Änderung erklären** und bestätigen lassen, dass nur deaktiviert wird.
4. **Never-Liste** (siehe `lists/never.txt`): SystemUI, Einstellungen, Tastatur, Bluetooth, Alexa/Sprachsuche, HDMI/CEC, Launcher, OTA, Kernsysteme.
5. **In kleinen Stufen** arbeiten (ca. 10 Pakete), nach jeder Stufe Neustart und Funktionstest (Sprachsuche, Prime, YouTube, Music).
6. **Jede Änderung protokollieren** mit Undo-Befehl (`pm enable <paket>`).
7. **Externe Eingriffe nur mit Zustimmung**, z. B. Private DNS (siehe Lessons Learned).
8. Am Ende: ADB-Debugging und "Apps aus unbekannten Quellen" wieder ausschalten lassen.

## Ablauf
1. **Verbinden**: Entwickleroptionen (7x auf Gerätename tippen), ADB-Debugging AN, `adb connect <IP>:5555`, Dialog am TV bestätigen.
   Hinweis: Fire OS schließt den ADB-Port nach Neustart oder Last oft wieder. Kurz AUS/AN schalten und sofort alle Befehle in einem Rutsch ausführen.
2. **Analyse** (nur lesen): `scripts/01_analyse.sh <IP>`.
3. **Kandidaten prüfen**: `lists/disable_stage1.txt` gegen die installierte Paketliste abgleichen. Nutzer-Apps (Netflix, Mediatheken) nur bei Nichtnutzung.
4. **Anwenden**: `scripts/02_detox.sh <IP> lists/disable_stage1.txt` (Trockenlauf ohne `--apply`).
5. **Neustart und Test**. Bei Problemen zuerst die zuletzt geänderten Pakete zurückholen, dann `lists/caution.txt` beachten.
6. **Einstellungen**: Animationen 0 (`window_animation_scale`, `transition_animation_scale`, `animator_duration_scale`), `screen_off_timeout 300000`.
7. **Nachher messen** und ehrlich berichten. Auf 1,7-GB-Geräten ist der freie RAM im Leerlauf danach kaum anders; der Gewinn ist oft nur gefühlt.
8. **Protokoll** mit Undo-Liste ausgeben (`scripts/undo.sh`).

## Bekannte Fallen
- "Cannot disable a protected package": normal bei Fire OS, überspringen und notieren.
- Fire OS aktiviert manche Pakete nach Neustart selbst wieder.
- Persistente Pakete lassen sich nicht stabil deaktivieren.
- Sprachsuche hängt (blauer Balken): zuerst Smarthome-/Device-Control-Pakete und Telemetrie-Gruppe zurückholen.
- Private DNS im Modus `hostname` (z. B. AdGuard) kann nach Kaltstart die Namensauflösung blockieren. Auf Standard zurück: `settings delete global private_dns_specifier; settings put global private_dns_mode opportunistic`.
- `ping` vom Stick ist oft blockiert; Erreichbarkeit mit `nc -w 4 <host> 443` testen.

Mehr Details: `docs/LESSONS_LEARNED.md`.
