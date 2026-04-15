# FT SDK HarmonyOS Demo

HarmonyOS demo app for Guance FT SDK integration. The project demonstrates RUM, logging, tracing, WebView monitoring, native crash collection, and OpenTelemetry linkage in a real ArkTS application.

## Overview

This demo currently uses:

- `@guancecloud/ft_sdk`
- `@guancecloud/ft_sdk_ext`
- `@guancecloud/ft_native`
- local `libs/otel_sdk.har`
- `@ohos/axios@2.2.8`

## What This Demo Covers

- Automatic FT SDK initialization in [`entry/src/main/ets/entryability/EntryAbility.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/entryability/EntryAbility.ets)
- RUM setup for view, action, resource, WebView, crash, ANR, UI block, and device metrics in [`entry/src/main/ets/manager/FTSDKManager.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/manager/FTSDKManager.ets)
- Login flow plus RUM user binding in [`entry/src/main/ets/manager/AccountManager.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/manager/AccountManager.ets)
- Native test actions for custom view/action/error/log/global context/network/OTEL in [`entry/src/main/ets/pages/NativePage.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/pages/NativePage.ets)
- WebView RUM bridge demo in [`entry/src/main/ets/pages/WebViewPage.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/pages/WebViewPage.ets)
- Runtime configuration editing, connectivity checks, and import via `gc-demo://` in [`entry/src/main/ets/pages/SettingPage.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/pages/SettingPage.ets)

## Pages

- `LoginPage`: login entry, page/action tracking, settings entry
- `MainPage`: bottom tabs for Home and Mine
- `HomePage`: feature navigation
- `NativePage`: native FT SDK capability demonstrations
- `WebViewPage`: WebView RUM injection and page loading demo
- `MinePage`: user info refresh, config entry, version display, logout
- `SettingPage`: DataKit/DataWay configuration, Demo API config, OTEL config, connection test, config import

## Prerequisites

- DevEco Studio with HarmonyOS SDK `6.0.0(20)` available
- `ohpm`
- A reachable Demo API service
- One of:
  - DataKit endpoint
  - DataWay endpoint + client token
- Valid Guance HarmonyOS App ID

## Install Dependencies

From the project root:

```bash
ohpm install
```

Module dependencies are declared in [`entry/oh-package.json5`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/oh-package.json5).

## Runtime Configuration

The app supports two access modes:

- `DataKit`: configure `datakitAddress`
- `DataWay`: configure `datawayAddress` and `datawayClientToken`

Common required fields:

- `appId`
- `demoApiAddress`

Optional field:

- `otelAddress`

Settings are persisted through [`SettingConfigManager.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/manager/SettingConfigManager.ets).

Current defaults in code are intentionally mostly empty, so first launch usually requires manual configuration.

### Default Login Credentials

The login page currently pre-fills:

- Username: `guance`
- Password: `admin`

These values come from [`entry/src/main/ets/constants/Constant.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/constants/Constant.ets).

## Configuration Import

`SettingPage` supports importing a base64 JSON payload with the `gc-demo://` prefix.

Format:

```text
gc-demo://<base64-json>
```

Supported JSON fields:

```json
{
  "demoHarmonyOSAppId": "your_app_id",
  "demoApiAddress": "https://demo.example.com",
  "datakitAddress": "http://127.0.0.1:9529",
  "datawayAddress": "https://rum-openway.guance.com",
  "datawayClientToken": "your_client_token",
  "otelAddress": "http://127.0.0.1:4318/v1/traces"
}
```

Behavior:

- If `datakitAddress` exists, the page switches to `DataKit`
- Otherwise, if both `datawayAddress` and `datawayClientToken` exist, it switches to `DataWay`
- Imported values are only applied to the form until you tap `Save`

## Launch Parameters

`EntryAbility` can seed initial configuration from `want.parameters` before the SDK starts. It only writes values that are not already stored in preferences.

Supported parameter names:

- `datakitUrl`
- `datawayUrl`
- `clientToken`
- `appId`
- `otelAddress`
- `demoApiUrl`
- `accessType`

Code reference: [`entry/src/main/ets/entryability/EntryAbility.ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets/entryability/EntryAbility.ets)

## Build And Run

This is the easiest way to run the demo:

1. Open this `demo` directory in DevEco Studio.
2. Run `Sync and Refresh Project`.
3. Build and launch on a phone device.

## Test And Validation

Existing test directories:

- `entry/src/test`
- `entry/src/ohosTest`

For this demo, the most meaningful validation path is:

1. Open settings and save valid DataKit or DataWay configuration.
2. Verify `Test Connection` succeeds.
3. Log in and enter `Native View`.
4. Trigger custom action, error, log, network, and OTEL examples.
5. Open `WebView` and confirm page loading plus WebView tracking.

## Notes About Current Implementation

- Session Replay fields are persisted in the settings model, but the current `SettingPage` UI does not expose corresponding controls.
- `FTSDKManager` always enables debug mode and full sampling in the current demo.
- OTEL initialization is skipped when `otelAddress` is empty.
- Native crash simulation is implemented through the C++ bridge under [`entry/src/main/cpp`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/cpp).

## Troubleshooting

### Save Fails Or Connection Test Fails

- `appId` must not be empty
- `demoApiAddress` must be a valid `http://` or `https://` URL
- `datakitAddress` must be valid in `DataKit` mode
- `datawayAddress` and `datawayClientToken` must both be valid in `DataWay` mode

### No Data In Guance

- Confirm the selected mode matches your actual endpoint
- Confirm the App ID belongs to the target workspace
- Confirm the Demo API is reachable from the device
- Check device logs because demo code enables FT SDK debug mode

### WebView Page Is Blank

- Confirm `demoApiAddress` is set
- Confirm the Demo API root page is reachable in a mobile WebView
- Confirm the derived `requestUrl` endpoint is also reachable

## Support

- Guance docs: [https://docs.guance.com/real-user-monitoring/harmonyos/app-access/](https://docs.guance.com/real-user-monitoring/harmonyos/app-access/)
- HarmonyOS FT SDK related code in this demo: [`entry/src/main/ets`](/Users/Brandon/Documents/workplace/working/StudioPlace/ft-sdk-app-demo/src/harmonyos/demo/entry/src/main/ets)
