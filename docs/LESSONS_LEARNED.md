# Lessons Learned (Fire TV Stick AFTKRT, 1.7 GB RAM, Fire OS 8.1.8.5 / Android 11)

An honest field report from one real run. Results apply to this device and may differ on yours. All personal data is removed.

## Outcome
- 23 packages (stage 1) + 9 packages (stage 3) disabled, nothing deleted. Animations off, screen-off timeout 5 minutes.
- Subjectively smoother: YouTube feels faster; voice search, Prime Video and Amazon Music work.
- **Not measurably better in memory:** free RAM at idle (`MemAvailable`) ~435 MB before, ~412 MB after.
  Most memory is held by the launcher (~180 MB), `system_server` and the Alexa services, which must stay enabled.
- Cold-start times afterwards (activity start, `am start -W`): YouTube ~0.4 s, Prime Video ~0.6-0.8 s.
  I did not record a "before" value. **Measure start times before changing anything**, otherwise you have no proof.

## What went wrong / pitfalls
1. **Voice search hung** (blue bar, no Alexa answer) after disabling smarthome, device-control and kids-related packages.
   Re-enabling them fixed it. Cause not proven. See `lists/caution.txt`.
2. **Fire OS re-enables packages on its own** (five packages from my second stage were enabled again after a reboot).
3. **Protected packages** (`Cannot disable a protected package`) cannot be disabled. Skip them.
4. **The ADB TCP port is unreliable**: after reboots or under load I saw `connection refused (10061)` and `device offline`.
   The stick still advertised itself via mDNS (`_adb._tcp`) while the port was closed.
   Fix: toggle ADB debugging OFF/ON and run all commands in one batch instead of a long back-and-forth.
5. **Private DNS (AdGuard) in `hostname` mode**: after a cold boot Alexa was unreachable and YouTube started very slowly.
   Strict mode breaks name resolution if the DNS-over-TLS server (port 853) is unreachable. I reverted to default.
   Whether DNS or a not-yet-settled network after boot was the cause remained open. **Do not enable it without testing after a cold boot.**
6. **`ping` from the stick is unreliable** (ICMP often blocked). Test with `echo | timeout 5 nc -w 4 <host> 443`.
7. The stick used **Ethernet**; `dumpsys wifi` said "DISCONNECTED", which was irrelevant. Check `dumpsys connectivity` for the active network.
8. `ip route` on Android shows only the main table; default routes live in `ip route show table all`.

## Approach that worked
- Analyse read-only first, then dry run, then apply in small stages.
- Reboot and test the apps you use plus voice search after each stage.
- Log every package with an undo command. Roll back suspect groups first (smarthome, then telemetry).
- Finally turn ADB debugging and "Apps from unknown sources" OFF.

## Honest limits
- Old Sony Bravia TVs (for example a 2010 KDL-40NX705) do not run Android: no ADB, no package cleanup. See `sony-bravia-tips.md`.
- You cannot create more RAM. Regular restarts and enough free storage help more than disabling additional packages.

---

# Second run: AFTSS, Fire OS 7.7.1.7 / Android 9, 0.9 GB RAM (used with a 4K OLED TV)

## Outcome
- 24 packages disabled in two stages (A: ads/promo/dummy 17, B: tracking/telemetry 7), nothing deleted; animations 0/0/0.
- Alexa voice search, music playback and starting Prime Video/YouTube by voice worked after both stages.
- **No measurable gain.** Free RAM ~237 MB before, ~202-209 MB after; YouTube cold start 786-1087 ms before, 990-1559 ms after
  (the first "after" run was only minutes after a cold boot and is not comparable). The list from the first device carried over
  almost 1:1, so the lists are portable across Fire OS 7 and 8 on these sticks.

## New lessons
1. **Know the real package names before concluding an app is missing.** I searched for `avod` and `music` and wrongly reported
   Prime Video and Amazon Music as not installed. They are `com.amazon.firebat` (Prime Video) and `com.amazon.bueller.music`
   (Amazon Music). Both are on the never-list. Use `pm list packages | grep -iE 'firebat|bueller|youtube'` and check the launcher with
   `cmd package resolve-activity --brief -c android.intent.category.LEANBACK_LAUNCHER <pkg>`.
2. **Disabled packages can be silently back after the first reboot.** After stage B and a reboot all 7 packages were enabled again
   (the count of `pm list packages -d` was unchanged). Re-applying and rebooting again kept them disabled. Cause unproven
   (Fire OS re-enable, or the change not persisted before the reboot). Always verify after the reboot (`scripts/03_verify.sh`)
   and wait a minute before rebooting after `pm disable-user`.
3. **Measure under comparable conditions.** "Before" was a warm, long-running system; "after" started minutes after a cold boot
   and looked slower. Compare like with like (cold boot + 5-8 min settle time both times), otherwise you measure the reboot.
4. **Several sticks in one household.** Identify the target (`ro.product.model`, `ro.serialno`, `ro.build.display.id`) before
   changing anything and compare it with what the owner told you.
5. **Windows Git Bash rewrites `/data` into `C:/Program Files/Git/data`** in adb arguments (`df: 'C:/Program': No such file`).
   Fixed with `export MSYS_NO_PATHCONV=1` in the scripts.
6. **`dumpsys package` prints "Failed to write while dumping service package: Broken pipe"** when piped into `grep -m1`.
   Harmless; stderr is now silenced inside the persistent-package check.
7. **`device unauthorized`** means the TV waits for "Always allow". Only the user can accept it on the TV.
8. A 0.9 GB stick has no headroom: the launcher (~115 MB), `system_server` (~75 MB), `surfaceflinger` (~60 MB) and the Alexa
   services dominate. Expect cosmetic benefits only.
