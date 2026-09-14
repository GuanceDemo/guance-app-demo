import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const platforms = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../platforms');

// Matches the Cocos SDK Hybrid host's Android Agent 1.7.6-alpha03 pairing.
const ftPluginVersion = '1.3.9-alpha01';

function patchAndroidPlugin(root) {
  const begin = '// DEMO_FT_PLUGIN_BEGIN';
  const end = '// DEMO_FT_PLUGIN_END';
  const marked = /\/\/ DEMO_FT_PLUGIN_BEGIN[\s\S]*?\/\/ DEMO_FT_PLUGIN_END/g;
  const classpath = [
    begin,
    'repositories {',
    "    maven { url 'https://mvnrepo.guance.com/repository/maven-releases' }",
    '}',
    'dependencies {',
    `    classpath 'com.cloudcare.ft.mobile.sdk.tracker.plugin:ft-plugin:${ftPluginVersion}'`,
    '}',
    end,
  ].join('\n');
  // Creator's build entry point and native template each have a buildscript scope.
  for (const relative of ['build/android/proj/build.gradle', 'native/engine/android/build.gradle']) {
    const file = path.join(root, relative);
    const source = readFileSync(file, 'utf8');
    if (!/buildscript\s*\{/.test(source)) throw new Error(`Missing Android buildscript block: ${file}`);
    const next = source.includes(begin)
      ? source.replace(marked, classpath)
      : source.replace(/buildscript\s*\{/, (match) => `${match}\n${classpath}\n`);
    writeFileSync(file, next);
  }
  const app = path.join(root, 'native/engine/android/app/build.gradle');
  const source = readFileSync(app, 'utf8');
  const plugin = [
    begin,
    "apply plugin: 'ft-plugin'",
    'FTExt {',
    '    showLog = true',
    '    instrumentHttpURLConnection = true',
    '}',
    end,
  ].join('\n');
  writeFileSync(app, source.includes(begin) ? source.replace(marked, plugin) : `${source}\n${plugin}\n`);
}

/** Apply app-owned native settings and Android instrumentation. SDK linking is owned by its npm extension. */
export function patchNative(root, platform, metadata = {}) {
  if (platform === 'android') {
    patchAndroidPlugin(root);
    const cmakePath = path.join(root, 'native/engine/android/CMakeLists.txt');
    let cmake = readFileSync(cmakePath, 'utf8');
    if (!/add_library\(\s*\$\{CC_LIB_NAME\}\s+SHARED\b/.test(cmake)) throw new Error(`Missing Cocos shared library target: ${cmakePath}`);
    if (!cmake.includes('# DEMO_ANDROID_16KB')) {
      // Creator's NDK 22 needs both flags for LOAD alignment and the GNU_RELRO end.
      // LINK_FLAGS also works with the template's CMake 3.8 minimum version.
      cmake += '\n# DEMO_ANDROID_16KB\n'
        + 'set_property(TARGET ${CC_LIB_NAME} APPEND_STRING PROPERTY LINK_FLAGS\n'
        + '    " -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384")\n';
      writeFileSync(cmakePath, cmake);
    }
    const manifest = path.join(root, 'native/engine/android/app/AndroidManifest.xml');
    if (!existsSync(manifest)) throw new Error(`Missing generated Android manifest: ${manifest}`);
    let value = readFileSync(manifest, 'utf8');
    value = value.replace(/<application\b[^>]*>/, tag => {
      if (/android:name="[^"]*"/.test(tag)) {
        if (!tag.includes('android:name="com.guance.cocos.demo.NativeSdkApplication"')) throw new Error('Unexpected Application class; integrate NativeTelemetry.boot into the existing host.');
        return tag;
      }
      return tag.replace('<application', '<application android:name="com.guance.cocos.demo.NativeSdkApplication"');
    });
    const host = /<activity\b[^>]*android:name="(?:com\.cocos\.game\.AppActivity|com\.guance\.cocos\.demo\.NativeCocosActivity)"[^>]*>/;
    if (!host.test(value)) throw new Error(`Missing Cocos host Activity: ${manifest}`);
    value = value.replace(host, tag => {
      tag = tag.replace('com.cocos.game.AppActivity', 'com.guance.cocos.demo.NativeCocosActivity');
      return tag.includes('android:enableOnBackInvokedCallback=')
        ? tag.replace(/android:enableOnBackInvokedCallback="[^"]*"/, 'android:enableOnBackInvokedCallback="true"')
        : tag.replace('<activity', '<activity android:enableOnBackInvokedCallback="true"');
    });
    value = value.replace(/android:usesCleartextTraffic="[^"]*"/g, 'android:usesCleartextTraffic="true"');
    if (!value.includes('android:usesCleartextTraffic')) value = value.replace('<application', '<application android:usesCleartextTraffic="true"');
    if (!value.includes('com.guance.cocos.demo.NativeGameActivity')) {
      value = value.replace(/(<application\b[^>]*?)\/>/, '$1></application>');
      value = value.replace('</application>', '<activity android:name="com.guance.cocos.demo.NativeGameActivity" android:exported="false" android:screenOrientation="portrait" android:configChanges="orientation|keyboardHidden|screenSize" android:theme="@android:style/Theme.Material.NoActionBar" />\n</application>');
    }
    writeFileSync(manifest, value);
    const java = path.join(root, 'native/engine/android/app/src/com/guance/cocos/demo');
    mkdirSync(java, { recursive: true });
    for (const name of ['NativeGameBridge.java', 'NativeGameActivity.java', 'NativeCocosActivity.java', 'NativeSdkApplication.java', 'NativeTelemetry.java']) copyFileSync(path.join(platforms, 'android', name), path.join(java, name));
    // JSB resolves these npm-provided Java classes/methods by strings, so R8 must preserve them.
    const proguard = path.join(root, 'native/engine/android/app/proguard-rules.pro');
    const rules = existsSync(proguard) ? readFileSync(proguard, 'utf8') : '';
    if (!rules.includes('# DEMO_COCOS_BRIDGE')) writeFileSync(proguard,
      rules + '\n# DEMO_COCOS_BRIDGE\n-keep class com.ft.sdk.cocos.** { *; }\n');
    const updatedRules = readFileSync(proguard, 'utf8');
    if (!updatedRules.includes('# DEMO_NATIVE_PAGES')) writeFileSync(proguard,
      updatedRules + '\n# DEMO_NATIVE_PAGES\n-keep class com.guance.cocos.demo.NativeGameBridge { *; }\n');
    const hostRules = readFileSync(proguard, 'utf8');
    if (!hostRules.includes('# DEMO_NATIVE_SDK_HOST')) writeFileSync(proguard,
      hostRules + '\n# DEMO_NATIVE_SDK_HOST\n-keep class com.guance.cocos.demo.NativeTelemetry { *; }\n');
  } else {
    const plist = path.join(root, 'native/engine/ios/Info.plist');
    if (!existsSync(plist)) throw new Error(`Missing generated iOS Info.plist: ${plist}`);
    let value = readFileSync(plist, 'utf8');
    const version = metadata.version ?? JSON.parse(readFileSync(path.join(root, 'package.json'), 'utf8')).version;
    const buildNumber = metadata.buildNumber ?? '1';
    if (!/^\d+\.\d+\.\d+$/.test(version) || !/^[1-9]\d*$/.test(buildNumber)) throw new Error('Invalid iOS version/build number.');
    value = value.replace(/(<key>CFBundleShortVersionString<\/key>\s*<string>)[^<]*(<\/string>)/, (_, before, after) => before + version + after);
    value = value.replace(/(<key>CFBundleVersion<\/key>\s*<string>)[^<]*(<\/string>)/, (_, before, after) => before + buildNumber + after);
    // This demo does not use non-exempt encryption; include the declaration for TestFlight.
    if (!value.includes('<key>ITSAppUsesNonExemptEncryption</key>')) {
      value = value.replace(/<dict>/, '<dict>\n\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>');
    }
    // Creator requires an accelerometer by default, but this demo uses touch input only.
    value = value.replace(/(<key>UIRequiredDeviceCapabilities<\/key>\s*<dict>)([\s\S]*?)(<\/dict>)/,
      (_, before, capabilities, after) => before + capabilities.replace(/\s*<key>accelerometer<\/key>\s*<(?:true|false)\s*\/>/g, '') + after);
    if (!value.includes('<key>NSAppTransportSecurity</key>')) {
      value = value.replace(/<dict>/, '<dict>\n\t<key>NSAppTransportSecurity</key>\n\t<dict><key>NSAllowsArbitraryLoads</key><true/></dict>');
    }
    if (!value.includes('<key>NSLocalNetworkUsageDescription</key>')) value = value.replace(/<dict>/,
      '<dict>\n\t<key>NSLocalNetworkUsageDescription</key><string>Connect to the configured local Demo API and DataKit collector.</string>');
    writeFileSync(plist, value);
    // Xcode generates the required iPhone/iPad sizes from Creator's existing app icon.
    const iconRoot = path.join(root, 'native/engine/ios/Images.xcassets/AppIcon.appiconset');
    if (existsSync(path.join(iconRoot, '1024.png'))) {
      writeFileSync(path.join(iconRoot, 'Contents.json'), JSON.stringify({
        images: [{ filename: '1024.png', idiom: 'universal', platform: 'ios', size: '1024x1024' }],
        info: { author: 'xcode', version: 1 }
      }, null, 2) + '\n');
    }
    const cmakePath = path.join(root, 'native/engine/ios/CMakeLists.txt');
    let cmake = readFileSync(cmakePath, 'utf8');
    copyFileSync(path.join(platforms, 'ios/GCNativeGameBridge.mm'), path.join(root, 'native/engine/ios/GCNativeGameBridge.mm'));
    for (const name of ['GCNativeTelemetry.h', 'GCNativeTelemetry.mm'])
      copyFileSync(path.join(platforms, 'ios', name), path.join(root, 'native/engine/ios', name));
    const delegatePath = path.join(root, 'native/engine/ios/AppDelegate.mm');
    let delegate = readFileSync(delegatePath, 'utf8');
    if (!delegate.includes('#import "GCNativeTelemetry.h"')) delegate = '#import "GCNativeTelemetry.h"\n' + delegate;
    if (!delegate.includes('[GCNativeTelemetry boot];')) {
      const launch = /(-\s*\(BOOL\)application:[^{]+didFinishLaunchingWithOptions:[^{]+\{)/;
      if (!launch.test(delegate)) throw new Error('Missing AppDelegate launch callback for native SDK initialization.');
      delegate = delegate.replace(launch, '$1\n    [GCNativeTelemetry boot];');
    }
    writeFileSync(delegatePath, delegate);
    if (!cmake.includes('# DEMO_NATIVE_SDK_HOST')) {
      cmake += '\n# DEMO_NATIVE_SDK_HOST\n'
        + 'target_sources(${EXECUTABLE_NAME} PRIVATE ${CMAKE_CURRENT_LIST_DIR}/GCNativeTelemetry.mm)\n'
        + 'set_source_files_properties(${CMAKE_CURRENT_LIST_DIR}/GCNativeTelemetry.mm PROPERTIES COMPILE_FLAGS "-fobjc-arc")\n';
    }
    if (!cmake.includes('# DEMO_NATIVE_PAGES')) {
      cmake += '\n# DEMO_NATIVE_PAGES\n'
        + 'target_sources(${EXECUTABLE_NAME} PRIVATE ${CMAKE_CURRENT_LIST_DIR}/GCNativeGameBridge.mm)\n'
        + 'set_source_files_properties(${CMAKE_CURRENT_LIST_DIR}/GCNativeGameBridge.mm PROPERTIES COMPILE_FLAGS "-fobjc-arc")\n';
    }
    if (!cmake.includes('# DEMO_XCODE26_ENOKI')) {
      cmake += '\n# DEMO_XCODE26_ENOKI: Creator 3.8.8 bundles legacy Enoki std trait specializations.\n'
        + 'if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 17)\n'
        + '    target_compile_options(cocos_engine PRIVATE -Wno-invalid-specialization)\nendif()\n';
    }
    writeFileSync(cmakePath, cmake);
  }
}
