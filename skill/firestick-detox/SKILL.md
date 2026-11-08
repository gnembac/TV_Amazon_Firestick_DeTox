---
name: firestick-detox
description: Analyse and slim down an Amazon Fire TV Stick over ADB using only pm disable-user (nothing is deleted), with a never-list, an undo log and before/after measurement. Use when a Fire TV Stick is slow or crashing, shows ad tiles or vendor telemetry, or when the user mentions Fire TV debloat, making a Firestick faster, Fire OS background services or cleaning up over ADB.
---

# Fire TV Stick Detox (Fire OS, ADB)

Goal: keep an old Fire TV Stick (for example 0.9-1.7 GB RAM) usable for longer without breaking Alexa voice search, Bluetooth,
HDMI-CEC or Settings. Everything is reversible.

## Non-negotiable rules
1. **Disable only**: `pm disable-user --user 0 <package>`. Never suggest `pm uninstall`, `pm clear` or a factory reset.
2. **Measure first, then change.** Save "before" values: `/proc/meminfo`, `top`, `dumpsys meminfo`, `pm list packages`, and app start times (`am start -W`).
3. **Explain the risk before the first change** and get confirmation that packages are only disabled.
4. **Never-list** (`lists/never.txt`): System UI, Settings, keyboard, Bluetooth, Alexa/voice search, HDMI/CEC, launcher, OTA, core services.
5. **Work in small stages** (about 10 packages). Reboot and test after each stage: voice search, and every app the user actually uses.
6. **Log every change** with its undo command (`pm enable <package>`).
7. **Ask before external or network-level changes**, for example Private DNS (see below).
8. At the end tell the user to turn **ADB debugging and "Apps from unknown sources" OFF** again.
9. Report results honestly. On 1.7 GB devices free RAM at idle barely changes; the gain is often only perceived.

## Procedure
1. **Connect**: Developer options (click the device name 7 times), ADB debugging ON, `adb connect <IP>:5555`, accept the dialog on the TV.
   Fire OS often closes the ADB port after reboot or under load. Toggle ADB OFF/ON and run commands in one batch.
2. **Analyse** (read-only): `scripts/01_analyse.sh <IP> [out_dir]`.
3. **Check candidates**: compare `lists/disable_stage1.txt` with the installed packages. User-facing apps (Netflix, media libraries) only if unused.
4. **Apply**: `scripts/02_detox.sh <IP> lists/disable_stage1.txt` (dry run), then add `--apply`.
5. **Reboot and test.** If something breaks, re-enable the most recently changed packages first, then consult `lists/caution.txt`.
6. **Settings**: animations to 0 (`window_animation_scale`, `transition_animation_scale`, `animator_duration_scale`), `screen_off_timeout 300000` (5 minutes).
7. **Measure after** and compare with the saved "before" values.
8. **Deliver** the change log with undo commands (`scripts/undo.sh` re-enables everything).

## Checks added after the second device (AFTSS, Fire OS 7.7.1.7)
- **Identify the target first** (`ro.product.model`, `ro.serialno`, `ro.build.display.id`, storage) and compare with what the user said:
  people often own several sticks. If `adb` says `unauthorized`, ask the user to accept "Always allow" on the TV.
- **Look up the real package names** before claiming an app is missing: Prime Video = `com.amazon.firebat`,
  Amazon Music = `com.amazon.bueller.music`, YouTube = `com.amazon.firetv.youtube` (all on the never-list).
- **Two stages** (A: ads/promo/dummy, B: telemetry), reboot after each, then run
  `scripts/03_verify.sh <IP> <list> <pkg/activity>`. Disabled packages can silently be enabled again after the first reboot.
- **Measure comparably**: same conditions (cold boot + 5-8 min) before and after, start times via `am start -W`.
- Verified lists: `lists/disable_stage1.txt` (AFTKRT, Fire OS 8.1.8.5) and `lists/disable_aftss_fireos7.txt` (AFTSS, Fire OS 7.7.1.7).
- On Windows Git Bash scripts need `MSYS_NO_PATHCONV=1` (already set).
- Modern webOS/Android TVs: no ADB cleanup, see `docs/lg-oled-tips.md`; old Sony: `docs/sony-bravia-tips.md`.

## Known pitfalls
- `Cannot disable a protected package` is normal on Fire OS. Skip and note it.
- Fire OS may re-enable some packages itself after a reboot.
- PERSISTENT packages cannot be disabled stably.
- Voice search hangs (blue bar, no answer): first re-enable smarthome/device-control packages, then the telemetry group in `lists/disable_stage1.txt`.
- Private DNS in `hostname` mode (for example AdGuard) can break name resolution after a cold boot. Test after a cold boot before keeping it. Reset with
  `settings delete global private_dns_specifier; settings put global private_dns_mode opportunistic`.
- `ping` from the stick is often blocked; test reachability with `echo | timeout 5 nc -w 4 <host> 443`.
- If the stick uses Ethernet, `dumpsys wifi` showing "disconnected" is irrelevant.

More detail: `docs/LESSONS_LEARNED.md`.
