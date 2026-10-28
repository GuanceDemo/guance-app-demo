import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, openSync, closeSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { creatorPath } from './creator.mjs';
import { patchNative } from './native-project.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const platform = process.argv[2];
if (!['android', 'ios', 'web-mobile'].includes(platform)) throw new Error('Usage: node scripts/build.mjs android|ios|web-mobile');
const creator = creatorPath();
if (!existsSync(path.join(root, 'packages/guance-cocos-sdk/package.json'))) throw new Error('Run npm run setup before building.');
const config = { ...JSON.parse(readFileSync(path.join(root, 'settings/builder.json'), 'utf8')), platform,
  buildPath: path.join(root, 'build', platform), autoCompile: false };
if (process.env.DEMO_PACKAGE_NAME) {
  if (!/^[A-Za-z]\w*(?:\.[A-Za-z]\w*)+$/.test(process.env.DEMO_PACKAGE_NAME)) throw new Error('Invalid DEMO_PACKAGE_NAME.');
  config.packageName = process.env.DEMO_PACKAGE_NAME; config.ios.packageName = config.packageName; config.android.packageName = config.packageName;
}
mkdirSync(path.join(root, 'temp'), { recursive: true });
const configPath = path.join(root, 'temp', `build-${platform}.json`);
writeFileSync(configPath, JSON.stringify(config, null, 2));
const log = path.join(root, 'temp', `build-${platform}.log`);
const fd = openSync(log, 'w');
console.log(`Building ${platform} with Creator 2.4.9. Log: ${log}`);
const child = spawn(creator, ['--path', root, '--build', `configPath=${configPath}`], {
  cwd: root, stdio: ['ignore', fd, fd], env: { ...process.env, UV_THREADPOOL_SIZE: '2' },
});
let code;
try { code = await new Promise((resolve, reject) => { child.once('error', reject); child.once('exit', (status, signal) => resolve({ status, signal })); }); }
finally { closeSync(fd); }
if (![0, 36].includes(code.status)) throw new Error(`Creator build failed (${code.signal || code.status}). See ${log}`);
const output = platform === 'web-mobile' ? config.buildPath : path.join(config.buildPath, 'jsb-link');
if (!existsSync(path.join(output, platform === 'web-mobile' ? 'index.html' : 'main.js')))
  throw new Error(`Creator did not generate the expected output: ${output}`);
if (platform !== 'web-mobile') patchNative(output, platform);
console.log(`Generated ${output}`);
