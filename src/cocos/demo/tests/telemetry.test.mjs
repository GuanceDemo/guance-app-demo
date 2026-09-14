import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';
import { composeSessionReplay } from '../node_modules/@cloudcare/cocos-session-replay/dist/creator3/core/client.js';
import { FTCocosSDK } from '../node_modules/@cloudcare/cocos-sdk/dist/creator3/core/client.js';
import { FTDefaultAutoTracking } from '../node_modules/@cloudcare/cocos-sdk/dist/creator3/core/auto-tracking.js';
import { FTRUM, FTLogger, FTTrace } from '../node_modules/@cloudcare/cocos-sdk/dist/creator3/core/modules.js';
const calls = [];
let failAttach = false, initialized = false;
const record = name => (...args) => calls.push([name, ...args]);
const transport = { platform: 'android', invoke(method, payload) {
  calls.push([method, payload]);
  if (method === 'replay.capabilities') return { protocol: 1 };
  if (method === 'hybrid.attach' && (!initialized || failAttach)) throw Error('host unavailable');
} };
let sdk;
const sys = { isNative: true, os: 'Android', OS: { ANDROID: 'Android', IOS: 'iOS' } };
const nativeHost = {
  initialize(config) { record('host.initialize')(config); initialized = true; },
  disable() { record('host.disable')(); const wasInitialized = initialized; initialized = false; return wasInitialized; },
};
globalThis.__telemetryTest = { get sdk() { return sdk; }, sys, nativeHost };
const url = source => 'data:text/javascript;base64,' + Buffer.from(source).toString('base64');
const compile = name => ts.transpileModule(readFileSync(new URL(`../assets/scripts/${name}.ts`, import.meta.url), 'utf8'), {
  compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020 },
}).outputText;
const configUrl = url(compile('Config'));
const { defaultConfig } = await import(configUrl);
const baseSource = compile('Telemetry').replace("'cc'", JSON.stringify(url('export const {sys} = globalThis.__telemetryTest;')))
  .replace("'@cloudcare/cocos-sdk/creator3'", JSON.stringify(url('export const guanceSdk = new Proxy({}, {get: (_, key) => { const value = globalThis.__telemetryTest.sdk[key]; return typeof value === "function" ? value.bind(globalThis.__telemetryTest.sdk) : value; }});')))
  .replace("'@cloudcare/cocos-session-replay/creator3'", JSON.stringify(url('export const withSessionReplay = sdk => sdk;')))
  .replace("'./NativeHost'", JSON.stringify(url('export const {nativeHost} = globalThis.__telemetryTest;')))
  .replace("'./Config'", JSON.stringify(configUrl));
const { Telemetry } = await import(url(baseSource));
function reset() {
  calls.length = 0; failAttach = false; initialized = false; sys.isNative = true; sys.os = 'Android';
  const rum = new FTRUM(transport), logger = new FTLogger(transport), trace = new FTTrace(transport);
  const tracking = new FTDefaultAutoTracking(rum, logger, trace, {}, {});
  const base = new FTCocosSDK(transport, tracking);
  const composed = composeSessionReplay(base, 'creator3', () => ({ transport, capture: { setCamera: record('camera') } }));
  sdk = {
    attach(config) { record('attach')(config); composed.attach(config); },
    enterCocos(options) { record('enter')(options); composed.enterCocos(options); },
    leaveCocos() { record('leave')(); composed.leaveCocos(); },
    setReplayCamera: record('camera'),
    rum: base.rum, logger: base.logger, mobile: base.mobile, replay: composed.replay,
    start() { assert.fail('Cocos must never initialize the native SDK'); },
    shutdown() { assert.fail('Cocos must never shut down the native SDK'); },
  };
}
const valid = () => ({ ...defaultConfig(), demoAndroidAppId: 'android-only', demoIOSAppId: 'ios-only',
  demoApiAddress: 'https://demo.example.com', datakitAddress: 'https://collector.example.com' });

