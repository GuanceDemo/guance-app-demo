import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';

const source = readFileSync(new URL('../assets/scripts/Config.ts', import.meta.url), 'utf8');
const compiled = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020 } }).outputText;
const config = await import('data:text/javascript;base64,' + Buffer.from(compiled).toString('base64'));
const payload = { demoAndroidAppId: 'android-app', demoIOSAppId: 'ios-app', demoApiAddress: 'https://demo.example.com', datakitAddress: 'http://192.168.1.2:9529' };
const encoded = data => 'gc-demo://' + Buffer.from(JSON.stringify(data)).toString('base64');

test('imports the existing server payload for both platforms, including UTF-8', () => {
  const value = config.importConfig(encoded({ ...payload, demoIOSAppId: '中文测试' }));
  assert.equal(value.demoIOSAppId, '中文测试');
  assert.equal(value.accessType, 'datakit');
  assert.doesNotThrow(() => config.validateConfig(value, 'android'));
  assert.doesNotThrow(() => config.validateConfig(value, 'ios'));
});
test('optional Cocos App IDs override native IDs; blank overrides preserve compatibility', () => {
  assert.equal(config.importConfig(encoded({ ...payload, demoCocosAndroidAppId: 'cocos-android' })).demoAndroidAppId, 'cocos-android');
  assert.equal(config.importConfig(encoded({ ...payload, demoCocosIOSAppId: '' })).demoIOSAppId, 'ios-app');
});
test('DataKit takes precedence and DataWay requires both endpoint and token', () => {
  const value = config.importConfig(encoded({ ...payload, datawayAddress: 'https://dataway.example.com', datawayClientToken: 'secret' }));
  assert.equal(value.accessType, 'datakit');
  const dw = config.importConfig(encoded({ ...payload, datakitAddress: '', datawayAddress: 'https://dataway.example.com', datawayClientToken: 'secret' }));
  assert.equal(dw.accessType, 'dataway');
  assert.deepEqual(config.sdkConnection(dw), { datawayUrl: 'https://dataway.example.com', clientToken: 'secret' });
  assert.deepEqual(config.sdkConnection(value), { datakitUrl: payload.datakitAddress });
  assert.throws(() => config.validateConfig({ ...dw, datawayClientToken: '' }, 'ios'), /Token/);
});
test('only the current platform ID is required', () => {
  const value = config.importConfig(encoded({ ...payload, demoIOSAppId: '' }));
  assert.doesNotThrow(() => config.validateConfig(value, 'android'));
  assert.throws(() => config.validateConfig(value, 'ios'), /iOS/);
});
test('invalid payloads, field types, unsupported URLs and malformed base64 fail safely', () => {
  for (const input of ['gc-demo://%%%', 'gc-demo://abc', 'null', '[]', '{}garbage', encoded({ datakitAddress: 42 }), encoded({ enableSessionReplay: 'true' })]) {
    assert.throws(() => config.importConfig(input));
  }
  for (const url of ['file:///etc/passwd', 'javascript:alert(1)', 'https://', 'https://user:password@example.com', 'http://bad host']) assert.equal(config.isHttpUrl(url), false);
});
test('persisted explicit DataWay mode wins over a retained inactive DataKit endpoint', () => {
  let saved = null;
  const storage = { getItem: () => saved, setItem: (_, value) => { saved = value; } };
  const value = { ...config.importConfig(encoded(payload)), accessType: 'dataway', datawayAddress: 'https://dataway.example.com', datawayClientToken: 'secret', enableSessionReplay: false };
  config.saveConfig(storage, value, 'android');
  assert.deepEqual(config.readConfig(storage), value);
  saved = 'corrupted'; assert.deepEqual(config.readConfig(storage), config.defaultConfig());
});
test('failed validation never overwrites a saved configuration', () => {
  const storage = { getItem: () => null, setItem: () => assert.fail('must not write invalid config') };
  assert.throws(() => config.saveConfig(storage, config.defaultConfig(), 'android'));
});
test('endpoint joining handles a backend mounted below a path', () => {
  assert.equal(config.endpoint('https://demo.example.com/demo/', '/api/products'), 'https://demo.example.com/demo/api/products');
});

test('platform routing never sends or falls back to the other platform App ID', () => {
  const value = config.importConfig(encoded({ ...payload, demoCocosAndroidAppId: 'cocos-android', demoCocosIOSAppId: 'cocos-ios' }));
  assert.deepEqual(config.sdkAppId(value, 'android'), { androidAppId: 'cocos-android' });
  assert.deepEqual(config.sdkAppId(value, 'ios'), { iosAppId: 'cocos-ios' });
  assert.throws(() => config.sdkAppId({ ...value, demoAndroidAppId: '' }, 'android'), /Android/);
  assert.throws(() => config.sdkAppId({ ...value, demoIOSAppId: '' }, 'ios'), /iOS/);
  assert.equal(config.settingFields('android').some(f => f.key === 'demoIOSAppId'), false);
  assert.equal(config.settingFields('ios').some(f => f.key === 'demoAndroidAppId'), false);
});
test('old settings gain defaults; native drafts retain explicit mode, FPS, quality and switches', () => {
  const old = config.readConfig({ getItem: () => JSON.stringify(payload) });
  assert.equal(old.enableSdk, true); assert.equal(old.replayFps, 1); assert.equal(old.replayQuality, 'medium');
  const draft = { ...old, accessType: 'dataway', datawayAddress: 'https://dataway.example.com', datawayClientToken: 'test',
    enableNativeCrash: false, enableAutoResource: false, debug: true, replayFps: 5, replayQuality: 'high' };
  const form = config.formConfig(draft);
  assert.deepEqual(form, draft);
  let saved;
  config.saveConfig({ setItem: (_, value) => { saved = value; } }, form, 'android');
  assert.deepEqual(config.readConfig({ getItem: () => saved }), draft);
  assert.deepEqual(config.sdkReplay(form), { captureFps: 5, imagePolicy: { quality: 'high' }, touchPrivacy: 'show' });
});
test('disabled SDK can be saved before connection setup; invalid options never persist', () => {
  assert.doesNotThrow(() => config.validateConfig({ ...config.defaultConfig(), enableSdk: false }, 'android'));
  for (const changes of [{ replayFps: 0 }, { replayFps: 6 }, { replayFps: 1.5 }, { replayFps: '5' }, { replayQuality: 'ultra' }, { enableSdk: 'false' }, { debug: null }]) {
    assert.throws(() => config.importConfig(JSON.stringify(changes)));
  }
  for (const value of [null, [], 42, { ...config.defaultConfig(), accessType: 'invalid' }]) assert.throws(() => config.formConfig(value));
});
