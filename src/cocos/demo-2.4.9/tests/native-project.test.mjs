import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { patchNative, addIosSources } from '../scripts/native-project.mjs';

const pbx = `/* Begin PBXBuildFile section */
AAAAAAAAAAAAAAAAAAAAAAAA /* AppController.mm in Sources */ = {isa = PBXBuildFile; fileRef = BBBBBBBBBBBBBBBBBBBBBBBB /* AppController.mm */; };
/* End PBXBuildFile section */
/* Begin PBXFileReference section */
BBBBBBBBBBBBBBBBBBBBBBBB /* AppController.mm */ = {isa = PBXFileReference; path = AppController.mm; };
/* End PBXFileReference section */
IOS_GROUP = { children = (
BBBBBBBBBBBBBBBBBBBBBBBB /* AppController.mm */,
); };
IOS_PHASE = { files = (
AAAAAAAAAAAAAAAAAAAAAAAA /* AppController.mm in Sources */,
); };`;

test('Creator 2 native integration survives regeneration and does not duplicate host/plugin/source entries', () => {
  const root = mkdtempSync(path.join(tmpdir(), 'cocos249-native-'));
  const put = (relative, content) => { const file = path.join(root, relative); mkdirSync(path.dirname(file), {recursive:true}); writeFileSync(file, content); };
  const read = relative => readFileSync(path.join(root, relative), 'utf8');
  const android = 'frameworks/runtime-src/proj.android-studio';
  const ios = 'frameworks/runtime-src/proj.ios_mac';
  try {
    put(`${android}/app/AndroidManifest.xml`, '<manifest><application><activity android:name="org.cocos2dx.javascript.AppActivity" android:screenOrientation="portrait"><intent-filter /></activity></application></manifest>');
    put(`${android}/build.gradle`, "buildscript { dependencies { classpath 'com.android.tools.build:gradle:4.2.2' } }");
    put(`${android}/app/build.gradle`, "apply plugin: 'com.android.application'\narguments '-j' + Runtime.runtime.availableProcessors()\n/* COCOS_SDK_BEGIN */ SDK_BRIDGE /* COCOS_SDK_END */");
    put(`${android}/gradle.properties`, 'PROP_COMPILE_SDK_VERSION=30\nPROP_TARGET_SDK_VERSION=30\norg.gradle.jvmargs=-Xmx4096m\n');
    put(`${android}/jni/CocosAndroid.mk`, 'LOCAL_MODULE := cocos2djs\ninclude $(BUILD_SHARED_LIBRARY)\n');
    put('frameworks/runtime-src/Classes/AppDelegate.cpp', 'jsb_enable_debugger("0.0.0.0", 6086, false);');
    patchNative(root, 'android');
    const files = [`${android}/app/AndroidManifest.xml`, `${android}/app/build.gradle`, `${android}/build.gradle`, `${android}/jni/CocosAndroid.mk`, `${android}/app/proguard-rules.pro`, `${android}/gradle.properties`];
    const first = files.map(read); patchNative(root, 'android'); assert.deepEqual(files.map(read), first);
    assert.match(read('frameworks/runtime-src/Classes/AppDelegate.cpp'), /jsb_enable_debugger\("0.0.0.0", 6087, false\)/);
    assert.match(first[0], /NativeSdkApplication/); assert.match(first[0], /NativeCocosActivity/); assert.match(first[0], /NativeGameActivity/);
    assert.match(first[1], /arguments '-j2'/); assert.match(first[1], /SDK_BRIDGE/); assert.match(first[1], /instrumentHttpURLConnection = true/);
    assert.match(first[2], /ft-plugin:1.3.9-alpha01/); assert.match(first[3], /max-page-size=16384/);
    assert.match(read(`${android}/app/src/com/guance/cocos/demo/NativeGameBridge.java`), /Cocos2dxActivity.getContext\(\)/);
    assert.match(read(`${android}/app/src/com/guance/cocos/demo/NativeCocosActivity.java`), /org.cocos2dx.javascript.AppActivity/);
    assert.match(read(`${android}/gradle.properties`), /PROP_COMPILE_SDK_VERSION=34/);
    put(`${ios}/ios/AppController.mm`, '@implementation AppController\n- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options { window = [[UIWindow alloc] initWithFrame:bounds]; startCocos(); return YES; }\n@end');
    put(`${ios}/ios/Info.plist`, '<plist><dict></dict></plist>');
    put(`${ios}/ios/main.m`, 'UIApplicationMain(argc, argv, nil, @"AppController");');
    put(`${ios}/Demo.xcodeproj/project.pbxproj`, pbx);
    patchNative(root, 'ios');
    const iosFiles = [`${ios}/ios/AppController.mm`, `${ios}/ios/Info.plist`, `${ios}/Demo.xcodeproj/project.pbxproj`];
    const iosFirst = iosFiles.map(read); patchNative(root, 'ios'); assert.deepEqual(iosFiles.map(read), iosFirst);
    assert.ok(iosFirst[0].indexOf('[GCNativeTelemetry boot];') < iosFirst[0].indexOf('startCocos();'));
    assert.match(iosFirst[1], /NSAppTransportSecurity/);
    for (const orientation of ['Portrait', 'LandscapeLeft', 'LandscapeRight']) assert.ok(iosFirst[1].includes('UIInterfaceOrientation' + orientation));
    assert.match(first[0], /android:screenOrientation="portrait"/);
    assert.match(iosFirst[1], /UIApplicationSceneManifest/);
    assert.match(iosFirst[1], /UISceneDelegateClassName<\/key><string>GCSceneDelegate<\/string>/);
    const [processLaunch, sceneStartup] = iosFirst[0].split('- (void)gcConnectWindowScene:');
    assert.match(processLaunch, /self.gcLaunchOptions = options/);
    assert.doesNotMatch(processLaunch, /startCocos\(\)|UIWindow alloc/);
    assert.match(sceneStartup, /initWithWindowScene:scene/);
    assert.match(read(`${ios}/ios/main.m`), /UIApplicationMain.*@"GCCocosApplication"/);
    assert.ok(processLaunch.includes('[GCNativeTelemetry boot];'));
    assert.match(iosFirst[2], /GCSceneDelegate\.mm in Sources/);
    const scene=read(`${ios}/ios/GCSceneDelegate.mm`);
    assert.equal(scene,readFileSync(new URL('../platforms/ios/GCSceneDelegate.mm',import.meta.url),'utf8'));
    assert.match(scene,/didUpdateEffectiveGeometry:/); assert.match(scene,/didUpdateCoordinateSpace:/);
    assert.match(scene,/app->updateViewSize\(width, height\)/);

    assert.match(iosFirst[2], /COMPILER_FLAGS = "-fobjc-arc"/);
    assert.match(read(`${ios}/ios/GCNativeGameBridge.mm`), /GCNativeGameController : UIViewController/);
    put(`${ios}/Demo.xcodeproj/project.pbxproj`, pbx); patchNative(root, 'ios'); assert.equal(read(iosFiles[2]), iosFirst[2]);
  } finally { rmSync(root, { recursive:true, force:true }); }
});

test('Xcode integration rejects an unknown template instead of producing an unlinked host', () => {
  assert.throws(() => addIosSources(''), /Missing AppController/);
});

test('bridge paths follow AppController and repair previously generated root-relative paths', () => {
  const linked = addIosSources(pbx.replace('path = AppController.mm;', 'path = ios/AppController.mm;'));
  assert.match(linked, /path = "ios\/GCNativeTelemetry\.mm"/);
  assert.match(linked, /path = "ios\/GCNativeGameBridge\.mm"/);
  const broken = linked.replaceAll('path = "ios/GCNative', 'path = "GCNative');
  assert.equal(addIosSources(broken), linked);
  assert.equal(addIosSources(linked), linked);
});
