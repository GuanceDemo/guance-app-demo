import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { patchNative } from '../scripts/native-project.mjs';

test('native app patches are repeatable and apply the requested iOS version/build number', () => {
  const root = mkdtempSync(path.join(tmpdir(), 'cocos-native-test-'));
  try {
    mkdirSync(path.join(root, 'native/engine/android/app'), { recursive: true });
    mkdirSync(path.join(root, 'native/engine/ios'), { recursive: true });
    writeFileSync(path.join(root, 'package.json'), '{"version":"1.0.0"}');
    const manifest = path.join(root, 'native/engine/android/app/AndroidManifest.xml');
    writeFileSync(manifest, '<manifest><application android:usesCleartextTraffic="false" /></manifest>');
    patchNative(root, 'android'); patchNative(root, 'android');
    assert.equal((readFileSync(manifest, 'utf8').match(/android:usesCleartextTraffic="true"/g) ?? []).length, 1);
    const rules = readFileSync(path.join(root, 'native/engine/android/app/proguard-rules.pro'), 'utf8');
    assert.equal((rules.match(/# DEMO_COCOS_BRIDGE/g) ?? []).length, 1);
    assert.match(rules, /-keep class com\.ft\.sdk\.cocos\.\*\*/);
    const plist = path.join(root, 'native/engine/ios/Info.plist');
    const cmake = path.join(root, 'native/engine/ios/CMakeLists.txt');
    writeFileSync(plist, '<plist><dict><key>CFBundleShortVersionString</key><string>1.0.0</string><key>CFBundleVersion</key><string>1.0</string></dict></plist>');
    writeFileSync(cmake, 'project(Demo)\n');
    patchNative(root, 'ios', { version: '2.3.4', buildNumber: '102' });
    patchNative(root, 'ios', { version: '2.3.4', buildNumber: '102' });
    const result = readFileSync(plist, 'utf8');
    assert.match(result, /CFBundleShortVersionString<\/key><string>2.3.4<\/string>/);
    assert.match(result, /CFBundleVersion<\/key><string>102<\/string>/);
    assert.equal((result.match(/NSAppTransportSecurity/g) ?? []).length, 1);
    assert.equal((readFileSync(cmake, 'utf8').match(/# DEMO_XCODE26_ENOKI/g) ?? []).length, 1);
  } finally { rmSync(root, { recursive: true, force: true }); }
});
