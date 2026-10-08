# Readout — design

Status: draft for review · Date: 2026-10-08 · Owner: Jeremy Daughhetee

Readout is a small, open-source macOS menu bar system monitor that replaces the parts of iStat Menus 7 actually in daily use. Network up/down throughput is the headline feature; CPU temperature, disk usage, CPU history and memory pressure come along.

## 1. Goals and non-goals

**Goals**

- Glanceable network upload/download rates in the menu bar, at least as legible as iStat's.
- The four other items currently in use (section 2), visually close to iStat's compact two-line style.
- A light dropdown panel per item for detail.
- No privileged helper, no account, no telemetry. The only network calls are the update check and a public-IP lookup made while the network panel is open.
- Public MIT-licensed repo on GitHub, signed and notarized with Jeremy's own Apple Developer ID (team `PCWH4GSLHZ`, jeremy@weebu.com).
- Automatic updates via Sparkle.
- CI on every push and pull request; releases cut manually from GitHub Actions.
- README with screenshots.

**Non-goals (v1)**

- Fan control or anything else that writes to the SMC (it would need a privileged helper).
- Weather, time, battery, GPU-as-menu-item, alerts and notifications, desktop widgets, multi-profile settings.
- The Mac App Store (sandboxing blocks `nettop`, `ps` and AppleSMC access).
- Support for macOS older than 26 (Tahoe).

## 2. What it replaces (observed 2026-10-08 on macstudio, iStat Menus 7.30, macOS 26.6.2, M1 Ultra)

Menu bar items, left to right, taken from a screenshot plus `com.bjango.istatmenus.menubar.7.plist`:

| Item | Display | iStat source |
|---|---|---|
| CPU temperature | caption `CPU`, value `126°` (°F) | Sensors, `CUS_AS_CORE_AVERAGE` |
| Network | `↑ 25 KB/s` over `↓ 61 KB/s` | Network |
| Disk | caption `SSD`, value `81%` | Disks, boot "Data" volume |
| CPU history | bar graph, blue = user, pink = system | CPU, graph type |
| Memory | caption `MEM`, value `5%`, plus a vertical fill bar | Memory, pressure |

Two calibration facts:

- **Memory pressure.** iStat's 5% matched `kern.memorystatus_level` = 96, i.e. 100 − level gives about 4–5%. It is pressure, not % of RAM used.
- **Disk %.** iStat's 81% differs from `df` (89%) because iStat counts purgeable space as free.

## 3. Product

### 3.1 Menu bar items

Each item is its own `NSStatusItem`, so macOS persists ⌘-drag reordering through `autosaveName`. Default order matches section 2.

| Item | Rendering |
|---|---|
| Network | Two right-aligned lines, `↑` upload over `↓` download. Monospaced digits, fixed width so the bar never jitters. Units are B/s, KB/s, MB/s and GB/s with decimal (1000) steps, B/s and KB/s as integers, MB/s and GB/s with one decimal below 100 (`999 KB/s` → `1.0 MB/s`, `19.0 MB/s`, `125 MB/s`), matching iStat's `Network_DataFormat` bytes mode as observed under load on 2026-10-08. |
| CPU temp | 9 pt caption `CPU` over a value such as `126°`. Unit is °F or °C per settings. |
| Disk | Caption `SSD` over `81%`. |
| CPU graph | 20 columns at 1 sample/s (2 pt bars, 1 pt gaps, newest on the right), each a stacked user (blue) + system (pink) bar, inside a rounded outline. Matches iStat's density and colors in both appearances. |
| Memory | Caption `MEM` over `5%`, followed by a vertical bar filled to the pressure value. The bar turns yellow at 50% and red at 80% pressure. |

Text and outlines follow the menu bar's effective appearance (light or dark), and redraw when it changes.

### 3.2 Dropdown panels

Clicking an item opens an `NSPopover` hosting SwiftUI. Every panel ends with a footer: `Settings…`, `Check for Updates…`, `Quit Readout`. Work that is expensive (subprocesses, the public-IP fetch) runs only while a panel is open and stops when it closes.

| Panel | Contents |
|---|---|
| Network | Primary interface name and type (Wi-Fi/Ethernet/other). Local IPv4/IPv6. Public IP, fetched on open from `https://api.ipify.org` and cached for 5 minutes. Up/down history graph covering the last 10 minutes. Session totals since launch. Top 5 processes by bandwidth from `nettop`, sampled every 2 s while open. |
| CPU temp | CPU-cluster average, GPU average, hottest sensor (name + value), fan RPM. Fan RPM is omitted on fanless Macs. |
| Disk | Used / free / total for the boot volume. Read/write throughput summed across all block storage devices. |
| CPU | Total, user and system %. Per-core bars, grouped into performance and efficiency cores. Load averages. Top 5 processes by CPU from `ps`. |
| Memory | Pressure %. Used, wired, compressed and cached memory. Swap used. Top 5 processes by resident memory from `ps`. |

