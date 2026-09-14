import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';
const calls = [];
let reply = '', fail = false;
const sys = { isNative: true, os: 'Android', OS: { ANDROID: 'Android', IOS: 'iOS' } };
globalThis.__nativePageTest = { sys, native: { reflection: { callStaticMethod: (...args) => {
  calls.push(args); if (fail) throw new Error('Missing bridge'); const value = reply; reply = ''; return value;
} } } };
const url = source => 'data:text/javascript;base64,' + Buffer.from(source).toString('base64');
const engine = url('export const {sys, native} = globalThis.__nativePageTest;');
const source = ts.transpileModule(readFileSync(new URL('../assets/scripts/NativePages.ts', import.meta.url), 'utf8'), {
  compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020 },
}).outputText.replace("'cc'", JSON.stringify(engine));
const { NativePages } = await import(url(source));
const payload = { page: 'lobby', best: 40, sdkStatus: 'SDK not configured' };

test('Android mailbox accepts the matching request once and ignores stale responses', () => {
  calls.length = 0; sys.os = 'Android';
  const pages = new NativePages(); assert.equal(pages.open(payload), true);
  const request = JSON.parse(calls[0][3]); assert.equal(request.best, 40);
  assert.equal(calls[0][0], 'com/guance/cocos/demo/NativeGameBridge');
  reply = JSON.stringify({ requestId: request.requestId + 1, action: 'play' }); assert.equal(pages.poll(), undefined);
  reply = JSON.stringify({ requestId: request.requestId, action: 'play' }); assert.equal(pages.poll(), 'play');
  assert.equal(pages.pending, false); const count = calls.length; pages.poll(); assert.equal(calls.length, count);
});
test('iOS uses Objective-C selectors and returns native navigation', () => {
  calls.length = 0; sys.os = 'iOS';
  const pages = new NativePages(); pages.open(payload);
  assert.equal(calls[0][1], 'show:'); const request = JSON.parse(calls[0][2]);
  reply = JSON.stringify({ requestId: request.requestId, action: 'settings' });
  assert.equal(pages.poll(), 'settings'); assert.equal(calls[1][1], 'consumeAction:');
});
test('browser and missing native bridge fall back without leaving pending navigation', () => {
  const pages = new NativePages(); sys.isNative = false;
  assert.equal(pages.open(payload), false); assert.equal(pages.pending, false);
  sys.isNative = true; fail = true;
  try { assert.equal(pages.open(payload), false); assert.equal(pages.pending, false); } finally { fail = false; }
});

test('Android Back mailbox consumes once and is not read for native pages or other platforms', () => {
  sys.os = 'Android'; calls.length = 0;
  const pages = new NativePages(); reply = true;
  assert.equal(pages.consumeBack(), true);
  assert.deepEqual(calls[0], ['com/guance/cocos/demo/NativeGameBridge', 'consumeBack', '()Z']);
  assert.equal(pages.consumeBack(), false);
  pages.pending = true; const count = calls.length;
  assert.equal(pages.consumeBack(), false); assert.equal(calls.length, count);
  pages.pending = false; sys.os = 'iOS';
  assert.equal(pages.consumeBack(), false); assert.equal(calls.length, count);
  sys.os = 'Android'; sys.isNative = false;
  assert.equal(pages.consumeBack(), false); assert.equal(calls.length, count);
  sys.isNative = true; fail = true;
  try { assert.equal(pages.consumeBack(), false); } finally { fail = false; }
});
