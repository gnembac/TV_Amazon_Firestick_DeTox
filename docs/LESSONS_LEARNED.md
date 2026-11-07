# Lessons Learned (Fire TV Stick AFTKRT, 1,7 GB RAM, Fire OS 8.1.8.5 / Android 11)

Ehrlicher Erfahrungsbericht aus einem echten Durchlauf. Ergebnisse gelten für dieses Gerät und können abweichen.

## Ergebnis
- 23 Pakete (Stufe 1) + 9 Pakete (Stufe 3) deaktiviert, nichts gelöscht. Animationen aus, Standby 5 Minuten.
- Subjektiv: YouTube läuft flüssiger, Sprachsuche, Prime Video und Amazon Music funktionieren.
- **Messbar nicht besser**: freier RAM im Leerlauf (MemAvailable) vorher ca. 435 MB, nachher ca. 412 MB.
  Den meisten Speicher belegen Launcher (~180 MB), `system_server` und die Alexa-Dienste, und die lassen sich nicht abschalten.
- Kaltstartzeiten nachher (Aktivität, `am start -W`): YouTube ca. 0,4 s, Prime ca. 0,6-0,8 s. Einen Vorher-Wert habe ich nicht erfasst.
  **Tipp: Startzeiten VOR den Änderungen messen**, sonst fehlt der Beleg.

## Was nicht funktionierte / Stolpersteine
1. **Sprachsuche hing** (blauer Balken, keine Alexa-Antwort) nach Deaktivierung von Smarthome-/Device-Control-/Kids-Paketen.
   Nach Reaktivierung wieder OK. Ursache nicht sicher belegt. Siehe `lists/caution.txt`.
2. **Fire OS aktiviert Pakete selbst wieder** (fünf Pakete aus Stufe 2 waren nach dem Neustart wieder an).
3. **Geschützte Pakete** (`Cannot disable a protected package`) lassen sich nicht abschalten. Einfach überspringen.
4. **ADB-Port 5555 wird unzuverlässig**: nach Neustart oder bei Last kam `connection refused (10061)` oder `device offline`.
   Abhilfe: ADB-Debugging AUS/AN, dann alle Befehle in einem Rutsch ausführen, kein langes Hin und Her.
   Der Stick meldete sich trotzdem per mDNS als `_adb._tcp`, der TCP-Port war aber zu.
5. **Private DNS (AdGuard) im Modus `hostname`**: Nach einem Kaltstart war Alexa nicht erreichbar und YouTube startete sehr langsam.
   Der strikte Modus bricht die Namensauflösung ab, wenn der DoT-Server (Port 853) nicht erreichbar ist. Ich habe auf Standard zurückgestellt.
   Ob das DNS die Ursache war oder nur das Netzwerk nach dem Boot noch unruhig war, blieb offen. **Nicht ohne Test nach Kaltstart aktivieren.**
6. **`ping` vom Stick ist unzuverlässig** (ICMP oft blockiert). Besser: `echo | timeout 5 nc -w 4 <host> 443`.
7. Der Stick hing per **Ethernet**; `dumpsys wifi` zeigte "DISCONNECTED" und war irrelevant. Aktives Netz mit `dumpsys connectivity` prüfen.
8. `ip route` zeigt auf Android nur die Haupttabelle; Default-Routen stehen in `ip route show table all`.

## Vorgehen, das sich bewährt hat
- Erst Analyse (nur lesen), dann Trockenlauf, dann in kleinen Stufen anwenden.
- Nach jeder Stufe Neustart und Test der drei genutzten Apps plus Sprachsuche.
- Jedes Paket mit Undo-Befehl protokollieren. Rückbau gezielt für Verdachtsgruppen (Telemetrie, Smarthome).
- Am Ende ADB-Debugging und "Apps aus unbekannten Quellen" wieder ausschalten.

## Nicht erreichbar / ehrliche Grenzen
- Alte Sony-Bravia-TVs (z. B. KDL-40NX705, 2010) laufen nicht auf Android. Kein ADB, keine Paketbereinigung. Siehe `sony-bravia-tips.md`.
- Mehr RAM geht nicht. Regelmäßiger Neustart und freier Speicher helfen mehr als weitere Deaktivierungen.