### 3.3 Settings

A small SwiftUI window, stored in `UserDefaults`:

- On/off toggle for each item.
- Temperature unit: °F (default) or °C.
- Network interface: Automatic (primary) by default, or a specific interface.
- Launch at login, via `SMAppService.mainApp`.
- Update checks: automatic (default on), and whether to download and install automatically (default on).

## 4. Architecture

### 4.1 Layout

```
Readout/
  ReadoutKit/                   SwiftPM package (kept out of the repo root so Xcode does not treat the root as a package)
    Package.swift
    Sources/ReadoutCore/        pure logic, no OS calls
    Sources/CReadout/           C shim: sysctl, mach, IOKit and AppleSMC calls
    Sources/ReadoutSystem/      samplers that read the OS through CReadout and Foundation
    Sources/readout-probe/      CLI: prints every metric once per second
    Tests/ReadoutCoreTests/
    Tests/ReadoutSystemTests/
  App/                          AppKit/SwiftUI app target (status items, panels, settings, Sparkle)
  project.yml                   XcodeGen spec for the app; the .xcodeproj is generated, not committed
  scripts/                      build, sign, notarize, screenshot, appcast helpers
  .github/workflows/            ci.yml, release.yml
  docs/images/                  README screenshots
```

- **App bundle and dependencies.** The app is built by Xcode through XcodeGen. That is the conventional path for embedding and signing Sparkle's framework and XPC services under the hardened runtime. Sparkle 2.10.x comes in as a Swift package dependency.
- **Identifiers.** Bundle id `com.daughhetee.Readout`, deployment target macOS 26.0. That is the oldest version we can test: both dev Macs run 26.6.2 and CI runs on `macos-26`. It also allows Liquid Glass panel styling and current SwiftUI with no availability branches. macOS 27 (Golden Gate, 27.0.1 shipped) is expected to work but is unverified until a Mac or a GitHub runner image is on 27; add `macos-27` to the CI matrix once GitHub publishes it. The app is an agent (`LSUIElement`) with no Dock icon.

### 4.2 Units and boundaries

- **ReadoutCore** is pure. It contains:
  - counter-delta math: 64-bit byte counters treat a decrease (reset, interface re-created) as 0, never a spike; 32-bit CPU tick counters use wrapping subtraction
  - rate computation over a monotonic elapsed time
  - byte-rate and percent formatters
  - CPU tick-ratio math
  - memory-pressure math
  - disk-usage math
  - a fixed-capacity ring buffer for history
  - temperature unit conversion
  - SMC value decoding and temperature-key classification (which keys count as CPU, GPU)

  Everything is unit-tested with recorded fixtures.
- **ReadoutSystem** holds one sampler class per metric, all owned by a `SamplingEngine` actor whose `tick()` returns a `Sendable` `MetricsSnapshot`. Samplers own the OS calls and nothing else; the stateful ones take their OS sources as injectable closures so tests can drive them. A failed read returns `nil` and logs through `os.Logger` (subsystem `com.daughhetee.Readout`).
- **App** layer:
  - `MetricsStore`, an `@MainActor @Observable` class. A main-actor `Task` loop awaits `SamplingEngine.tick()` once per second and applies the snapshot and histories.
  - Status item renderers, which are custom `NSView` drawing.
  - SwiftUI panels and settings.
  - The Sparkle updater controller.

  Views read the store only.

### 4.3 Data sources

