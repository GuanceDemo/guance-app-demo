# Guance Cocos Game Demo

An interactive **Cocos Creator 3.8.8** game with real Android and iOS native screens, plus a separate SDK laboratory. The interface is in English. Both platforms use `com.guance.cocos.demo` by default.

## Play Crystal Dash

**Native lobby → Cocos game → native results → play again / lobby / SDK lab.**

Drag the ship around the arena, collect green gems and avoid red meteors. Each round lasts 45 seconds or until all three shields are lost. Consecutive gems increase the score multiplier. The game includes collision detection, particles, scrolling stars, a live score/timer, pause/resume, a leave-round confirmation and a locally saved personal best. Backgrounding the app pauses the round; resume explicitly when returning.

Gameplay works without a backend or SDK configuration. Configure Guance to inspect gameplay telemetry and Session Replay. The optional network experiments use the existing Demo Server.

## Native / Cocos boundaries

| Screen | Android | iOS |
| --- | --- | --- |
| Game lobby | `NativeGameActivity` with Android widgets | `GCNativeGameController` with UIKit |
| Interactive round | Cocos touch input, Graphics and tweens | Same Cocos game |
| Results and replay entry | Android native results layout | UIKit native results layout |
| SDK lab and connection settings | Cocos UI | Same Cocos UI |

Native pages receive only round results, personal best and a credential-free SDK status. Reflection opens the platform screen; a one-shot mailbox returns a navigation action to Cocos. SDK credentials stay in the existing app configuration and are not passed to these pages.

App-owned native source lives in `platforms/android` and `platforms/ios`. `scripts/native-project.mjs` copies it into Creator-generated projects, registers the Android Activity, preserves reflection entry points for R8 and adds the Objective-C++ file to the iOS target. Generated `native/`, `build/` and SDK extensions remain ignored. Always use the build scripts to apply these integrations.

Browser builds show an explicitly labeled **Cocos preview** of the lobby and results. Real platform pages require a native build. The Cocos Replay camera captures the game and Cocos lab; it does **not** capture the Android Activity or UIKit screens. Each native/Cocos destination receives a distinct manual RUM View.

## Install and open

```sh
cd src/cocos/demo
npm run setup
```

Open this directory in Creator **3.8.8**. The entry scene is `assets/scenes/Demo.scene`. Reopen Creator after the first SDK extension installation.

`npm ci` installs the committed lockfile: `@cloudcare/cocos-sdk@0.1.0-alpha.6` and `@cloudcare/cocos-session-replay@0.1.0-alpha.6`. Keep these packages on the same exact version. The demo does not depend on a local SDK source checkout.

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
  "enableSessionReplay": true
}
```

- Optional Cocos App IDs override `demoAndroidAppId` / `demoIOSAppId`. Existing configuration strings remain compatible.
- For DataWay, supply `datawayAddress` and `datawayClientToken` instead of `datakitAddress`. If both are supplied, DataKit takes precedence.
- Import fills the form; **Save settings** persists it in `sys.localStorage`. Only the current platform App ID is required. Changes to an active SDK require closing and reopening the app. The personal best uses a separate storage key.
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
| Replay | Game motion and particles, public text, masked test input, pause/resume |
| Native screens | Open the real platform lobby from the lab |

Native Crash / Android ANR / UI Block capture is enabled. JS Error / LongTask experiments do not deliberately crash the native process. Automatic native View/Action/Resource and native Trace are disabled to avoid duplication with Cocos collection. Calls succeeding locally do not prove ingestion; check the configured Guance workspace. Server Trace linkage requires the existing Demo Server to run through `ddtrace-run` in the same workspace.

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
6. Run lab experiments, including invalid configuration, HTTP failures and privacy masking. Repeat on physical Android/iOS devices before distribution.

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
