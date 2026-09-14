# Guance Cocos Game Demo

An interactive **Cocos Creator 3.8.8** game with real Android and iOS native screens, plus a separate SDK laboratory. The interface is in English. Both platforms use `com.guance.cocos.demo` by default.

## Play Crystal Dash

**Native lobby → Cocos game → native results → play again / lobby / SDK lab.**

Drag the ship around the arena, collect green gems and avoid red meteors. Each round lasts 45 seconds or until all three shields are lost. Consecutive gems increase the score multiplier. The game includes collision detection, particles, scrolling stars, a live score/timer, pause/resume, a leave-round confirmation and a locally saved personal best. Backgrounding the app pauses the round; resume explicitly when returning.

Gameplay works without a backend or SDK configuration. Configure Guance to inspect gameplay telemetry and Session Replay. The optional network experiments use the existing Demo Server.

Android system Back returns from Cocos lab subpages to their parent and from the lab to the native lobby. During a round, Back pauses and opens the leave confirmation; Back again dismisses it and resumes the round. Choose **Back to native lobby** to abandon the round. Native screens keep their own Back handling.

## Native / Cocos boundaries

| Screen | Android | iOS |
| --- | --- | --- |
| Game lobby | `NativeGameActivity` with Android widgets | `GCNativeGameController` with UIKit |
| Interactive round | Cocos touch input, Graphics and tweens | Same Cocos game |
| Results and replay entry | Android native results layout | UIKit native results layout |
| SDK settings | Android switches, text fields and selectors | UIKit switches, text fields and segmented controls |
| SDK lab | Cocos UI | Same Cocos UI |

Lobby/results receive round data and SDK status. The native settings page receives a configuration draft and returns import/check/save actions through the same one-shot mailbox. Cocos validates the draft; saved settings live in Android SharedPreferences / iOS NSUserDefaults so the native host can initialize before the Cocos runtime starts. Drafts are not logged or added to telemetry; the DataWay token uses a password field, and Android settings disallow screenshots. Cancel leaves the saved configuration unchanged.

App-owned native source lives in `platforms/android` and `platforms/ios`. `scripts/native-project.mjs` copies it into Creator-generated projects, registers the Android Activity, preserves reflection entry points for R8 and adds the Objective-C++ files to the iOS target. It also registers `NativeSdkApplication` and patches iOS AppDelegate to call `GCNativeTelemetry.boot` before creating the Cocos controller. Generated `native/`, `build/` and SDK extensions remain ignored. Always use the build scripts to apply these integrations.

Android launches `NativeCocosActivity`, a subclass of Creator's `AppActivity`. It forwards system Back through the native mailbox, including Android 13+ back callbacks, while leaving text-editing keys to the engine. The generated manifest preserves Creator's launcher settings and opts this Activity into the system back callback.

Android builds also apply `ft-plugin:1.3.9-alpha01`, paired with the Cocos SDK's Android Agent `1.7.6-alpha03` in its Hybrid host. The native patch script adds the Maven classpath and plugin configuration after each Creator build, including HTTPURLConnection instrumentation. Runtime native collection switches still follow the demo's telemetry configuration.

The same script sets `max-page-size=16384` and `common-page-size=16384` when linking `libcocos.so`, so Creator's NDK 22 produces 16 KB-aligned LOAD segments and GNU_RELRO boundaries. This applies to Debug and Release. Check every packaged `.so` again when upgrading native dependencies; these link flags do not change prebuilt libraries. ELF/ZIP alignment checks do not replace testing on a device with a 16 KB page size.

Browser builds show an explicitly labeled **Cocos preview** of the lobby and results. Real platform pages require a native build. The native SDK records Android/UIKit pages using its native recorder; the Cocos Replay camera captures the game and lab only while Cocos is visible. Each destination receives a distinct RUM View. Native View/Action events originate in the native page lifecycle. Before a native page covers Cocos, `leaveCocos()` releases the Cocos View, hooks and recorder; returning to Cocos calls `enterCocos({ viewName })`. Component disable/destroy and background/foreground follow the same visibility boundary.