| Metric | Source | Notes |
|---|---|---|
| Network bytes | `sysctl` `NET_RT_IFLIST2` → `if_msghdr2.ifm_data` (`if_data64`) | 64-bit counters. `getifaddrs`' 32-bit `if_data` wraps at 4 GiB. |
| Primary interface | `SCDynamicStore` key `State:/Network/Global/IPv4` → `PrimaryInterface` | Re-resolved on store change notifications. The rate is the primary interface only, so VPN tunnels are not double-counted. |
| Per-process network | `/usr/bin/nettop -P -L 1 -x -J bytes_in,bytes_out` | Two samples, then the delta. Panel-open only. |
| CPU | `host_processor_info(PROCESSOR_CPU_LOAD_INFO)` | Per-core user/system/idle/nice tick deltas. P/E grouping from each `IODeviceTree:/cpus/*` node's `cluster-type` keyed by `logical-cpu-id`. On M1 Ultra the clusters are interleaved (cpu0–1 E, 2–9 P, 10–11 E, 12–19 P), so position is not a valid proxy. |
| Top CPU / memory | `/bin/ps -Aceo pid,pcpu,rss,comm` | Panel-open only. |
| Memory pressure | `sysctl kern.memorystatus_level` | pressure = 100 − level |
| Memory breakdown | `host_statistics64(HOST_VM_INFO64)`, `sysctl vm.swapusage` | |
| Disk capacity | `URLResourceValues` `volumeTotalCapacity`, `volumeAvailableCapacity` (container free) and `volumeAvailableCapacityForImportantUsage` on `/`; `getattrlist(ATTR_VOL_SPACEUSED)` on `/System/Volumes/Data` | used % = (Data-volume used − purgeable) ÷ container total, where purgeable = important-usage free − container free. Matches iStat (80.41% vs iStat 80% on 2026-10-08); the container-wide figure read 81.6%. Falls back to the container-wide figure if `getattrlist` fails. |
| Disk throughput | IOKit `IOBlockStorageDriver` `Statistics` (bytes read/written), summed over all drivers | Deltas, as with network. A detached drive lowers the sum, which reads as 0 for that tick. |
| Temperatures | `AppleSMC` user client, read-only, `flt ` keys. CPU = mean of keys `Tp` + digit + any (P-core sensors; excludes `TpD*`). GPU = mean of keys `Tg` + digit + any. | Calibrated 2026-10-08 on M1 Ultra. iStat read 106/107/107 °F while the `Tp` mean read 107/106/104 °F, within tolerance. The IOHID `PMU tdie*` sensors read about 97 °F, about 10 °F low, so IOHID is not used. Readings outside 5–130 °C are discarded. `readout-probe --sensors` dumps every `T*` key. |
| Fan RPM | `AppleSMC` user client, read-only keys `FNum`, `F0Ac` | Reads need no privilege. Nothing is written. |
| Load averages | `getloadavg` | |

### 4.4 Errors

- A sampler returning `nil` renders its item as `—`.
- If temperatures read `nil` for 10 consecutive ticks (no sensors, e.g. in a VM), the temperature item hides itself and its panel explains why. It never shows a fabricated value.
- Subprocess failures (`nettop`, `ps`) show "unavailable" in that panel section.
- Nothing in the sampling path can terminate the app.

### 4.5 Performance budget

Average CPU at most 0.5% of one core with all panels closed, measured with `top -l 30 -pid <pid> -stats cpu` on macstudio. Resident memory at most 60 MB.

## 5. Updates (Sparkle 2)

- **Appcast.** `SUFeedURL` = `https://github.com/jeremywho/readout/releases/latest/download/appcast.xml`. The appcast is attached to every release, so "latest" always serves the newest feed. No gh-pages branch.
- **Signing.** Updates are signed with EdDSA (ed25519). The public key goes in `SUPublicEDKey` in Info.plist. The private key is stored in 1Password (vault Private) and as GitHub secret `SPARKLE_ED_PRIVATE_KEY`. Sparkle additionally verifies the Developer ID signature.
- **Defaults.** `SUEnableAutomaticChecks` = YES, `SUAutomaticallyUpdate` = YES, check interval 1 day. A `Check for Updates…` item sits in every panel footer.
- **Versioning.** `CFBundleShortVersionString` is semver from the release input. `CFBundleVersion` is the release workflow's `github.run_number`, which is monotonic and is what Sparkle compares.

## 6. CI/CD (GitHub Actions)

### 6.1 `ci.yml`: every push to any branch, and every pull request

Runs on `macos-26` (arm64). Public repos get hosted macOS minutes at no cost.

1. Check out the code, select the Xcode version, `brew install xcodegen`.
2. `swift format lint --strict --recursive ReadoutKit/Sources ReadoutKit/Tests App` (swift-format ships with the toolchain).
3. `swift test --package-path ReadoutKit` (ReadoutCore and ReadoutSystem tests).
4. `xcodegen generate`, then `xcodebuild build` for the app with ad-hoc signing (`CODE_SIGN_IDENTITY=-`).
5. `Readout.app/Contents/MacOS/Readout --self-test`: runs every sampler for 3 ticks headlessly and exits non-zero if any non-sensor sampler returns `nil`. Sensor samplers may be `nil` on the VM runner; real-hardware sensor verification is the acceptance step in section 8.

CI uses no secrets, so fork PRs are safe.

### 6.2 `release.yml`: manual `workflow_dispatch` with input `version` (e.g. `1.2.0`)

Runs in GitHub environment `release`, which holds the signing secrets and is restricted to `main`.

