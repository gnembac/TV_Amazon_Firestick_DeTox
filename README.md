# Fire TV Stick DeTox

A careful, **fully reversible** ADB workflow to make an old Amazon Fire TV Stick usable for longer instead of throwing it away.
It disables background services, ad/promo tiles and vendor telemetry with `pm disable-user` (**never uninstalls anything**),
protects voice search, Bluetooth, HDMI-CEC and Settings with a never-list, logs every change with its undo command,
and measures the result honestly.

It ships as plain POSIX shell scripts **and** as a reusable [Claude Code](https://claude.com/claude-code) skill.

> Motivation: sustainability. A 1.7 GB RAM stick that became "unusably slow" can be kept in service for years with a few safe changes,
> without rooting, sideloading launchers or touching the core system.

---

## Contents

- [Results (anonymized, honest)](#results-anonymized-honest)
- [Repository layout](#repository-layout)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Safety model](#safety-model)
- [Package lists explained](#package-lists-explained)
- [Measuring before/after](#measuring-beforeafter)
- [Optional: Private DNS (read the warning)](#optional-private-dns-read-the-warning)
- [Troubleshooting](#troubleshooting)
- [Use as a Claude Code skill](#use-as-a-claude-code-skill)
- [Old non-Android TVs](#old-non-android-tvs)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## Results (anonymized, honest)

Test device: **Fire TV Stick (AFTKRT), Fire OS 8.1.8.5 / Android 11, 1.7 GB RAM, ~13 GB storage**, connected via Ethernet.
Only three apps are used: Prime Video, Amazon Music, YouTube. No personal identifiers are published in this repository.

| Metric | Before | After |
|---|---|---|
| Free RAM at idle (`MemAvailable`) | ~435 MB | ~412 MB |
| Free swap | ~307 MB | ~283 MB |
| Running tasks | 317 | 312 |
| Packages disabled (never removed) | 0 | 23 (stage 1) + 9 (stage 3) |
| Animations (window/transition/animator) | 1.0 / 1.0 / unset | 0 / 0 / 0 |
| Screen-off timeout | 5 min | 5 min |
| YouTube cold start (`am start -W`, 3 runs) | not measured | 380-443 ms |
| Prime Video cold start (2 valid runs) | not measured | 602-798 ms |

**What this means, honestly:**

- Subjectively the stick feels smoother (YouTube in particular), and voice search, Prime Video and Amazon Music all work.
- **Free RAM at idle did not improve measurably.** Most memory is held by the launcher (~180 MB), `system_server` and the
  Alexa services, and those must not be disabled. Do not expect dramatic numbers on a 1.7 GB device.
- I did not record start-up times *before* the changes, so there is no measured before/after for responsiveness.
  **Measure start times first** (see below) if you want proof.

## Repository layout

| Path | Purpose |
|---|---|
| `skill/firestick-detox/SKILL.md` | Claude Code skill: rules and procedure |
| `scripts/01_analyse.sh` | Read-only analysis (RAM, services, network, packages, settings) |
| `scripts/02_detox.sh` | Dry-run or apply a package list, never-list protection, undo log |
| `scripts/undo.sh` | Re-enable everything, reset animations and private DNS |
| `lists/never.txt` | Packages that are never touched (substring match) |
| `lists/disable_stage1.txt` | Packages that were stable to disable on the test device |
| `lists/caution.txt` | Packages that caused trouble, were protected or were re-enabled by Fire OS |
| `docs/LESSONS_LEARNED.md` | Detailed field report including failures |
| `docs/sony-bravia-tips.md` | Tips for old non-Android TVs |

## Requirements

- Android platform-tools (`adb`) on your computer, and a POSIX shell (Linux, macOS, WSL, or Git Bash on Windows).
- Computer and Fire TV in the same network.
- On the Fire TV: *Settings > My Fire TV > About*, click the device name 7 times, then
  *Developer options > ADB debugging = ON*. Accept the authorization dialog on the TV ("Always allow").

## Quick start

```sh
# 0. Connect (replace with your stick's IP, shown under Settings > My Fire TV > About > Network)
adb connect 192.168.1.50:5555

# 1. Read-only analysis. Saves the "before" state (RAM, services, packages, settings).
sh scripts/01_analyse.sh 192.168.1.50 analysis_before

# 2. Dry run: shows what would be disabled. Nothing changes.
sh scripts/02_detox.sh 192.168.1.50 lists/disable_stage1.txt

# 3. Apply. Disables packages, sets animations to 0 and screen-off timeout to 5 min, writes an undo log.
sh scripts/02_detox.sh 192.168.1.50 lists/disable_stage1.txt --apply

# 4. Reboot the stick, then test: voice search (hold the remote's mic button), Prime Video, Music, YouTube.

# 5. Roll back everything if anything misbehaves:
sh scripts/undo.sh 192.168.1.50
```

Tips:

- **Work in small stages and reboot between them.** If something breaks, re-enable the most recent packages first.
- Fire OS closes the ADB TCP port after reboots or under load. If `adb connect` says *connection refused* or *device offline*,
  toggle ADB debugging OFF/ON on the stick and run all commands in one go.
- When you are done: **turn ADB debugging and "Apps from unknown sources" OFF again.**

## Safety model

1. **Disable only.** `pm disable-user --user 0 <package>`. No `pm uninstall`, no `pm clear`, no factory reset.
2. **Never-list.** `lists/never.txt` protects System UI, Settings, keyboard, Bluetooth, Alexa/voice search, HDMI/CEC, launcher,
   OTA and core services. Matching is by substring and is deliberately conservative.
3. **Protected and persistent packages are skipped.** Fire OS refuses some changes (`Cannot disable a protected package`);
   persistent packages cannot be disabled stably. The script detects both and moves on.
4. **Every change is logged** with its undo command (`pm enable <package>`).
5. **Measure before you change** and report results honestly.

## Package lists explained

- `lists/disable_stage1.txt` - ad/promo/shopping apps, tutorials, telemetry and usage-collection services, an ad-supported
  screensaver and empty "dummy" apps. Streaming/media apps in this list (Netflix, public-broadcaster apps) are only for people who do not use them.
- `lists/caution.txt` - packages **not** to disable blindly:
  - Smarthome/device-control and kids-related packages: after disabling them **voice search hung** (blue bar, no answer). Re-enabling fixed it.
    The causal link is likely but not proven.
  - Packages Fire OS re-enabled on its own after a reboot.
  - Protected and persistent packages.
- If voice search hangs after a cold boot, re-enable the **telemetry group** in `disable_stage1.txt` first (see lessons learned).

## Measuring before/after

Do this **before** running `02_detox.sh --apply`, then repeat after a reboot with the apps closed:

```sh
adb shell grep -E 'MemAvailable|SwapFree' /proc/meminfo
for i in 1 2 3; do
  adb shell am force-stop <package>
  adb shell am start -W -n <package>/<launcher-activity> | grep TotalTime
  sleep 8; adb shell input keyevent KEYCODE_HOME; sleep 3
done
```

Find the launcher activity with
`adb shell cmd package resolve-activity --brief -c android.intent.category.LEANBACK_LAUNCHER <package>`.
`01_analyse.sh` stores memory, CPU, services, package lists and key settings for later comparison.

## Optional: Private DNS (read the warning)

An ad/tracker-blocking DNS (for example AdGuard via DNS-over-TLS) can block ad and tracking domains network-wide:

```sh
adb shell settings put global private_dns_specifier <your-dns-over-tls-hostname>
adb shell settings put global private_dns_mode hostname
```

> **Warning:** in `hostname` (strict) mode all name resolution fails if the DNS-over-TLS server (port 853) is unreachable.
> In my test, after a cold boot Alexa was unreachable and YouTube started very slowly. I rolled back and could not prove
> whether DNS or a not-yet-settled network was responsible. Only enable it if you test **after a cold boot**.
> Roll back with `adb shell settings delete global private_dns_specifier` and
> `adb shell settings put global private_dns_mode opportunistic`.
> It does not block video ads inside YouTube, and it sends your DNS queries to a third party - decide consciously.

## Troubleshooting

| Symptom | What to do |
|---|---|
| `adb connect` refused (10061) / `device offline` | Toggle ADB debugging OFF/ON on the stick, reconnect, run commands in one batch |
| Voice search: blue bar hangs, no answer | Re-enable smarthome/device-control packages (`lists/caution.txt`), then the telemetry group |
| `Cannot disable a protected package` | Normal on Fire OS. Skip it |
| Packages are enabled again after reboot | Fire OS re-enabled them. Not an error |
| Alexa unreachable / very slow after cold boot | Check private DNS first (reset to `opportunistic`), then test reachability with `adb shell "echo | timeout 5 nc -w 4 <host> 443"` (`ping` is often blocked) |
| `dumpsys wifi` says disconnected | Irrelevant if the stick uses Ethernet. Check `dumpsys connectivity` |

## Use as a Claude Code skill

Copy `skill/firestick-detox/` to `~/.claude/skills/`. Then ask Claude Code, for example:
"My Fire TV Stick is slow and crashes. Analyse it over ADB and clean it up safely."
The skill enforces: analysis first, risk explanation, disable-only, never-list, small stages, undo log, honest measurement.

## Old non-Android TVs

Old TVs such as a 2010 Sony Bravia are not Android devices: there is no ADB and no package management.
See `docs/sony-bravia-tips.md` for what actually helps (use the TV as a plain display, eco settings, disconnect its network).

## Disclaimer

Use at your own risk. The lists were tested on **one device model and firmware (AFTKRT, Fire OS 8.1.8.5)**; other models and versions may behave differently.
Disabling system packages can affect features. Every step here is reversible with `pm enable`, but no warranty is given.
Not affiliated with Amazon. "Fire TV", "Alexa" and "Prime Video" are trademarks of their owners.

## License

Apache License 2.0, see `LICENSE`.
