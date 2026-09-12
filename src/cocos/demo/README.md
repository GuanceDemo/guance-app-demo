# Guance Cocos Demo

Cocos Creator **3.8.8** 工程，Android / iOS 共用一套 TypeScript 页面、配置与业务接口。SDK 通过 npm 安装，不依赖机器上的 `ft-sdk-cocos` 源码目录。

## 安装和打开

```sh
cd src/cocos/demo
npm run setup
```

`npm ci` 按已提交的 lockfile 安装 `@cloudcare/cocos-sdk@0.1.0-alpha.6` 和 `@cloudcare/cocos-session-replay@0.1.0-alpha.6`，随后安装 Creator 3 原生构建扩展及隐私组件。升级时两个包必须使用同一精确版本。

在 **Creator 3.8.8** 中打开本目录，入口场景是 `assets/scenes/Demo.scene`。首次安装扩展后重新打开 Creator。`library`、`temp`、`native`、`extensions`、构建产物与凭据均不提交；用 `npm run setup` 恢复 SDK 扩展。

## 配置读取

从首页或“我的”进入“编辑 Demo 配置”。支持手填、粘贴 JSON，或使用服务端 `/import_helper` 生成的原有协议：

```text
gc-demo://<UTF-8 JSON 的 Base64>
```

```json
{
  "demoAndroidAppId": "existing-android-app-id",
  "demoIOSAppId": "existing-ios-app-id",
  "demoCocosAndroidAppId": "cocos-android-app-id",
  "demoCocosIOSAppId": "cocos-ios-app-id",
  "demoApiAddress": "https://demo.example.com",
  "datakitAddress": "http://192.168.1.2:9529",
  "enableSessionReplay": true
}
```

- 可选的 `demoCocosAndroidAppId` / `demoCocosIOSAppId` 优先于原生 App ID；未填写时复用原有字段，因此已有配置串仍可直接导入。
- DataWay 配置使用 `datawayAddress` + `datawayClientToken`，不填 `datakitAddress`。与其他 Demo 一致，同时提供两种入口时优先 DataKit。
- 导入仅回填表单，点击保存后写入 `sys.localStorage`；启动时读取同一配置。当前设备只要求自己的平台 App ID。
- 首次保存会启动 SDK；已启动后更改配置需彻底关闭并重新打开 App，避免原生 SDK 重复初始化。保存未生效前仍使用原配置。
- 地址检查复用 `/connect`、DataKit `/v1/ping` 和 DataWay `/v1/write/logging?...&to_headless=true`。DataWay 检查与其他 Demo 一样发送一条 `connect test` 日志。检查请求绕过自动 RUM/Trace 采集。
- 设置页、账号/密码、个人信息和回放隐私输入均做 Cocos Replay 遮罩，Token 不写入日志。配置保存在设备应用存储中，设备卸载会清除。

真机请填写可访问的局域网或公网地址。Android 模拟器的 `127.0.0.1` 指模拟器自身；访问宿主机可用 `10.0.2.2` 或 `adb reverse`。工程保留 HTTP 访问能力以兼容现有局域网 Demo API / DataKit。

## 场景

| 分类 | 场景 | 预期行为 |
| --- | --- | --- |
| 真实 | 登录 / 退出 | POST `/api/login`，成功后绑定 RUM 用户，退出时解绑；测试账号 `guance` / `admin` |
| 真实 | 商品列表 | GET `/api/products`、远程图片、滚动、刷新、加载/空/失败状态 |
| 真实 | 商品详情 | GET `/api/products/:id`、收藏、加入购物车、详情重试 |
| 真实 | 演示购物车 | 本地增减数量与 Action；不创建服务端订单或付款 |
| 真实 | 我的 | GET `/api/user`、刷新资料、配置入口、退出 |
| 真实 / 实验 | H5 | 原生 WebView 打开现有首页或商品 H5，提供返回与加载反馈 |
| 实验 | View / Action | 独立业务 View；进入 startView、离开 stopView；自定义 Action |
| 实验 | Log | info / warning / error / critical / ok，关联当前 RUM |
| 实验 | Error | 手动捕获异常、异步未捕获 JS 异常 |
| 实验 | LongTask | 有上限的约 250ms JS 忙任务，测量后按纳秒上报 |
| 实验 | 网络 | 自动成功请求、HTTP 404、手动 Resource + ddTrace Headers |
| 实验 | Replay | 持续运动、公开文字、测试隐私遮罩、暂停/恢复 |

Cocos 单场景中由应用为业务页面命名 View 和 Action；XHR 自动采集 Resource/Trace，关闭原生自动 View/Action/Resource 和原生自动 Trace，防止同一请求重复采集。手动网络实验使用初始化前保存的 XHR 方法，且 Resource 与 Trace 共用一个 key。网络请求离开页面时取消，过期响应不会修改新页面。