test('host initialization precedes attach; attach contains only capture and automatic tracking options', () => {
  for (const os of ['Android', 'iOS']) {
    reset(); sys.os = os;
    const telemetry = new Telemetry(); telemetry.start(valid(), {});
    assert.deepEqual(calls.map(c => c[0]), ['host.initialize', 'camera', 'attach', 'replay.capabilities', 'hybrid.attach']);
    const config = calls.find(c => c[0] === 'attach')[1];
    assert.deepEqual(Object.keys(config).sort(), ['autoTrack', 'replay']);
    assert.equal('sampleRate' in config.replay, false);
    assert.equal('sdk' in config, false); assert.equal('rum' in config, false);
    assert.equal(telemetry.ready, true);
  }
});
test('native -> Cocos -> native repeated transitions leave exactly one View and retain native SDK', () => {
  reset(); const telemetry = new Telemetry(); telemetry.start(valid(), {}); calls.length = 0;
  for (let i = 0; i < 3; i++) {
    telemetry.view('Game', 'game'); telemetry.view('Game', 'game');
    telemetry.view('Lab', 'experimental'); telemetry.leave(); telemetry.leave();
  }
  const views = calls.filter(c => ['rum.startView', 'rum.stopView'].includes(c[0]));
  let active = 0;
  for (const [method] of views) { active += method === 'rum.startView' ? 1 : -1; assert.ok(active === 0 || active === 1); }
  assert.equal(active, 0); assert.equal(views.length, 12);
  assert.equal(calls.filter(c => c[0] === 'enter').length, 3);
  assert.equal(calls.filter(c => c[0] === 'leave').length, 3);
  assert.deepEqual(calls.filter(c => c[0] === 'hybrid.setExternalRecorderActive').map(c => c[1].active), [true, false, true, false, true, false]);
  assert.throws(() => sdk.replay.start(), /Hybrid Replay/);
  assert.throws(() => sdk.replay.stop(), /Hybrid Replay/);
  telemetry.close(); assert.equal(initialized, true);
});
test('explicit disable leaves Cocos before asking the host to stop; component cleanup never stops host', () => {
  reset(); const telemetry = new Telemetry(); telemetry.start(valid(), {}); telemetry.view('Game', 'game');
  calls.length = 0; telemetry.disable();
  assert.deepEqual(calls.map(c => c[0]), ['leave', 'rum.stopView', 'hybrid.setExternalRecorderActive', 'host.disable']);
  assert.equal(telemetry.ready, false); assert.equal(telemetry.message, 'SDK disabled');
  telemetry.close();
});
test('disabled SDK and browser preview never initialize or attach', () => {
  reset(); new Telemetry().start({ ...defaultConfig(), enableSdk: false }, {});
  sys.isNative = false; new Telemetry().start(defaultConfig(), {});
  assert.deepEqual(calls, []);
});
test('failed attach keeps the native SDK running and can retry', () => {
  reset(); failAttach = true; const telemetry = new Telemetry();
  assert.throws(() => telemetry.start(valid(), {}), /Hybrid attachment failed/);
  assert.equal(telemetry.ready, false); assert.equal(initialized, true);
  failAttach = false; telemetry.start(valid(), {}); assert.equal(telemetry.ready, true);
});
test('Replay FPS/quality and Cocos switches reach attach; Replay disabled omits capture', () => {
  reset(); const telemetry = new Telemetry();
  telemetry.start({ ...valid(), replayFps: 4, replayQuality: 'high', enableAutoResource: false, enableAutoError: false }, {});
  const config = calls.find(c => c[0] === 'attach')[1];
  assert.deepEqual(config.replay, { captureFps: 4, imagePolicy: { quality: 'high' }, touchPrivacy: 'show' });
  assert.equal(config.autoTrack.network, false); assert.equal(config.autoTrack.errors, false);
  reset(); const withoutReplay = new Telemetry(); withoutReplay.start({ ...valid(), enableSessionReplay: false }, {});
  assert.equal('replay' in calls.find(c => c[0] === 'attach')[1], false);
  withoutReplay.view('Game', 'game'); withoutReplay.leave();
  assert.equal(calls.some(c => c[0] === 'hybrid.setExternalRecorderActive'), false);
});
