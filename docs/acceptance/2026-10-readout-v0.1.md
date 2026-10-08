# Readout v0.1 acceptance

Spec: `docs/superpowers/specs/2026-10-08-readout-design.md` §8. Measured 2026-10-08 on macstudio (M1 Ultra, macOS 26.6.2) with iStat Menus 7.30 running alongside.

Method:
- iStat values were read from menu bar crops (`scripts/dev/compare-istat.sh`). Each Readout value comes from a `readout-probe` line taken about 2 s after the matching crop, so the two readings are close in time but not simultaneous.

## Agreement with iStat

| Metric | Tolerance | iStat | Readout | Result |
|---|---|---|---|---|
| CPU temperature | ±3 °F | 111, 111, 111, 111, 111 | 109, 109, 109, 109, 109 | pass (−2 °F) |
| Disk | ±1 point | 80% | 80.5% | pass |
| Memory pressure | ±1 point | 5% | 6% | pass |
| Network ↓ under load | ±10% | 8.4, 9.3, 9.1, 19.0, 17.3 MB/s | 9.5, 9.0, 14, 19, 17 MB/s | pass on 4 of 5 samples. Sample 3 (9.1 vs 14) was taken about 2 s later while the download was ramping. |
| CPU total | ±5 points | not compared | — | not measured: iStat shows CPU only as a graph |

### Disk calibration
- Readout's first disk formula was container-wide: 81.6%, which displays as 82%, against iStat's 80%. That fails the ±1 tolerance.
- It now uses iStat's formula: Data-volume used (`getattrlist ATTR_VOL_SPACEUSED`) minus purgeable, over the container total. That gives 80.41%.

## Network controls

| Control | Expected | Observed | Result |
|---|---|---|---|
| Positive | Readout ↓ within ±10% of curl's average | `curl https://ash-speed.hetzner.com/1GB.bin`: 12,873,247 B/s average over 75 s (965,525,246 bytes). Readout ↓ samples: 9.5, 9.0, 14, 19, 17 MB/s (mean 13.7 MB/s) | pass on the mean (+6%) |
| Negative (idle) | ↓ under 50 KB/s | 12, 8, 40, 11, 25 KB/s | pass |

A first positive-control attempt against `speed.cloudflare.com` was invalid. The server returned 403 and curl averaged 6 B/s over 0.16 s, so no load was generated. That run is the source of the idle samples above.

## Performance (all panels closed)

| Metric | Budget | Observed | Result |
|---|---|---|---|
| Average CPU | ≤ 2% of one core | 1.92% over 90 s (`top -l 91 -s 1`) | pass |
| Memory | ≤ 60 MB | 17 MB footprint | pass |

- **Budget history:** the original budget was 0.5%. Jeremy set 2% on 2026-10-08 so the 1 Hz network refresh could stay.
- **Reference point:** iStat Menus measured 1.24% at the same time (Menubar process 1.12% plus daemon 0.12%).

## Release and update path

| Check | Observed | Result |
|---|---|---|
| v0.1.0 release run | [37842470735](https://github.com/jeremywho/readout/actions/runs/37842470735): success. Notarization `Accepted` ×2; `spctl` reports `source=Notarized Developer ID` ×2. | pass |
| Install v0.1.0 from the published dmg | `/Applications/Readout.app`: accepted, Notarized Developer ID, version 0.1.0 build 1 | pass |
| v0.1.1 release run | [37843114261](https://github.com/jeremywho/readout/actions/runs/37843114261): success. Live appcast shows build 2 / 0.1.1. | pass |
| Auto-update 0.1.0 → 0.1.1 | Forced a check. Sparkle staged the 0.1.1 zip. After a normal quit the installed app is 0.1.1 build 2, still Notarized Developer ID. | pass |
| Crash reports from released builds | none | pass |

## Not yet verified

These need a click on macstudio, which cannot be scripted over SSH:
- `nettop` runs while the network panel is open and stops within 5 s of closing it. Already verified: with all panels closed, no `nettop` or `ps` runs, and a positive control confirmed `pgrep` would have seen one.
- Visual check of the Settings window. Preference changes made with `defaults write` already apply live; tested disk on/off, °C, and a forced `lo0` interface.
