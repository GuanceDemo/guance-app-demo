import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';
const source = ts.transpileModule(readFileSync(new URL('../assets/scripts/MultiTouchModel.ts', import.meta.url), 'utf8'), {
  compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020 },
}).outputText;
const { MultiTouchModel } = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
const point = (x, y = 0) => ({ x, y });
const near = (actual, expected) => assert.ok(Math.abs(actual - expected) < 0.00001, `${actual} != ${expected}`);

test('crossing fingers keep their IDs, colors and independent paths', () => {
  const model = new MultiTouchModel(); model.start(0, point(-100)); model.start(7, point(100));
  model.move(0, point(150)); model.move(7, point(-150));
  assert.deepEqual(model.active.get(0).points, [point(-100), point(150)]);
  assert.deepEqual(model.active.get(7).points, [point(100), point(-150)]);
  assert.notEqual(model.active.get(0).color, model.active.get(7).color);
  model.end(0); model.move(7, point(-200));
  assert.equal(model.active.size, 1); assert.equal(model.active.get(7).points.at(-1).x, -200);
  assert.equal(model.peak, 2); assert.equal(model.ends, 1);
});
test('two fingers translate, pinch and rotate the card', () => {
  const model = new MultiTouchModel(); model.start(1, point(-50)); model.start(2, point(50));
  model.move(1, point(-100)); model.move(2, point(100));
  near(model.pose.scale, 2); near(model.pose.x, 0);
  model.reset(); model.start(1, point(-50)); model.start(2, point(50));
  model.move(1, point(0, -50)); model.move(2, point(0, 50));
  near(model.pose.angle, 90); near(model.pose.scale, 1);
  model.move(1, point(20, -30)); model.move(2, point(20, 70));
  near(model.pose.x, 20); near(model.pose.y, 20);
});
test('a third finger draws independently and replacement of a gesture finger does not jump', () => {
  const model = new MultiTouchModel(); model.start(1, point(-50)); model.start(2, point(50));
  model.move(2, point(100)); const before = { ...model.pose };
  model.start(3, point(200, 100)); model.move(3, point(200, 150));
  assert.deepEqual(model.pose, before);
  model.end(1, true); assert.deepEqual(model.pose, before);
  model.move(2, point(100)); assert.deepEqual(model.pose, before);
  assert.equal(model.cancels, 1); assert.equal(model.active.size, 2);
});
test('duplicate, excess and stale events cannot steal active touches', () => {
  const model = new MultiTouchModel();
  for (let id = 0; id < 5; id++) assert.equal(model.start(id, point(id * 20)), true);
  assert.equal(new Set([...model.active.values()].map(touch => touch.color)).size, 5);
  assert.equal(model.start(0, point(200)), false); assert.equal(model.start(10, point(200)), false);
  model.move(10, point(0)); assert.equal(model.end(10), false);
  assert.equal(model.starts, 5); assert.equal(model.peak, 5);
  model.end(0, true); assert.equal(model.end(0), false);
  assert.equal(model.start(10, point(100)), true);
  assert.equal(new Set([...model.active.values()].map(touch => touch.color)).size, 5);
});
test('coincident fingers remain finite and trails and positions stay bounded', () => {
  const model = new MultiTouchModel(); model.start(1, point(0)); model.start(2, point(0));
  for (let i = 0; i < 1000; i++) model.move(1, point(i, -i));
  assert.ok(Object.values(model.pose).every(Number.isFinite));
  assert.equal(model.active.get(1).points.length, 80);
  assert.deepEqual(model.active.get(1).points.at(-1), point(300, -280));
  for (let i = 0; i < 20; i++) { model.start(3, point(i)); model.end(3); }
  assert.equal(model.completed.length, 5);
});
test('cancellation and reset leave no stuck fingers and stale moves are ignored', () => {
  const model = new MultiTouchModel(); model.start(1, point(-50)); model.start(2, point(50));
  for (const id of [...model.active.keys()]) model.end(id, true);
  assert.equal(model.cancels, 2); assert.equal(model.active.size, 0);
  model.reset(); model.move(1, point(200)); model.end(2);
  assert.equal(model.active.size, 0); assert.equal(model.completed.length, 0);
  assert.deepEqual(model.pose, { x: 0, y: 0, scale: 1, angle: 0 });
  assert.equal(model.starts + model.ends + model.cancels + model.peak, 0);
  assert.equal(model.start(1, point(0)), true);
});
