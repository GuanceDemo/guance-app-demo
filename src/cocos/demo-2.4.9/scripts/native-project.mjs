import { adoptIosScenes, addIosSceneManifest, useSceneApplication, enableIosRotation } from './ios-scenes.mjs';
import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const platforms = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../platforms');

function edit(file, transform) { writeFileSync(file, transform(readFileSync(file, 'utf8'))); }
function marked(source, name, content) {
  const begin = `// ${name}_BEGIN`, end = `// ${name}_END`;
  const block = `${begin}\n${content}\n${end}`;
  return source.includes(begin) ? source.replace(new RegExp(`${begin}[\\s\\S]*?${end}`, 'g'), block) : `${source}\n${block}\n`;
}

function alignIosWebP(ios) {
  const config = path.join(ios, 'UserConfigIOS.debug.xcconfig');
  if (process.platform !== 'darwin' || !existsSync(config)) return;
  const include = readFileSync(config, 'utf8').match(/^#include\s+"([^"\n]*CCModuleConfigIOS\.debug\.xcconfig)"/m)?.[1];
  if (!include) return;
  const engine = path.resolve(ios, path.dirname(include), '../../..');
  const original = path.join(engine, 'external/ios/libs/libwebp.a');
  const directory = path.resolve(ios, 'demo-webp');
  mkdirSync(directory, { recursive: true });
  const lipo = args => {
    const result = spawnSync('xcrun', ['lipo', ...args], { encoding: 'utf8', maxBuffer: 65536 });
    if (result.error || result.status !== 0) throw new Error(`Cannot align Creator's WebP archive: ${String(result.error || result.stderr).slice(0, 1500)}`);
    return result.stdout.trim();
  };
  const info = lipo(['-info', original]);
  const architectures = info.match(/are: ([^\r\n]+)/)?.[1].trim().split(/\s+/);
  if (!architectures) return; // Thin archives do not have a universal slice-offset problem.
  const slices = architectures.map(architecture => {
    const slice = path.join(directory, `${architecture}.a`);
    lipo([original, '-thin', architecture, '-output', slice]);
    return slice;
  });
  const alignments = architectures.filter(architecture => ['arm64', 'arm64e', 'x86_64'].includes(architecture))
    .flatMap(architecture => ['-segalign', architecture, '0x8']);
  lipo(['-create', ...slices, ...alignments, '-output', path.join(directory, 'libwebp.a')]);
  for (const mode of ['debug', 'release']) edit(path.join(ios, `UserConfigIOS.${mode}.xcconfig`), source =>
    marked(source, 'DEMO_IOS_WEBP_ALIGNMENT', `LIBRARY_SEARCH_PATHS = "${directory}" $(inherited)`));
}

// Native files live in frameworks/runtime-src in Creator 2, unlike Creator 3's native/engine.
export function patchNative(buildRoot, platform) {
  if (!['android', 'ios'].includes(platform)) throw new Error('Expected android or ios.');
  const runtime = path.join(buildRoot, 'frameworks/runtime-src');
  // Both editions can stay alive on one device; their JS inspectors need distinct ports.
  edit(path.join(runtime, 'Classes/AppDelegate.cpp'), source => {
    const next = source.replace(/jsb_enable_debugger\("0\.0\.0\.0",\s*6086,/, 'jsb_enable_debugger("0.0.0.0", 6087,');
    if (!next.includes('jsb_enable_debugger("0.0.0.0", 6087,')) throw new Error('Missing Creator 2 JS debugger configuration.');
    return next;
  });
  if (platform === 'android') {
    const project = path.join(runtime, 'proj.android-studio');
    const app = path.join(project, 'app');
    const manifest = path.join(app, 'AndroidManifest.xml');
    edit(manifest, source => {
      source = source.replace(/<application\b[^>]*>/, tag => {
        const name = tag.match(/android:name="([^"]*)"/);
        if (name && name[1] !== 'com.guance.cocos.demo.NativeSdkApplication') throw new Error('Unexpected Application class. Integrate NativeTelemetry.boot into the existing host.');
        if (!name) tag = tag.replace('<application', '<application android:name="com.guance.cocos.demo.NativeSdkApplication"');
        return tag.includes('android:usesCleartextTraffic=') ? tag.replace(/android:usesCleartextTraffic="[^"]*"/, 'android:usesCleartextTraffic="true"') : tag.replace('<application', '<application android:usesCleartextTraffic="true"');
      });
      const host = /<activity\b[^>]*android:name="(?:org\.cocos2dx\.javascript\.AppActivity|com\.guance\.cocos\.demo\.NativeCocosActivity)"[^>]*>/;
      if (!host.test(source)) throw new Error('Missing Creator 2 AppActivity.');
      source = source.replace(host, tag => {
        tag = tag.replace('org.cocos2dx.javascript.AppActivity', 'com.guance.cocos.demo.NativeCocosActivity');
        tag = tag.includes('android:screenOrientation=')
          ? tag.replace(/android:screenOrientation="[^"]*"/, 'android:screenOrientation="portrait"')
          : tag.replace('<activity', '<activity android:screenOrientation="portrait"');
        if (!tag.includes('android:exported=')) tag = tag.replace('<activity', '<activity android:exported="true"');
        return tag.includes('android:enableOnBackInvokedCallback=') ? tag.replace(/android:enableOnBackInvokedCallback="[^"]*"/, 'android:enableOnBackInvokedCallback="true"') : tag.replace('<activity', '<activity android:enableOnBackInvokedCallback="true"');
      });
      if (!source.includes('com.guance.cocos.demo.NativeGameActivity')) source = source.replace('</application>', '<activity android:name="com.guance.cocos.demo.NativeGameActivity" android:exported="false" android:screenOrientation="portrait" android:configChanges="orientation|keyboardHidden|screenSize" android:theme="@android:style/Theme.Material.NoActionBar" />\n</application>');
      return source;
    });
    const java = path.join(app, 'src/com/guance/cocos/demo'); mkdirSync(java, { recursive: true });
    for (const name of readdirSync(path.join(platforms, 'android'))) copyFileSync(path.join(platforms, 'android', name), path.join(java, name));
    const rules = path.join(app, 'proguard-rules.pro');
    writeFileSync(rules, marked(existsSync(rules) ? readFileSync(rules, 'utf8') : '', 'DEMO_BRIDGES', '-keep class com.ft.sdk.cocos.** { *; }\n-keep class com.guance.cocos.demo.NativeGameBridge { *; }\n-keep class com.guance.cocos.demo.NativeTelemetry { *; }'));
    edit(path.join(project, 'build.gradle'), source => {
      if (!/buildscript\s*\{/.test(source)) throw new Error('Missing Android buildscript.');
      const name = 'DEMO_FT_PLUGIN';
      const content = "repositories { maven { url 'https://mvnrepo.guance.com/repository/maven-releases' } }\ndependencies { classpath 'com.cloudcare.ft.mobile.sdk.tracker.plugin:ft-plugin:1.3.9-alpha01' }";
      if (source.includes(`// ${name}_BEGIN`)) return marked(source, name, content);
      return source.replace(/buildscript\s*\{/, value => `${value}\n${marked('', name, content)}\n`);
    });
    edit(path.join(app, 'build.gradle'), source => marked(source
      .replace(/arguments '-j' \+ Runtime\.runtime\.availableProcessors\(\)/g, "arguments '-j2'"), 'DEMO_FT_PLUGIN',
      "apply plugin: 'ft-plugin'\nFTExt { showLog = true; instrumentHttpURLConnection = true }\nandroid { compileOptions { sourceCompatibility JavaVersion.VERSION_1_8; targetCompatibility JavaVersion.VERSION_1_8 } }"));
    edit(path.join(project, 'gradle.properties'), source => {
      source = source.replace(/^(PROP_COMPILE_SDK_VERSION|PROP_TARGET_SDK_VERSION)\s*=\s*\d+/gm, '$1=34');
      source = source.replace(/^org\.gradle\.jvmargs=.*$/m, 'org.gradle.jvmargs=-Xmx2048m');
      return /^org\.gradle\.workers\.max=/m.test(source) ? source.replace(/^org\.gradle\.workers\.max=.*$/m, 'org.gradle.workers.max=2') : `${source}\norg.gradle.workers.max=2\n`;
    });
    // Creator 2 uses ndk-build. These flags align the app library; prebuilts still need device verification.
    edit(path.join(project, 'jni/CocosAndroid.mk'), source => {
      const flags = 'LOCAL_LDFLAGS += -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384';
      if (source.includes(flags)) return source;
      if (!source.includes('include $(BUILD_SHARED_LIBRARY)')) throw new Error('Missing cocos2djs shared library target.');
      return source.replace('include $(BUILD_SHARED_LIBRARY)', `${flags}\ninclude $(BUILD_SHARED_LIBRARY)`);
    });
  } else {
    const project = path.join(runtime, 'proj.ios_mac'), ios = path.join(project, 'ios');
    alignIosWebP(ios);
    for (const name of readdirSync(path.join(platforms, 'ios'))) copyFileSync(path.join(platforms, 'ios', name), path.join(ios, name));
    edit(path.join(ios, 'AppController.mm'), source => {
      if (!source.includes('#import "GCNativeTelemetry.h"')) source = '#import "GCNativeTelemetry.h"\n' + source;
      if (!source.includes('[GCNativeTelemetry boot];')) {
        const launch = /(-\s*\(BOOL\)application:[^{]+didFinishLaunchingWithOptions:[^{]+\{)/;
        if (!launch.test(source)) throw new Error('Missing AppController launch callback.');
        source = source.replace(launch, '$1\n    [GCNativeTelemetry boot];');
      }
      return adoptIosScenes(source);
    });
    edit(path.join(ios, 'main.m'), useSceneApplication);
    edit(path.join(ios, 'Info.plist'), source => {
      if (!source.includes('<key>NSAppTransportSecurity</key>')) source = source.replace('<dict>', '<dict>\n<key>NSAppTransportSecurity</key><dict><key>NSAllowsArbitraryLoads</key><true/></dict>');
      if (!source.includes('<key>NSLocalNetworkUsageDescription</key>')) source = source.replace('<dict>', '<dict>\n<key>NSLocalNetworkUsageDescription</key><string>Connect to the local Demo API and DataKit collector.</string>');
      source = source.replace(/(<key>CFBundleDisplayName<\/key>\s*<string>)[^<]*(<\/string>)/, '$1Cocos 2.4.9$2');
      return enableIosRotation(addIosSceneManifest(source));
    });
    const xcode = readdirSync(project).filter(name => name.endsWith('.xcodeproj'));
    if (xcode.length !== 1) throw new Error('Expected one generated Xcode project.');
    edit(path.join(project, xcode[0], 'project.pbxproj'), addIosSources);
  }
}

export function addIosSources(source) {
  // Attach to the same group and source phase as AppController, leaving the Mac target alone.
  const controller = source.match(/([A-F0-9]{24}) \/\* AppController\.mm in Sources \*\/ = \{isa = PBXBuildFile; fileRef = ([A-F0-9]{24})/);
  if (!controller) throw new Error('Missing AppController Xcode build entry.');
  const controllerRef = source.match(new RegExp(`${controller[2]} /\\* AppController\\.mm \\*/ = \\{([^}]+)\\};`))?.[1];
  const controllerPath = controllerRef?.match(/\bpath\s*=\s*("[^"]+"|[^;]+);/)?.[1].replace(/^"|"$/g, '').trim();
  if (!controllerPath) throw new Error('Missing AppController Xcode file path.');
  const sourceTree = controllerRef.match(/\bsourceTree\s*=\s*([^;]+);/)?.[1] ?? '"<group>"';
  for (const name of ['GCNativeGameBridge.mm', 'GCNativeTelemetry.mm', 'GCSceneDelegate.mm']) {
    const id = suffix => createHash('sha256').update(`demo249:${name}:${suffix}`).digest('hex').slice(0, 24).toUpperCase();
    const file = id('file'), build = id('build');
    const relativePath = path.posix.join(path.posix.dirname(controllerPath), name);
    const reference = `${file} /* ${name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.cpp.objcpp; name = ${name}; path = "${relativePath}"; sourceTree = ${sourceTree}; };`;
    if (source.includes(`/* ${name} in Sources */ =`)) {
      // Repair projects generated with the old root-relative bridge paths too.
      source = source.replace(new RegExp(`${file} /\\*[^*]+\\*/ = \\{[^}]+\\};`), reference);
      continue;
    }
    source = source.replace('/* End PBXBuildFile section */', `\t\t${build} /* ${name} in Sources */ = {isa = PBXBuildFile; fileRef = ${file} /* ${name} */; settings = {COMPILER_FLAGS = "-fobjc-arc"; }; };\n/* End PBXBuildFile section */`);
    source = source.replace('/* End PBXFileReference section */', `\t\t${reference}\n/* End PBXFileReference section */`);
    const group = `${controller[2]} /* AppController.mm */,`;
    const phase = `${controller[1]} /* AppController.mm in Sources */,`;
    if (!source.includes(group) || !source.includes(phase)) throw new Error('Missing AppController group or source phase.');
    source = source.replace(group, `${group}\n\t\t\t\t${file} /* ${name} */,`);
    source = source.replace(phase, `${phase}\n\t\t\t\t${build} /* ${name} in Sources */,`);
  }
  return source;
}
