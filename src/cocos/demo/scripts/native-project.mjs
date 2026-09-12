import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const platforms = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../platforms');

/** Apply app-owned HTTP/version settings to Creator-generated native projects. SDK linking is owned by its npm extension. */
export function patchNative(root, platform, metadata = {}) {
  if (platform === 'android') {
    const manifest = path.join(root, 'native/engine/android/app/AndroidManifest.xml');
    if (!existsSync(manifest)) throw new Error(`Missing generated Android manifest: ${manifest}`);
    let value = readFileSync(manifest, 'utf8');
    value = value.replace(/android:usesCleartextTraffic="[^"]*"/g, 'android:usesCleartextTraffic="true"');
    if (!value.includes('android:usesCleartextTraffic')) value = value.replace('<application', '<application android:usesCleartextTraffic="true"');
    if (!value.includes('com.guance.cocos.demo.NativeGameActivity')) {
      value = value.replace(/(<application\b[^>]*?)\/>/, '$1></application>');
      value = value.replace('</application>', '<activity android:name="com.guance.cocos.demo.NativeGameActivity" android:exported="false" android:screenOrientation="portrait" android:configChanges="orientation|keyboardHidden|screenSize" android:theme="@android:style/Theme.Material.NoActionBar" />\n</application>');
    }
    writeFileSync(manifest, value);
    const java = path.join(root, 'native/engine/android/app/src/com/guance/cocos/demo');
    mkdirSync(java, { recursive: true });
    for (const name of ['NativeGameBridge.java', 'NativeGameActivity.java']) copyFileSync(path.join(platforms, 'android', name), path.join(java, name));
    // JSB resolves these npm-provided Java classes/methods by strings, so R8 must preserve them.
    const proguard = path.join(root, 'native/engine/android/app/proguard-rules.pro');
    const rules = existsSync(proguard) ? readFileSync(proguard, 'utf8') : '';
    if (!rules.includes('# DEMO_COCOS_BRIDGE')) writeFileSync(proguard,
      rules + '\n# DEMO_COCOS_BRIDGE\n-keep class com.ft.sdk.cocos.** { *; }\n');
    const updatedRules = readFileSync(proguard, 'utf8');
    if (!updatedRules.includes('# DEMO_NATIVE_PAGES')) writeFileSync(proguard,
      updatedRules + '\n# DEMO_NATIVE_PAGES\n-keep class com.guance.cocos.demo.NativeGameBridge { *; }\n');
  } else {
    const plist = path.join(root, 'native/engine/ios/Info.plist');
    if (!existsSync(plist)) throw new Error(`Missing generated iOS Info.plist: ${plist}`);
    let value = readFileSync(plist, 'utf8');
    const version = metadata.version ?? JSON.parse(readFileSync(path.join(root, 'package.json'), 'utf8')).version;
    const buildNumber = metadata.buildNumber ?? '1';
    if (!/^\d+\.\d+\.\d+$/.test(version) || !/^[1-9]\d*$/.test(buildNumber)) throw new Error('Invalid iOS version/build number.');
    value = value.replace(/(<key>CFBundleShortVersionString<\/key>\s*<string>)[^<]*(<\/string>)/, (_, before, after) => before + version + after);
    value = value.replace(/(<key>CFBundleVersion<\/key>\s*<string>)[^<]*(<\/string>)/, (_, before, after) => before + buildNumber + after);
    if (!value.includes('<key>NSAppTransportSecurity</key>')) {
      value = value.replace(/<dict>/, '<dict>\n\t<key>NSAppTransportSecurity</key>\n\t<dict><key>NSAllowsArbitraryLoads</key><true/></dict>');
    }
    if (!value.includes('<key>NSLocalNetworkUsageDescription</key>')) value = value.replace(/<dict>/,
      '<dict>\n\t<key>NSLocalNetworkUsageDescription</key><string>Connect to the configured local Demo API and DataKit collector.</string>');
    writeFileSync(plist, value);
    const cmakePath = path.join(root, 'native/engine/ios/CMakeLists.txt');
    let cmake = readFileSync(cmakePath, 'utf8');
    copyFileSync(path.join(platforms, 'ios/GCNativeGameBridge.mm'), path.join(root, 'native/engine/ios/GCNativeGameBridge.mm'));
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
