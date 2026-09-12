import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, openSync, closeSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { patchNative } from './native-project.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const platform = process.argv[2];
if (!['android', 'ios', 'web-mobile'].includes(platform)) throw new Error('Usage: node scripts/build.mjs android|ios|web-mobile [--release]');
const creator = process.env.COCOS_CREATOR || '/Applications/Cocos/Creator/3.8.8/CocosCreator.app/Contents/MacOS/CocosCreator';
if (!existsSync(creator)) throw new Error('Set COCOS_CREATOR to the Cocos Creator 3.8.8 executable.');
if (process.platform === 'darwin') {
  const info = path.resolve(path.dirname(creator), '../Info.plist');
  if (!existsSync(info) || !/<key>CFBundleShortVersionString<\/key>\s*<string>3\.8\.8<\/string>/.test(readFileSync(info, 'utf8'))) {
    throw new Error('This demo requires the Cocos Creator 3.8.8 application.');
  }
}
if (!existsSync(path.join(root, 'extensions/guance-cocos-sdk/package.json'))) throw new Error('Run npm run setup before building.');
const release = process.argv.includes('--release');
const source = JSON.parse(readFileSync(path.join(root, `build-config/${platform}.json`), 'utf8'));
if (release) source.debug = false;
if (process.env.DEMO_PACKAGE_NAME && source.packages?.[platform]) source.packages[platform].packageName = process.env.DEMO_PACKAGE_NAME;
mkdirSync(path.join(root, 'temp'), { recursive: true });
const config = path.join(root, 'temp', `demo-build-${platform}.json`);
writeFileSync(config, JSON.stringify(source, null, 2));
const logfile = path.join(root, 'temp', `build-${platform}.log`);
const fd = openSync(logfile, 'w');
console.log(`Building ${platform} with Creator 3.8.8. Log: ${logfile}`);
const child = spawn(creator, ['--project', root, '--build', `configPath=${config}`], { cwd: root, stdio: ['ignore', fd, fd] });
const code = await new Promise((resolve, reject) => { child.once('error', reject); child.once('exit', resolve); });
closeSync(fd);
// Creator returns 36 on successful command-line builds.
if (![0, 36].includes(code)) throw new Error(`Creator build failed (${code}). See ${logfile}`);
const output = path.join(root, 'build', platform);
if (!existsSync(output)) throw new Error('Creator did not generate the expected build output.');
if (platform !== 'web-mobile') patchNative(root, platform, { version: process.env.DEMO_VERSION, buildNumber: process.env.DEMO_BUILD_NUMBER });
if (platform === 'ios') {
  // Xcode reads build settings before ZERO_CHECK. Regenerate now so a fresh first build
  // already contains the app's compiler compatibility options and plist version values.
  const project = path.join(output, 'proj');
  const cache = readFileSync(path.join(project, 'CMakeCache.txt'), 'utf8');
  const cmake = process.env.CMAKE_BIN || cache.match(/^CMAKE_COMMAND:INTERNAL=(.+)$/m)?.[1];
  if (!cmake || !existsSync(cmake)) throw new Error('Set CMAKE_BIN to the CMake executable configured in Creator.');
  const nativeLog = openSync(logfile, 'a');
  const result = spawnSync(cmake, ['-S', path.join(root, 'native/engine/ios'), '-B', project], { cwd: root, stdio: ['ignore', nativeLog, nativeLog] });
  closeSync(nativeLog);
  if (result.error || result.status !== 0) throw new Error(`iOS CMake regeneration failed. See ${logfile}`);
}
console.log(`Generated ${output}${release ? ' (release JavaScript)' : ''}`);