1. Refuse if not on `main`, if tag `v<version>` exists, or if `<version>` is not greater than the latest release tag.
2. Run the full CI steps.
3. Import the Developer ID Application `.p12` into a temporary keychain.
4. `xcodebuild archive`, then `-exportArchive` with method `developer-id`. Hardened runtime on; Sparkle's XPC services are signed inside-out by Xcode.
5. `ditto -c -k --keepParent` → `Readout-<version>.zip`. Submit with `xcrun notarytool submit --wait`, authenticated by App Store Connect API key, then `xcrun stapler staple` the app and re-zip.
6. Build `Readout-<version>.dmg` (app + `/Applications` symlink), then sign, notarize and staple it.
7. Verify, failing the job on any failure:
   - `codesign --verify --deep --strict`
   - `spctl -a -t exec -vv` on the app, and `spctl -a -t open --context context:primary-signature -vv` on the dmg
   - `xcrun stapler validate`
8. Sign the zip with Sparkle's `sign_update` and render `appcast.xml` (single latest item: version, build, EdDSA signature, length, minimum system version, release-notes link).
9. Create tag `v<version>` and a GitHub release with generated notes. Assets: dmg, zip, `appcast.xml`.

**Secrets (environment `release`):**

| Secret | Contents |
|---|---|
| `DEVELOPER_ID_P12_BASE64` | Developer ID Application cert and private key, exported from macstudio's login keychain |
| `DEVELOPER_ID_P12_PASSWORD` | Password for that `.p12` |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` | App Store Connect API key used for notarization |
| `SPARKLE_ED_PRIVATE_KEY` | Sparkle EdDSA private key |

Every secret value is also stored in 1Password, vault Private, item "Readout release signing".

### 6.3 Local parity

`scripts/release-local.sh <version>` runs steps 3–8 on macstudio against the same scripts the workflow calls. It is used to prove the pipeline before the first CI release.

## 7. README and screenshots

- `Readout --export-screenshots <dir>` renders the menu bar strip and each panel offscreen from fixed fixture data, in light and dark appearance, to PNG.
- `scripts/update-screenshots.sh` writes them to `docs/images/`.
- The README also includes one real menu bar capture from macstudio.

README sections: what it shows, install (dmg from Releases), updating, privacy (the two outbound requests and nothing else), building from source, release process, license.

## 8. Testing and acceptance

**Unit tests (ReadoutCore):**

- counter deltas, including a 32-bit wrap, a 64-bit counter, and a reset
- rate math with uneven tick intervals
- formatter boundaries (`999 B/s`, `1.0 KB/s`, `999 KB/s` → `1.0 MB/s`, `1.0 GB/s`)
- CPU tick ratios from recorded `host_processor_info` snapshots
- pressure math
- disk % with purgeable space
- ring buffer wrap
- °F/°C conversion
- SMC key classification and averaging using the recorded M1 Ultra key list
- `nettop` and `ps` output parsing from recorded output

**System tests (ReadoutSystem, run in CI):**

- network counters are monotonic across two reads
- CPU percentages sum to between 0 and 100
- memory pressure is between 0 and 100
- disk total is greater than 0, and free is less than or equal to total

**Acceptance on macstudio:**

- **Agreement with iStat.** With iStat running alongside, `readout-probe` and the menu bar agree with iStat within:
  - network ±10% under steady load
  - CPU temperature ±3 °F
  - disk ±1 point
  - memory pressure ±1 point
  - CPU total ±5 points
- **Network positive control.** `curl -o /dev/null` downloads a large file, and the reported download rate matches curl's average speed within ±10%.
- **Network negative control.** An idle link reads under 50 KB/s.
- **Performance.** The budget in section 4.5 is met.
- **Update path.** Install release N from the dmg, publish release N+1, and Readout updates itself with no prompt beyond Sparkle's first-run permission. The updated app passes `spctl`.
- **Visual.** A menu bar screenshot of Readout next to iStat is attached to the first release PR.

## 9. Licensing and third-party code

- Readout is MIT, copyright Jeremy Daughhetee.
- exelban/stats is MIT (copyright 2019 Serhiy Mytrovtsiy). MIT allows copying with the notice preserved, and the grant on a copied version cannot be revoked by later owners.
- Policy: Readout is written from scratch. Stats may be read as a reference for facts (which APIs exist, sensor naming conventions). If any substantial portion is copied verbatim, `THIRD_PARTY_NOTICES.md` carries Stats' MIT notice and lists exactly which files are affected.
- Sparkle is MIT. Its notice also goes in `THIRD_PARTY_NOTICES.md` and is bundled in the app's Resources.

## 10. Prerequisites outside the repo

1. **Developer ID export.** Export the Developer ID Application identity as a `.p12` from macstudio's login keychain. This may need one GUI "Allow" click in the `hil` session, the same pattern as the hehehe Distribution signing.
2. **App Store Connect API key.** Reuse the existing team key, the one already configured in the fastlane `.env` on macstudio, for notarization.
3. **Sparkle EdDSA key pair.** Generate with Sparkle's `generate_keys` and store in 1Password.
4. **GitHub repo setup.** Create public repo `jeremywho/readout` with branch protection on `main` (CI required), and an environment `release` restricted to `main`.
