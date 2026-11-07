# TV Amazon Firestick DeTox

Alte Fire TV Sticks (und die Technik drumherum) länger nutzbar machen, statt sie wegzuwerfen: Hintergrunddienste, Werbekacheln und Telemetrie per ADB **deaktivieren** (nie löschen), mit Never-Liste, Undo-Protokoll und ehrlicher Messung.

*English:* A careful, reversible ADB debloat workflow for Amazon Fire TV Sticks (Fire OS 8 / Android 11), packaged as a reusable Claude Code skill plus plain POSIX shell scripts. Only `pm disable-user`, never uninstall.

## Warum
Weniger Elektroschrott: Ein 1,7-GB-Stick läuft nach der Bereinigung spürbar angenehmer, ohne dass Alexa-Sprachsuche, Bluetooth, HDMI-CEC oder Einstellungen kaputtgehen.

## Inhalt
| Pfad | Zweck |
|---|---|
| `skill/firestick-detox/SKILL.md` | Claude-Code-Skill mit Regeln und Ablauf |
| `scripts/01_analyse.sh` | Nur lesen: RAM, Dienste, Netzwerk, Pakete, Einstellungen |
| `scripts/02_detox.sh` | Trockenlauf/Anwenden aus einer Paketliste, mit Never-Liste und Undo-Protokoll |
| `scripts/undo.sh` | Alles wieder aktivieren, Animationen und DNS zurücksetzen |
| `lists/` | `never.txt`, `disable_stage1.txt`, `caution.txt` (Erfahrungen, was Probleme machte) |
| `docs/LESSONS_LEARNED.md` | Ehrlicher Bericht inkl. Fehlschlägen |
| `docs/sony-bravia-tips.md` | Tipps für alte Nicht-Android-TVs |

## Schnellstart
```sh
# 1. Fire TV: Entwickleroptionen > ADB-Debugging AN (7x auf Gerätename tippen), IP notieren
sh scripts/01_analyse.sh 192.168.1.50            # nur lesen, Vorher-Stand sichern
sh scripts/02_detox.sh   192.168.1.50 lists/disable_stage1.txt            # Trockenlauf
sh scripts/02_detox.sh   192.168.1.50 lists/disable_stage1.txt --apply    # anwenden
# Neustart, Sprachsuche + Apps testen. Rückgängig:
sh scripts/undo.sh 192.168.1.50
```
Als Claude-Code-Skill: `skill/firestick-detox/` nach `~/.claude/skills/` kopieren.

## Sicherheit
- Nur `pm disable-user --user 0`, nie `pm uninstall`.
- Nach der Bereinigung **ADB-Debugging und "Apps aus unbekannten Quellen" wieder ausschalten**.
- Auf eigene Gefahr; Listen sind auf **AFTKRT / Fire OS 8.1.8.5** getestet, andere Geräte können abweichen.

## Ergebnis (ehrlich)
Subjektiv flüssiger (YouTube), Sprachsuche/Prime/Music laufen. **Der freie RAM im Leerlauf änderte sich kaum** (ca. 435 MB vorher, 412 MB nachher). Details und Stolpersteine: `docs/LESSONS_LEARNED.md`.

## Lizenz
Apache License 2.0, siehe `LICENSE`.