## Hybrid SDK initialization

This demo follows the native-owned Hybrid lifecycle:

1. Android `NativeSdkApplication.onCreate()` / iOS `AppDelegate` loads saved settings and initializes the native SDK, RUM, Logger, Trace and optional Session Replay before starting Cocos. Native Replay uses the default native recorder mode, never external-only mode.
2. `Telemetry.start()` asks the app-owned host bridge to ensure initialization, then calls `sdk.attach({ autoTrack, replay })`. On first setup or migration from old Cocos localStorage, the native host initializes after valid settings become available. Subsequent launches initialize directly from native storage.
3. `attach()` receives only Cocos capture and automatic tracking options. App IDs, collector credentials and sampling are applied by `NativeTelemetry` / `GCNativeTelemetry`, not passed to the SDK's `attach()` API. All modules sample at 100% (Android `1`, iOS `100`).
4. Cocos page visibility controls `enterCocos()` / `leaveCocos()`. No Cocos `sdk.start()`, `sdk.shutdown()` or direct `sdk.replay.start()/stop()` calls remain. Disabling the SDK explicitly asks the native host to shut down after Cocos leaves; enabling again requires an app restart if the host was stopped.

The old Cocos settings are read only when native storage is empty, then migrated on successful native initialization. Saved changes to an active SDK require a restart; pending settings never reinitialize the host while navigating. Gameplay and the settings screen remain available before SDK configuration.

## Install and open

```sh
cd src/cocos/demo
npm run setup
```

Open this directory in Creator **3.8.8**. The entry scene is `assets/scenes/Demo.scene`. Reopen Creator after the first SDK extension installation.

`npm ci` installs the committed lockfile: `@cloudcare/cocos-sdk@0.1.0-alpha.7` and `@cloudcare/cocos-session-replay@0.1.0-alpha.7`. Keep these packages on the same exact version. The demo does not depend on a local SDK source checkout.

## Configure telemetry

Choose **Connection settings** in the native lobby or **Settings** in the Cocos navigation. Enter values manually or paste JSON / a configuration string produced by the existing server `/import_helper`:

```text
gc-demo://<Base64-encoded UTF-8 JSON>
```

```json
{
  "demoCocosAndroidAppId": "android-cocos-app-id",
  "demoCocosIOSAppId": "ios-cocos-app-id",
  "demoApiAddress": "https://demo.example.com",
  "datakitAddress": "http://192.168.1.2:9529",
  "enableSdk": true,
  "enableSessionReplay": true,
  "replayFps": 1,
  "replayQuality": "medium"
}
```

- Optional Cocos App IDs override `demoAndroidAppId` / `demoIOSAppId`. Existing configuration strings remain compatible.
- For DataWay, supply `datawayAddress` and `datawayClientToken` instead of `datakitAddress`. If both are supplied, DataKit takes precedence.
- Import fills the native form; **Save settings** persists it in the native host settings store (browser preview uses `sys.localStorage`). Only the current platform App ID is shown and used by native SDK initialization; the other platform ID is retained for import compatibility and never used as a fallback.
- **Enable SDK** controls initialization. Saving it off stops a running SDK immediately, and an empty connection is allowed when disabled. Other changes to an active SDK require closing and reopening the app; the page shows the pending restart notice after save.
- Switches control Session Replay, native crash / Android ANR / UI block collection, automatic Cocos network / JavaScript error collection, and debug logging. Existing saved settings receive the original defaults.
- **Replay capture FPS** supports integers 1–5 (default 1). **Replay image quality** uses SDK presets: Low (480 px), Medium (720 px, default), High (960 px), including their compression and traffic budgets. These settings affect Replay, not game rendering. Adaptive capture may reduce actual FPS/resolution. Returning from native pages retains the selected capture settings.
- The personal best uses a separate storage key.
- Connection checks use Demo Server `/connect`, DataKit `/v1/ping`, or DataWay `/v1/write/logging?...&to_headless=true`. The DataWay check sends one `connect test` log. Checks bypass Resource/Trace capture so the token does not enter telemetry.
- Configuration fields and Replay privacy probes are masked. Do not commit device settings or credentials.
- Android emulators reach the host via `10.0.2.2` or `adb reverse`. Use accessible LAN/public addresses on physical devices. HTTP is enabled for local Demo API / DataKit compatibility.

