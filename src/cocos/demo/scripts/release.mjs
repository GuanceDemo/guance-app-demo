import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { closeSync, copyFileSync, existsSync, mkdirSync, openSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const platform = process.argv[2];
if (!['android', 'ios'].includes(platform)) throw new Error('Usage: node scripts/release.mjs android|ios');
const env = process.env;
const required = names => { for (const name of names) if (!env[name]?.trim()) throw new Error(`Set ${name} before preparing a release.`); };
required(['DEMO_VERSION', 'DEMO_BUILD_NUMBER', 'DEMO_PACKAGE_NAME']);
if (!/^\d+\.\d+\.\d+$/.test(env.DEMO_VERSION)) throw new Error('DEMO_VERSION must be major.minor.patch.');
if (!/^[1-9]\d{0,8}$/.test(env.DEMO_BUILD_NUMBER)) throw new Error('DEMO_BUILD_NUMBER must be a positive integer (at most 9 digits).');
if (!/^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*){2,}$/.test(env.DEMO_PACKAGE_NAME)) throw new Error('DEMO_PACKAGE_NAME must be a valid application/bundle identifier.');
if (platform === 'android') {
  required(['ANDROID_KEYSTORE_PATH', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD']);
  if (!existsSync(env.ANDROID_KEYSTORE_PATH)) throw new Error('ANDROID_KEYSTORE_PATH does not exist.');
} else {
  required(['APPLE_TEAM_ID', 'IOS_EXPORT_OPTIONS']);
  if (!existsSync(env.IOS_EXPORT_OPTIONS)) throw new Error('IOS_EXPORT_OPTIONS must point to your App Store Connect export options plist.');
  const parsed = spawnSync('plutil', ['-convert', 'json', '-o', '-', env.IOS_EXPORT_OPTIONS], { encoding: 'utf8' });
  if (parsed.status !== 0) throw new Error('Cannot parse IOS_EXPORT_OPTIONS.');
  const options = JSON.parse(parsed.stdout);
  if (options.destination && options.destination !== 'export') throw new Error('IOS_EXPORT_OPTIONS destination must be export; this script never uploads.');
  if (!['app-store-connect', 'app-store'].includes(options.method)) throw new Error('IOS_EXPORT_OPTIONS method must be app-store-connect (or legacy app-store).');
}
const output = path.join(root, 'artifacts', platform, `${env.DEMO_VERSION}-${env.DEMO_BUILD_NUMBER}`);
mkdirSync(output, { recursive: true });
function run(command, args, cwd, logName) {
  const logfile = path.join(output, logName); const fd = openSync(logfile, 'w');
  console.log(`${logName}: ${logfile}`);
  const result = spawnSync(command, args, { cwd, env: { ...env, CMAKE_BUILD_PARALLEL_LEVEL: '2' }, stdio: ['ignore', fd, fd] });
  closeSync(fd);
  if (result.error || result.status !== 0) throw new Error(`${logName} failed. Inspect ${logfile}`);
}
function find(directory, predicate) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const item = path.join(directory, entry.name);
    if (predicate(item)) return [item];
    return entry.isDirectory() && !entry.name.startsWith('.') ? find(item, predicate) : [];
  });
}

// Only produces local artifacts. Upload is deliberately a separate future operation.
run(process.execPath, ['scripts/build.mjs', platform, '--release'], root, 'creator.log');
let artifact;
if (platform === 'android') {
  const init = path.join(root, 'temp/demo-release.gradle');
  writeFileSync(init, `allprojects { project ->
  project.plugins.withId('com.android.application') {
    project.extensions.getByName('androidComponents').finalizeDsl { android ->
      android.defaultConfig.versionName = System.getenv('DEMO_VERSION')
      android.defaultConfig.versionCode = System.getenv('DEMO_BUILD_NUMBER').toInteger()
      def signing = android.signingConfigs.maybeCreate('demoDistribution')
      signing.storeFile = new File(System.getenv('ANDROID_KEYSTORE_PATH'))
      signing.storePassword = System.getenv('ANDROID_KEYSTORE_PASSWORD')
      signing.keyAlias = System.getenv('ANDROID_KEY_ALIAS')
      signing.keyPassword = System.getenv('ANDROID_KEY_PASSWORD')
      android.buildTypes.release.signingConfig = signing
    }
  }
}
`);
  const project = path.join(root, 'build/android/proj');
  run(process.platform === 'win32' ? 'gradlew.bat' : './gradlew', ['--no-daemon', '--max-workers=2', '-Dorg.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8', '--init-script', init, 'assembleRelease'], project, 'gradle.log');
  const apks = find(path.join(project, 'build'), p => p.endsWith('-release.apk') && p.includes('/outputs/apk/'));
  if (apks.length !== 1) throw new Error(`Expected one signed release APK, found ${apks.length}.`);
  artifact = path.join(output, 'guance_cocos_demo.apk'); copyFileSync(apks[0], artifact);
  const mapping = find(path.join(project, 'build'), p => p.endsWith('/outputs/mapping/release/mapping.txt'));
  if (mapping.length === 1) copyFileSync(mapping[0], path.join(output, 'mapping.txt'));
} else {
  const project = path.join(root, 'build/ios/proj');
  run('pod', ['install'], project, 'pods.log');
  const target = path.join(project, 'GuanceCocosDemo.xcworkspace');
  if (!existsSync(target)) throw new Error('CocoaPods did not generate GuanceCocosDemo.xcworkspace.');
  const args = ['-workspace', target, '-scheme', env.IOS_SCHEME || 'GuanceCocosDemo-mobile',
    '-configuration', 'Release', '-destination', 'generic/platform=iOS', '-jobs', '2'];
  const archive = path.join(output, 'GuanceCocosDemo.xcarchive');
  run('xcodebuild', [...args, '-archivePath', archive, `DEVELOPMENT_TEAM=${env.APPLE_TEAM_ID}`,
    `PRODUCT_BUNDLE_IDENTIFIER=${env.DEMO_PACKAGE_NAME}`, `MARKETING_VERSION=${env.DEMO_VERSION}`, `CURRENT_PROJECT_VERSION=${env.DEMO_BUILD_NUMBER}`, 'archive'], root, 'archive.log');
  run('xcodebuild', ['-exportArchive', '-archivePath', archive, '-exportPath', output, '-exportOptionsPlist', path.resolve(env.IOS_EXPORT_OPTIONS)], root, 'export.log');
  const ipas = find(output, p => p.endsWith('.ipa'));
  if (ipas.length !== 1) throw new Error('Expected one exported IPA.');
  artifact = ipas[0];
}
const sha256 = createHash('sha256').update(readFileSync(artifact)).digest('hex');
writeFileSync(artifact + '.sha256', `${sha256}  ${path.basename(artifact)}\n`);
writeFileSync(path.join(output, 'release.json'), JSON.stringify({ platform, version: env.DEMO_VERSION,
  buildNumber: env.DEMO_BUILD_NUMBER, packageName: env.DEMO_PACKAGE_NAME, creator: '3.8.8', sdk: '0.1.0-alpha.6',
  artifact: path.basename(artifact), sha256, preparedAt: new Date().toISOString() }, null, 2) + '\n');
console.log(`Prepared ${artifact}. No upload performed.`);
