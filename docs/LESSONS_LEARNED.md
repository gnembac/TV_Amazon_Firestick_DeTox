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