原生 Crash、Android ANR、UI Block 采集已配置开启；实验区的 JS 异常与 LongTask 不等同于原生崩溃/ANR 注入。浏览器仅用于界面和业务流程预览，SDK 上报需要 Android / iOS 原生构建。

原生 WebView 为覆盖层，不在 Cocos 相机 Replay 捕获范围；H5 数据由仓库已有页面中的 Web SDK 控制，本 Demo 不额外实现 WebView JS Bridge。Trace 服务端数据需要现有 Demo Server 通过 `ddtrace-run` 接入相同工作空间。按钮显示“已调用”或 HTTP 成功并不证明服务端已入库。

## 构建与验证

macOS 默认使用 `/Applications/Cocos/Creator/3.8.8/CocosCreator.app/Contents/MacOS/CocosCreator`，其他位置通过环境变量 `COCOS_CREATOR` 指定 **3.8.8** 可执行文件。

```sh
npm test
npm run build:preview
npm run typecheck
npm run build:android
npm run build:ios
```

脚本使用 [Creator 命令行构建](https://docs.cocos.com/creator/3.8/manual/en/editor/publish/publish-in-command-line.html)，识别成功退出码 36，并应用 Demo 的原生 HTTP/版本配置。Creator 会生成类型声明，随后 `typecheck` 使用引擎真实声明和 npm SDK 类型检查业务代码。

构建脚本生成工程，不自动启动虚拟设备：

- Android：用 Android Studio 打开 `build/android/proj`，或在其中执行 `./gradlew --no-daemon --max-workers=2 assembleDebug`。APK 位于 `build/android/proj/build/GuanceCocosDemo/outputs/apk/debug/`。
- iOS：在 `build/ios/proj` 执行 `pod install`，打开 `GuanceCocosDemo.xcworkspace`，选择 `GuanceCocosDemo-mobile` scheme。npm 扩展管理 `GuanceSDK/Agent` 和 Replay 的原生依赖。
- 本机 Xcode 26 对 Creator 3.8.8 内置 Enoki 的 `std` 类型特化报错；构建脚本仅对 Demo 的 `cocos_engine` target 在 AppleClang 17+ 下添加 `-Wno-invalid-specialization`，不修改 Creator 安装目录。
- 若直接在 Creator 构建面板操作，最后运行相应 `npm run build:*`，保证脚本中的 Demo 配置补丁得到应用。
- **Android 模拟器与 iOS 模拟器禁止同时运行。** 切换平台前彻底关闭另一端。原生编译建议限制并行度为 2，避免 16GB 主机耗尽内存。

## 后续 OSS / TestFlight 分发

`release:*` 只准备本地分发产物，不上传。签名通过环境变量读取，账号和密码不写进仓库。

Android：设置 `DEMO_VERSION`（如 `1.0.0`）、递增的 `DEMO_BUILD_NUMBER`、最终 `DEMO_PACKAGE_NAME`，以及 `ANDROID_KEYSTORE_PATH`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`，然后：

```sh
npm run release:android
```

脚本重建 Release JS，使用指定 keystore 签名，输出 `artifacts/android/<版本>-<构建号>/guance_cocos_demo.apk`、SHA-256、`release.json` 和可用的 R8 mapping。保留对应 `build/android/proj/build` 中的未剥离 native symbols 与 JS source maps。以后将 APK 上传到指定 OSS 路径即可，不能将 debug APK 当作正式分发包。

iOS：设置相同的版本/构建号/最终 Bundle ID，以及 `APPLE_TEAM_ID`、`IOS_EXPORT_OPTIONS`（本机 App Store Connect 导出选项 plist 路径）；如需变更 scheme 可设置 `IOS_SCHEME`。确保本机已有对应分发证书和 provisioning profile，然后：

```sh
npm run release:ios
```

脚本重建 Release JS、安装 Pods、Archive、Export，输出 `.xcarchive`（含 dSYM）、IPA、SHA-256 和 `release.json`。导出 plist 必须使用 `destination=export`，以便先在本地审查产物；之后使用 Xcode Organizer 或 Transporter 上传 App Store Connect，并在 TestFlight 配置测试组。App Store Connect 记录、最终签名与上传凭据由后续分发阶段提供。

## 验收路径

1. 两端分别导入 DataKit / DataWay 配置，检查连接并重启，确认持久化和平台 App ID。
2. 登录 → 商品列表 → 图片加载 → 详情 → 收藏/购物车 → H5 → 个人信息 → 退出；核对 View、Action、Resource 与用户关联。
3. 依次操作实验区，核对日志等级、Error、LongTask 纳秒单位、每个 XHR 只有一条 Resource，以及服务端 Trace 关联。
4. 对比 Replay 动画和实时画面，检查隐私遮罩、输入内容、暂停/恢复；原生 WebView 层不纳入此项。
5. 模拟断网、请求超时、错误账号及离页取消，确认失败反馈与重试。签名分发前在 Android/iOS 真机重复验证。