## SDK lab

The lab remains available from the native lobby, native results and Cocos navigation.

| Experiment | What to inspect |
| --- | --- |
| Gameplay | `game_start`, `game_drag`, `game_collect`, `game_hit`, `game_pause`, `game_resume`, `game_abandon`, `game_finish` Actions; round result Log |
| Hybrid navigation | `NativeGameLobby` → `CocosCrystalDash` → `NativeRoundResults` Views; `native_navigation` Action |
| Custom RUM | Manual View / Action lifecycle |
| Logs | info, warning, error, critical, ok linked to the current View |
| Errors | Caught error reporting and an uncaught async JS error |
| LongTask | Bounded ~250ms JS blocking, reported in nanoseconds |
| Network | Automatic XHR success / HTTP 404, manual Resource and correlated ddTrace headers |
| Replay | Game motion, public text, masked test input, native/Cocos recorder transitions |
| Multi-touch Replay | Up to five independent colored touch trails, IDs and counters; two-finger card translation, pinch and rotation |
| Native screens | Open the real platform lobby from the lab |

Native Crash / Android ANR / UI Block capture is enabled by default and can be changed in settings. JS Error / LongTask experiments do not deliberately crash the native process. Native automatic View/Action tracking is disabled because native pages report their own Views/Actions. Android keeps the Resource master switch on for host traffic but disables HttpURLConnection Resource capture. On iOS, NSURLSession and NSURLConnection Resource capture are disabled because Creator 3.8.8 XHR is collected by Cocos. Native automatic Trace injection is off on both platforms, preserving Cocos headers and untracked connection probes. Calls succeeding locally do not prove ingestion; check the configured Guance workspace. Server Trace linkage requires the existing Demo Server to run through `ddtrace-run` in the same workspace.

### Hybrid navigation verification

On Android and iOS, repeat **native lobby → Cocos game/lab → native lobby** at least three times. Verify a single active View, continuous native/Cocos Replay without stale frames, and no repeated initialization errors. Cover and restore Cocos, background/foreground it, and verify that native settings remain masked. Disabling Replay omits Cocos capture without disabling RUM; disabling the SDK stops it through the native host. Unit tests and native compilation do not replace these device and ingestion checks.

### Multi-touch Replay verification

Open **Lab → Session Replay · Multi-touch playground** (also linked from the Replay privacy page). The fixed touch arena supports up to five fingers without scrolling. Each active touch has its own color, engine touch ID and bounded trail; the last five completed trails remain dimmed until reset. The oldest two active fingers control the card. Other fingers draw independently. The HUD shows active/peak touches and down/up/cancel counts.

1. Enable Session Replay in settings and restart the native app. This demo uses `touchPrivacy: 'show'` across Replay-enabled pages, including after native/Cocos transitions; configuration and private inputs retain their masks.
2. Hold two fingers, move them in opposite directions, cross their paths, then pinch and rotate. Hold each pose for at least one second to compare with the configured canvas capture rate (1 FPS by default).
3. Add a third to fifth finger. Lift one while continuing to move the others, then touch again. Verify IDs remain attached to the correct fingers, active counts decrease, and replacing a gesture finger does not jump the card.
4. Drag outside the arena, reset while another finger is held, navigate away and return, and background/foreground the app while touching. Active markers must clear on cancellation, reset, navigation and backgrounding; a new touch starts tracking again.
5. In Guance, find the `CocosMultiTouchReplay` View and compare the canvas trails/card with Replay touch indicators. Actions `multitouch_start`, `multitouch_end`, `multitouch_cancel` and `multitouch_reset` help locate the interaction; moves do not emit per-frame RUM Actions.

