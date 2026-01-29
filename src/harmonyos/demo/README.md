# FT SDK HarmonyOS Demo Application

This is a comprehensive demo application showcasing the integration of **FT SDK (Guance Observation SDK)** for HarmonyOS platform. The application demonstrates various monitoring and observability features including Real User Monitoring (RUM), Logging, Tracing, and more.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Application Pages](#application-pages)
- [SDK Integration Guide](#sdk-integration-guide)
- [Configuration Import](#configuration-import)
- [Building and Running](#building-and-running)
- [Dependencies](#dependencies)
- [Version](#version)

## Overview

This demo application integrates the **FT SDK for HarmonyOS** to demonstrate observability capabilities including:

- **Real User Monitoring (RUM)** - Track user interactions, page views, and application performance
- **Logging** - Capture and send logs with different severity levels
- **Tracing** - Distributed tracing for network requests and operations
- **WebView Monitoring** - RUM data collection within web content
- **Crash & ANR Reporting** - Automatic crash and Application Not Responding detection
- **Long Task Monitoring** - UI block detection and tracking

## Features

### RUM (Real User Monitoring)

- **View Tracking** - Automatic page view monitoring
- **Action Tracking** - User interaction tracking (taps, clicks, swipes)
- **Error Tracking** - Custom error reporting with stack traces
- **Resource Tracking** - Network request monitoring
- **Long Task Detection** - UI block detection
- **Device Metrics** - CPU, memory, and battery monitoring

### Logging

- Multiple log levels (DEBUG, INFO, WARN, ERROR)
- Custom log properties
- Console log capture
- Automatic log flushing

### Tracing

- Automatic network request tracing
- Custom span creation
- RUM data linkage

### WebView Support

- JavaScript injection for web content monitoring
- Seamless integration with native RUM

### Additional Features

- Configuration import via custom URI scheme (`gc-demo://`)
- Connection testing for DataKit/DataWay
- User authentication flow
- Settings persistence

## Project Structure

```
demo/
├── AppScope/                    # Application-level resources
├── entry/                       # Main entry module
│   ├── src/main/ets/
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets # Application entry point & SDK initialization
│   │   ├── pages/
│   │   │   ├── Index.ets        # Index page
│   │   │   ├── LoginPage.ets    # Login screen
│   │   │   ├── MainPage.ets     # Main page with bottom navigation
│   │   │   ├── HomePage.ets     # Home feature list
│   │   │   ├── MinePage.ets     # User profile page
│   │   │   ├── NativePage.ets   # Native demo features
│   │   │   ├── WebViewPage.ets  # WebView monitoring demo
│   │   │   └── SettingPage.ets  # Configuration settings
│   │   ├── manager/             # Business logic managers
│   │   ├── model/               # Data models
│   │   ├── constants/           # Constants and enums
│   │   ├── utils/               # Utility functions
│   │   └── http/                # Network layer
│   ├── libs/
│   │   └── ft_sdk.har          # FT SDK HarmonyOS library
│   └── build-profile.json5     # Module build configuration
├── build-profile.json5         # Project build configuration
├── oh-package.json5            # Project dependencies
└── hvigor/                     # Build tool configuration
```

## Getting Started

### Prerequisites

- **DevEco Studio** 5.0.0 or later
- **HarmonyOS SDK** API 12+ (5.0.0)
- **Node.js** and hvigorw build tool
- Valid DataKit or DataWay endpoint
- Guance workspace with Application ID

### Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd ft-sdk-app-demo/src/harmonyos/demo
```

2. Install dependencies:
```bash
ohpm install
```

3. Open the project in DevEco Studio

4. Place the `ft_sdk.har` library in the `entry/libs/` directory

## Configuration

### Access Types

The application supports two data access modes:

#### 1. DataKit (Local Deployment)
- Direct connection to a local DataKit instance
- Suitable for on-premise deployments
- Requires DataKit server address

#### 2. DataWay (Public Cloud)
- Connection to Guance public DataWay
- Requires DataWay URL and Client Token
- No local infrastructure needed

### Required Configuration

| Parameter | Description | Example |
|-----------|-------------|---------|
| `datakitAddress` | DataKit server URL | `http://192.168.1.100:9529` |
| `datawayAddress` | DataWay URL | `https://openway.guance.com` |
| `datawayClientToken` | DataWay authentication token | `tkn_xxxxxxxxxxxx` |
| `appId` | Guance Application ID | `harmonyos_xxxxxxxxxxxxx` |
| `demoAPIAddress` | Demo backend API | `https://demo-api.example.com` |
| `otelAddress` | Optional OTel endpoint | `https://otel.example.com` |

### Initial Setup

1. Launch the application
2. Click **"Edit Settings"** on the login page
3. Select access type (DataKit or DataWay)
4. Fill in required configuration fields
5. Click **"Test Connection"** to verify
6. Click **"Save"** to apply settings

## Application Pages

### LoginPage
Entry point of the application with user authentication.

- Default credentials:
  - Username: `ft_user`
  - Password: `123456`
- RUM view tracking
- Login action tracking
- Settings configuration access

### MainPage
Main interface with bottom navigation bar.

- Two tabs: **Home** and **Mine**
- Tab switching action tracking
- Login status verification

### HomePage
Feature demonstration menu.

- **Native View** - Navigate to native monitoring demos
- **WebView** - Navigate to WebView monitoring demos
- Menu item click tracking

### NativePage
Comprehensive native feature demonstrations.

#### RUM View Test
- Custom view tracking with properties

#### RUM Action Test
- Add custom actions
- Action start/stop duration tracking

#### RUM Error Test
- Add custom errors with stack traces
- Crash simulation for testing error handling

#### RUM LongTask Test
- UI block simulation
- Long task detection and reporting

#### Log Test
- Add logs at different levels (INFO, WARN, ERROR, DEBUG)
- Custom log properties

#### Global Tag Test
- Add global context tags
- RUM global context

#### Network Request Test
- Send HTTP requests with automatic RUM tracking
- Uses RCP (Remote Communication Kit) with auto-instrumentation

### WebViewPage
WebView monitoring demonstration.

- Automatic RUM data injection
- JavaScript bridge for web content monitoring
- Page load tracking
- Error handling

### MinePage
User profile and application settings.

- User information display
- Manual refresh functionality
- Configuration management
- Version information
- Logout functionality

### SettingPage
Application configuration interface.

- Access type selection (DataKit/DataWay)
- DataKit/DataWay configuration
- Application ID settings
- Demo API configuration
- OTel endpoint (optional)
- Connection testing
- Configuration import via clipboard

## SDK Integration Guide

### 1. Dependency Setup

Add to `entry/oh-package.json5`:
```json5
{
  "dependencies": {
    "ft_sdk": "file:../libs/ft_sdk.har"
  }
}
```

### 2. SDK Initialization

In `EntryAbility.ets`:

```typescript
import { FTSDK } from 'ft_sdk/src/main/ets/components/FTSDK';
import { FTSDKConfig, FTRUMConfig, FTLoggerConfig, FTTraceConfig } from 'ft_sdk/src/main/ets/components/Configs';

// Configure SDK
const sdkConfig = FTSDKConfig.builder(datakitAddress)
  .setServiceName('ft-sdk-demo-harmonyos')
  .setDebug(true)
  .setEnv(EnvType.PROD)
  .setAutoSync(true);

await FTSDK.install(sdkConfig, this.context);
```

### 3. RUM Configuration

```typescript
const rumConfig = new FTRUMConfig()
  .setRumAppId(appId)
  .setSamplingRate(1.0)
  .setEnableTraceUserAction(true)
  .setEnableTraceUserView(true)
  .setEnableTrackAppCrash(true)
  .setEnableTrackAppANR(true);

await FTSDK.installRUMConfig(rumConfig);
```

### 4. Logger Configuration

```typescript
const logConfig = new FTLoggerConfig()
  .setSamplingRate(1.0)
  .setEnableCustomLog(true)
  .setEnableConsoleLog(true);

FTSDK.installLogConfig(logConfig);
```

### 5. Using RUM Global Manager

```typescript
import { FTRUMGlobalManager } from 'ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';

// View tracking
FTRUMGlobalManager.getInstance().startView('PageName');

// Action tracking
FTRUMGlobalManager.getInstance().addAction('button_click', 'tap');

// Error tracking
FTRUMGlobalManager.getInstance().addError(
  stackTrace,
  message,
  ErrorType.CUSTOM,
  AppState.RUN
);
```

### 6. Logging

```typescript
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';

FTLogger.logBackground('User logged in', Status.INFO);
FTLogger.logBackground('API request failed', Status.ERROR);
```

## Configuration Import

The application supports importing configuration via a custom URI scheme.

### Format

```
gc-demo://<base64_encoded_json>
```

### JSON Structure (before base64 encoding)

```json
{
  "demoApiAddress": "https://demo-api.example.com",
  "demoHarmonyOSAppId": "harmonyos_xxxxxxxxxxxxx",
  "datakitAddress": "http://192.168.1.100:9529",
  "datawayAddress": "https://openway.guance.com",
  "datawayClientToken": "tkn_xxxxxxxxxxxx",
  "otelAddress": "https://otel.example.com"
}
```

### How to Import

1. Copy the configuration string (`gc-demo://...`)
2. Open **SettingPage** in the app
3. Click **"Import Configuration"**
4. Paste the configuration string
5. Click **"Confirm"**
6. Verify and save the imported settings

## Building and Running

### Debug Build

```bash
hvigorw clean
hvigorw assembleHap --mode module -p module=entry@default -p product=default
```

### Release Build

```bash
hvigorw assembleHap --mode module -p module=entry@default -p product=default --daemon
```

### Running on Device/Emulator

1. Connect a HarmonyOS device or start an emulator
2. Click **Run** in DevEco Studio
3. Or use command line:
```bash
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

## Dependencies

| Dependency | Version | Description |
|------------|---------|-------------|
| ft_sdk | 1.2.13 | Guance Observation SDK for HarmonyOS |
| @ohos/hypium | 1.0.24 | Testing framework |
| @ohos/hamock | 1.0.0 | Mocking framework |

## SDK Configuration Reference

### FTSDKConfig

| Method | Description | Default |
|--------|-------------|---------|
| `builder(address)` | Create config with DataKit address | - |
| `builder(address, token)` | Create config with DataWay address and token | - |
| `setServiceName()` | Set service name | - |
| `setDebug()` | Enable debug logging | `false` |
| `setEnv()` | Set environment (PROD/STAGING/COMMON) | `PROD` |
| `setAutoSync()` | Enable automatic data sync | `true` |
| `setSyncPageSize()` | Set sync page size | `SMALL` |
| `setDbCacheLimit()` | Set database cache limit (bytes) | 10MB |

### FTRUMConfig

| Method | Description | Default |
|--------|-------------|---------|
| `setRumAppId()` | Set RUM Application ID | - |
| `setSamplingRate()` | Set RUM sampling rate (0.0-1.0) | `1.0` |
| `setEnableTraceUserAction()` | Enable user action tracking | `true` |
| `setEnableTraceUserView()` | Enable view tracking | `true` |
| `setEnableTrackAppCrash()` | Enable crash tracking | `true` |
| `setEnableTrackAppANR()` | Enable ANR tracking | `true` |
| `setEnableTrackAppUIBlock()` | Enable UI block tracking | `true` |
| `setEnableTraceWebView()` | Enable WebView monitoring | `true` |

### FTLoggerConfig

| Method | Description | Default |
|--------|-------------|---------|
| `setSamplingRate()` | Set log sampling rate | `1.0` |
| `setEnableCustomLog()` | Enable custom logging | `true` |
| `setEnableConsoleLog()` | Enable console log capture | `false` |
| `setLogLevelFilters()` | Set log level filters | All levels |

## Troubleshooting

### Connection Issues

1. Verify DataKit/DataWay addresses are correct
2. Check network connectivity
3. Ensure firewall allows outbound connections
4. Verify client token (for DataWay)

### Data Not Appearing

1. Check Application ID matches workspace
2. Verify sampling rates are not too low
3. Check debug logs for errors
4. Ensure `setAutoSync(true)` is set

### WebView Not Working

1. Verify RUM config is set before WebView loads
2. Check JavaScript is enabled in WebView
3. Ensure FTWebViewHandler is properly configured

## Version

**Application Version:** 1.2.13 (21)
**Target SDK:** HarmonyOS 6.0.0 (API 20)
**Minimum SDK:** HarmonyOS 5.0.0 (API 12)
**FT SDK Version:** 1.2.13

## License

Please refer to the main project license file.

## Support

For issues related to:
- **FT SDK**: Contact Guance support or visit [Guance Documentation](https://docs.guance.com/)
- **Demo Application**: Create an issue in this repository
