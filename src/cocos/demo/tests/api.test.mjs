import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';

const asModule = text => 'data:text/javascript;base64,' + Buffer.from(text).toString('base64');
const compile = file => ts.transpileModule(readFileSync(new URL(file, import.meta.url), 'utf8'), {
  compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020 },
}).outputText;
let requests = [], events = [], autoRequests = 0;
class FakeXHR {
  status = 200; responseText = '{"success":true}'; headers = {};
  constructor() { requests.push(this); }
  open(method, url) { this.method = method; this.url = url; }
  setRequestHeader(name, value) { this.headers[name] = value; }
  send(body) { this.body = body; }
  abort() { this.onabort?.(); }
}
globalThis.XMLHttpRequest = FakeXHR;
globalThis.__demoTestSdk = {
  rum: { startResource: key => events.push(['start', key]), stopResource: key => events.push(['stop', key]), addResource: (key, content) => events.push(['resource', key, content]) },
  trace: { getHeaders: (_, key) => { events.push(['trace', key]); return { 'x-datadog-trace-id': '123' }; } },
};
const configModule = asModule(compile('../assets/scripts/Config.ts'));
const telemetryModule = asModule('export const sdk = globalThis.__demoTestSdk;');
const source = compile('../assets/scripts/Api.ts').replace("'./Config'", JSON.stringify(configModule)).replace("'./Telemetry'", JSON.stringify(telemetryModule));
const { Api } = await import(asModule(source));
// Simulate SDK installing the automatic XHR hook AFTER Api captured pristine methods.
const originalSend = FakeXHR.prototype.send;
FakeXHR.prototype.send = function(body) { ++autoRequests; originalSend.call(this, body); };
const reset = () => { requests = []; events = []; autoRequests = 0; return new Api('https://demo.example.com', { ready: true }); };

test('real login uses automatic XHR once with JSON credentials', async () => {
  const api = reset(); const pending = api.login('guance', 'admin'); const xhr = requests[0];
  xhr.onload(); assert.equal((await pending).success, true);
  assert.equal(xhr.url, 'https://demo.example.com/api/login'); assert.equal(xhr.method, 'POST');
  assert.equal(xhr.body, '{"username":"guance","password":"admin"}');
  assert.equal(autoRequests, 1); assert.deepEqual(events, []);
});
test('manual Resource/Trace bypasses automatic hooks and shares a single correlation key', async () => {
  const api = reset(); const pending = api.request('https://demo.example.com/api/version', { manual: true });
  requests[0].onload(); requests[0].onerror(); await pending;
  assert.equal(autoRequests, 0); assert.equal(requests[0].headers['x-datadog-trace-id'], '123');
  assert.deepEqual(events.map(event => event[0]), ['start', 'trace', 'stop', 'resource']);
  assert.equal(new Set(events.map(event => event[1])).size, 1);
  assert.equal('responseBody' in events[3][2], false);
});
test('DataWay connection probe neither traces nor records its token', async () => {
  const api = reset(); const pending = api.request('https://dataway.example.com/v1/write/logging?token=synthetic-test',
    { untracked: true, method: 'POST', rawBody: 'df_rum_cocos_log message="connect test" 1' });
  requests[0].onload(); await pending;
  assert.equal(autoRequests, 0); assert.deepEqual(events, []);
  assert.equal(requests[0].headers['Content-Type'], 'text/plain');
  assert.equal(requests[0].body, 'df_rum_cocos_log message="connect test" 1');
});
test('manual timeouts close Resource exactly once; cancellation settles outstanding promises', async () => {
  const api = reset(); const timed = api.request('https://demo.example.com', { manual: true });
  requests[0].ontimeout(); requests[0].onerror(); await assert.rejects(timed, /timed out/);
  assert.equal(events.filter(event => event[0] === 'stop').length, 1);
  const pending = api.request('https://demo.example.com'); api.cancel(); await assert.rejects(pending, /cancelled/);
});
test('HTTP failures and malformed JSON produce actionable failures', async () => {
  const api = reset(); const failure = api.products(); requests[0].status = 503; requests[0].onload();
  await assert.rejects(failure, /503/);
  const invalid = api.products(); requests[1].responseText = 'invalid'; requests[1].onload();
  await assert.rejects(invalid, /JSON/);
});
