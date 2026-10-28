# Guance Cocos Creator 2.4.9 Demo

Creator **2.4.9** edition of the [3.8.8 demo](../demo/README.md), with the same English interface, 720 × 1280 layout and features:

- Crystal Dash: drag the ship, collect gems, dodge meteors, combos, particles, shields, 45-second rounds, pause/leave confirmation and saved best score.
- Native Android / UIKit lobby, results and connection settings; the browser shows labeled Cocos previews.
- SDK lab: custom RUM Views/Actions, five log levels, caught/uncaught JS errors, bounded LongTask, automatic/manual network Resources and Trace, Replay motion/privacy, and two-to-five-finger Replay playground.
- Native-owned Hybrid SDK lifecycle, persistent configuration import, platform-specific App IDs, DataKit/DataWay connection checks, SDK/Replay switches, FPS/quality and native collection controls.

The original Creator 3.8.8 project remains in `../demo`. This project uses the matching SDK `/creator2` entry points and Creator 2 JSB reflection. Android and iOS use `com.guance.cocos.demo249` by default so both editions can be installed together. Native classes retain their `com.guance.cocos.demo` Java namespace independently of the application ID. Telemetry includes `creator_version=2.4.9`.

## Install and open

```sh
cd src/cocos/demo-2.4.9
npm run setup
npm run typecheck
npm test
```

Open **this directory** in Creator **2.4.9**, then open `assets/scenes/Demo.fire`. Reopen Creator after installing the SDK extension. `project.json`, `settings/project.json` and `settings/builder.json` use Creator 2 formats. Generated SDK extension files live in ignored `packages/guance-cocos-sdk`; `npm run setup` recreates them from the committed npm lockfile.

On macOS the default executable is `/Applications/Cocos/Creator/2.4.9/CocosCreator.app/Contents/MacOS/CocosCreator`. Set `COCOS_CREATOR` for another location. Typecheck copies the declarations from that installation; set `COCOS_RESOURCES` to its Resources directory when its layout differs (for example on Windows). The engine declarations are generated locally and ignored.

## Configure and play

Choose **Connection settings** in the lobby or **Settings** in Cocos navigation. Use the same JSON or `gc-demo://` configuration string as the existing demo/server `/import_helper`. Optional `demoCocosAndroidAppId` and `demoCocosIOSAppId` override the respective native-demo IDs. Configure the appropriate Guance application for each installed demo. Gameplay works without SDK configuration or a backend.

See the [shared settings and experiment guide](../demo/README.md#configure-telemetry) for all fields and the [game/native navigation acceptance route](../demo/README.md#acceptance-route). The same workflows apply to 2.4.9, including save/cancel/import, restart requirements, Android Back, background pause, Replay privacy and multi-touch cancellation. Connection checks bypass SDK hooks so the DataWay token is excluded from telemetry.

## Build

```sh
npm run build:preview
npm run build:android
npm run build:ios
```

Run one Creator/native build at a time. The scripts use Creator 2's `--path` CLI, generate each platform into a separate build folder, then integrate app-owned native pages. SDK extensions supply the native Agent/Replay dependencies. Do not build directly from the editor and skip the post-build integration.

- Web: serve `build/web-mobile` with a local HTTP server and open `index.html`.
- Android: open the generated `frameworks/runtime-src/proj.android-studio` project under `build/android/jsb-link`. Use an Android SDK with API 34 and Creator-compatible JDK/NDK. Native compilation is capped at two jobs; use `./gradlew --no-daemon --max-workers=2 assembleDebug`.
- iOS: in the generated `frameworks/runtime-src/proj.ios_mac` directory under `build/ios/jsb-link`, run `pod install` and open the generated workspace. Native app sources are added to the iOS target with ARC; `AppController.mm` boots telemetry before Cocos starts.

Set `DEMO_PACKAGE_NAME` when building to override both platform application IDs. Build outputs, credentials, device settings and generated editor caches are ignored. Signing/distribution is performed in the platform tools; these commands generate local projects only.

Creator 2 uses `cc.Node` dimensions/colors, `cc.Mask.Type.RECT`, world-space touch locations and a `.fire` entry scene. `assets/scripts/Engine.ts` exposes its global `cc` APIs to the application modules. Game rules, page dimensions, action names and native page layouts follow the 3.8.8 edition. Android integration uses `org.cocos2dx.javascript.AppActivity` / `Cocos2dxActivity`, ndk-build alignment flags and the same `ft-plugin` instrumentation. Link flags alone do not certify all bundled prebuilt libraries for 16 KB devices.

Native compilation, physical Android/iOS navigation, multi-touch recording and Guance ingestion must be verified in the target environment. Unit tests cover game rules, configuration, network bypass, native mailboxes, Back handling, Hybrid transitions and repeatable native project integration.

## Verification on this workstation

- `npm run typecheck` and all 49 tests pass.
- Creator 2.4.9 editor/browser preview verified lobby, dragging/scoring, pause/return, lab navigation, touch trails/counters and settings input alignment/scrolling, with no runtime errors.
- SDK installation and repeatable Android/iOS host integration pass against the actual Creator 2.4.9 bundled `js-template-link` templates.
- CLI packaging is not yet verified: the local web exporter reports `exportSimpleProject` undefined; Android stops because Creator's configured NDK path does not exist. Check Creator's native SDK/NDK preferences before rerunning. No APK/IPA was produced, and device Replay/ingestion remains unverified.
