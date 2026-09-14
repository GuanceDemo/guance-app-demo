import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';
const calls = [];
let saved = '', rejected = false;
const legacy = new Map();
const sys = { isNative: true, os: 'Android', OS: { ANDROID: 'Android', IOS: 'iOS' }, localStorage: {
  getItem: key => legacy.get(key) ?? null, setItem: (key, value) => legacy.set(key, value),
} };
const native = { reflection: { callStaticMethod(...args) {
  calls.push(args);
  if (rejected) return JSON.stringify({ ok: false, error: 'Host unavailable' });
  const [method, payload] = args.slice(sys.os === 'Android' ? 3 : 2);
  if (method === 'read') return JSON.stringify({ ok: true, value: saved });
  if (method === 'save') saved = payload;
  return JSON.stringify({ ok: true, value: method === 'disable' });
} } };
globalThis.__nativeHostTest = { sys, native };
const url = s => 'data:text/javascript;base64,' + Buffer.from(s).toString('base64');
let source = ts.transpileModule(readFileSync(new URL('../assets/scripts/NativeHost.ts', import.meta.url), 'utf8'), {
  compilerOptions: { module: ts.ModuleKind.ES2020, target: ts.ScriptTarget.ES2020 },
}).outputText;
source = source.replace("'cc'", JSON.stringify(url('export const {sys, native} = globalThis.__nativeHostTest;')))
  .replace("'./Config'", JSON.stringify(url('export const CONFIG_KEY = "settings";')));
const { configStorage, nativeHost } = await import(url(source));
function reset() { calls.length = 0; saved = ''; rejected = false; legacy.clear(); sys.isNative = true; sys.os = 'Android'; }

test('native settings win over legacy data; first setup reads old localStorage for migration', () => {
  reset(); legacy.set('settings', 'old');
  assert.equal(configStorage.getItem('settings'), 'old');
  configStorage.setItem('settings', 'native');
  assert.equal(configStorage.getItem('settings'), 'native');
  assert.equal(legacy.get('settings'), 'old');
});
test('both platforms route lifecycle to host bridge; disable returns restart requirement', () => {
  for (const os of ['Android', 'iOS']) {
    reset(); sys.os = os; nativeHost.initialize({ enableSdk: true }); assert.equal(nativeHost.disable(), true);
    assert.equal(calls[0][0], os === 'Android' ? 'com/guance/cocos/demo/NativeTelemetry' : 'GCNativeTelemetry');
    assert.equal(calls[0][1], os === 'Android' ? 'invoke' : 'invoke:payload:');
  }
});
test('host save failure is surfaced and never silently persists settings only in Cocos', () => {
  reset(); rejected = true;
  assert.throws(() => configStorage.setItem('settings', 'new'), /Host unavailable/);
  assert.equal(legacy.has('settings'), false);
});
test('browser settings stay local and do not call the native bridge', () => {
  reset(); sys.isNative = false;
  configStorage.setItem('settings', 'preview');
  assert.equal(configStorage.getItem('settings'), 'preview'); assert.deepEqual(calls, []);
});
