import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';

const sys = { isNative: true, os: 'Android', OS: { ANDROID: 'Android' }, localStorage: {} };
const node = () => ({ active: true, destroy() { this.destroyed = true; }, on() {} });
class Page {
  node = node();
  heading() {} note() {} action() {} pair() {} destroy() {}
  row() { return node(); }
  field() { return { node: node() }; }
}
class Telemetry {
  message = '';
  view() {} protect() {} leave() {}
}
class MultiTouchView {
  constructor(_root, _action, back) { this.back = back; }
  destroy() { this.destroyed = true; }
}
globalThis.__androidBackTest = { sys, node, Page, Telemetry, MultiTouchView };
const url = source => 'data:text/javascript;base64,' + Buffer.from(source).toString('base64');
const engine = url(`
  export const { sys } = globalThis.__androidBackTest;
  export const _decorator = { ccclass: () => value => value };
  export class Component {} export class Color {} export class Camera {} export class Canvas {}
  export class EditBox {} export class Label {} export class Graphics {} export class UITransform {} export class Vec3 {}
  export class Node {} export class EventTouch {}
  Node.EventType = { TOUCH_START: 'touch-start' };
  export const Game = {}, Layers = {}, ResolutionPolicy = {}, director = {}, game = {}, profiler = {}, view = {}, tween = () => {};
`);
const ui = url(`
  export const { Page } = globalThis.__androidBackTest;
  export const box = () => globalThis.__androidBackTest.node(), text = () => ({}), button = () => {};
  export const theme = {};
`);
const compile = (name, imports) => {
  let source = ts.transpileModule(readFileSync(new URL(`../assets/scripts/${name}.ts`, import.meta.url), 'utf8'), {
    compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020, experimentalDecorators: true },
  }).outputText;
  for (const [specifier, value] of Object.entries(imports)) source = source.replace(`'${specifier}'`, JSON.stringify(value));
  return url(source);
};
const gameModel = compile('GameModel', {});
const gameView = compile('GameView', { cc: engine, './UI': ui, './GameModel': gameModel });
const { GameView } = await import(gameView);
const { Demo } = await import(compile('Demo', {
  cc: engine, './UI': ui, './GameView': gameView,
  './NativeHost': url('export const configStorage = {};'),
  './Api': url('export class Api { cancel() {} }'),
  './Config': url('export const readConfig = () => ({}), endpoint = () => {}, formConfig = () => {}, importConfig = () => {}, saveConfig = () => {}, settingFields = () => [], validateConfig = () => {};'),
  './Telemetry': url('export const { Telemetry } = globalThis.__androidBackTest; export const platform = () => "android", sdk = {};'),
  './NativePages': url('export class NativePages { pending = false; back = false; poll() {} consumeBack() { const result = this.back; this.back = false; return result; } }'),
  './MultiTouchView': url('export const { MultiTouchView } = globalThis.__androidBackTest;'),
}));

const back = value => { value.nativePages.back = true; value.update(0.12); };
function demo() {
  const value = new Demo(); value.root = node(); value.navigation = node(); value.status = {};
  return value;
}

test('system Back follows lab subpage parents, including the Replay-to-multitouch path', () => {
  const value = demo(); let destination;
  value.home = () => { destination = 'lobby'; };
  const lab = value.laboratory.bind(value);
  value.laboratory = () => { destination = 'lab'; lab(); };
  value.customView(); back(value); assert.equal(destination, 'lab');
  back(value); assert.equal(destination, 'lobby');
  value.multiTouchPage(); const touches = value.activeMultiTouch;
  back(value); assert.equal(destination, 'lab'); assert.equal(touches.destroyed, true);
  value.multiTouchPage(() => value.replayPage()); back(value);
  assert.equal(value.activeMultiTouch, undefined);
  destination = undefined; back(value); assert.equal(destination, 'lab');
});

test('native screens keep their Back handling and one request triggers one navigation', () => {
  const value = demo(); let calls = 0;
  value.backTarget = () => calls++;
  value.nativePages.pending = true; back(value); assert.equal(calls, 0);
  value.nativePages.pending = false; value.update(0.12); assert.equal(calls, 0);
  back(value); assert.equal(calls, 1);
  value.update(0.12); assert.equal(calls, 1);
});

test('game Back pauses for confirmation, then cancels the dialog without abandoning the round', () => {
  const value = demo(), events = [];
  const round = Object.create(GameView.prototype);
  round.node = node(); round.model = { paused: false, score: 30 };
  round.onAction = name => events.push(name);
  round.onExit = () => assert.fail('Back must not silently abandon the round');
  round.update = () => {};
  value.activeGame = round;
  back(value); assert.equal(round.model.paused, true);
  const overlay = round.pauseOverlay; assert.ok(overlay);
  back(value); assert.equal(round.model.paused, false); assert.equal(round.pauseOverlay, undefined);
  assert.equal(overlay.destroyed, true); assert.equal(overlay.active, false);
  assert.deepEqual(events, ['game_pause', 'game_resume']);
});

test('native presentation releases Cocos before opening and fallback re-enters a Cocos View', () => {
  const value = demo(), events = [];
  value.telemetry.leave = () => events.push('leave');
  value.telemetry.view = name => events.push(name);
  value.nativePages.open = () => { events.push('open'); return true; };
  value.home();
  assert.deepEqual(events, ['leave', 'open']);
  assert.equal(value.cocosView, undefined);
  events.length = 0;
  value.nativePages.open = () => { events.push('unavailable'); return false; };
  value.home();
  assert.deepEqual(events, ['leave', 'unavailable', 'CocosPreviewLobby']);
});

test('component visibility restores only visible Cocos pages and never steals a pending native View', () => {
  const value = demo(), events = [];
  value.telemetry.leave = () => events.push('leave');
  value.telemetry.view = name => events.push(name);
  value.show('Game', 'game'); value.onDisable(); value.onEnable();
  assert.deepEqual(events, ['Game', 'leave', 'Game']);
  events.length = 0;
  value.nativePages.pending = true; value.onEnable();
  assert.deepEqual(events, []);
  value.cocosView = undefined; value.nativePages.pending = false; value.onEnable();
  assert.deepEqual(events, []);
});