The pinned Replay SDK `0.1.0-alpha.7` records pointer down/up (cancel becomes up), but does not emit continuous pointer-move records. Colored trails and card transforms are canvas content captured at the configured FPS (default 1), not proof of continuous pointer-event playback. Validate native recording and ingestion on a physical Android/iOS multi-touch device; desktop mouse preview only checks single-pointer interaction.

## Build and verify

The default Creator executable on macOS is `/Applications/Cocos/Creator/3.8.8/CocosCreator.app/Contents/MacOS/CocosCreator`. Override it with `COCOS_CREATOR` when needed.

```sh
npm test
npm run build:preview
npm run typecheck
npm run build:android
npm run build:ios
```

Creator generates the engine declarations used by typecheck. The build scripts accept Creator success exit code 36 and apply the native page integration after generation.

- Android: open `build/android/proj` in Android Studio, or run `./gradlew --no-daemon --max-workers=2 assembleDebug` there. The APK is under `build/android/proj/build/GuanceCocosDemo/outputs/apk/debug/`.
- iOS: run `pod install` in `build/ios/proj`, open `GuanceCocosDemo.xcworkspace` and use the `GuanceCocosDemo-mobile` scheme. SDK extensions manage native Agent/Replay dependencies.
- Xcode 26 / AppleClang 17+: the demo applies `-Wno-invalid-specialization` to the generated `cocos_engine` target for Creator 3.8.8 Enoki compatibility. The Creator installation is not modified.
- On memory-constrained machines, run one platform simulator at a time and limit native compilation to two workers.

### Acceptance route

1. Open the app and confirm a real native lobby appears. Play without a network connection.
2. Drag the ship, collect gems, hit a meteor and verify score, shields, effects and combo changes.
3. Pause/resume; background/foreground the app; confirm the timer does not advance while paused.
4. Finish a round and confirm native results match it. Play again and return to the lobby; confirm the personal best survives an app restart.
5. Open settings and import the existing configuration. Restart, play a round and inspect native/Cocos Views, game Actions, logs and game Replay.
6. In native settings, check DataKit/DataWay visibility, import success/failure, save/cancel, keyboard scrolling, Replay FPS/quality, and SDK on/off. Supply distinct Android/iOS IDs, restart each platform, and verify its newly captured RUM and Replay data uses the matching ID. Previously queued records may still belong to the earlier configuration.
7. Run lab experiments, including invalid configuration, HTTP failures and privacy masking. Repeat on physical Android/iOS devices before distribution.

## Prepare distribution artifacts

Release scripts only prepare local artifacts. They do not upload. Set `DEMO_VERSION`, an increasing `DEMO_BUILD_NUMBER` and `DEMO_PACKAGE_NAME=com.guance.cocos.demo` for both platforms.

Android also requires `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`:

```sh
npm run release:android
```

Outputs include a signed APK, SHA-256, `release.json` and available R8 mapping in `artifacts/android/<version>-<build>/`. Keep matching native symbols and JS source maps. Do not distribute a debug APK as a release.

iOS also requires `APPLE_TEAM_ID`, `IOS_EXPORT_OPTIONS` pointing to a local export plist, and installed signing certificates/profiles. Optionally set `IOS_SCHEME`:

```sh
npm run release:ios
```

The export plist must use local export (`destination=export`), with `app-store-connect` or the legacy `app-store` method. Outputs include the archive/dSYMs, IPA, SHA-256 and `release.json`. Upload later with Xcode Organizer or Transporter and configure TestFlight groups separately.
