import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';
const source = ts.transpileModule(readFileSync(new URL('../assets/scripts/GameModel.ts', import.meta.url), 'utf8'), {
  compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020 },
}).outputText;
const { GameModel } = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));

test('pause freezes movement, timer, spawning and collisions until resumed', () => {
  const game = new GameModel(() => 0.5); game.tick(0.1); game.paused = true;
  const before = JSON.stringify(game);
  game.move(100, 100); assert.deepEqual(game.tick(0.1), []); assert.equal(JSON.stringify(game), before);
  game.paused = false; game.tick(0.1); assert.equal(game.time, 0.2);
});
test('touch movement stays inside the arena', () => {
  const game = new GameModel(); game.move(9999, -9999);
  assert.deepEqual(game.player, { x: 280, y: -300 });
});
test('gem collisions award points once and build a streak bonus', () => {
  const game = new GameModel(() => 0.5);
  for (let i = 0; i < 5; i++) {
    game.items = [{ id: 100 + i, kind: 'gem', x: 0, y: -230, speed: 0 }];
    const events = game.tick(0.01); assert.equal(events.filter(e => e.type === 'collect').length, 1);
  }
  assert.equal(game.gems, 5); assert.equal(game.score, 60);
  game.items = []; game.tick(0.01); assert.equal(game.score, 60);
});
test('a hit grants temporary invulnerability and a depleted shield finishes exactly once', () => {
  const game = new GameModel(() => 0.5);
  const meteor = id => ({ id, kind: 'hazard', x: 0, y: -230, speed: 0 });
  game.items = [meteor(100), meteor(101)]; game.tick(0.01); assert.equal(game.lives, 2);
  game.tick(0.01); assert.equal(game.lives, 2);
  game.invulnerable = 0; game.items = [meteor(102)]; game.tick(0.01);
  game.invulnerable = 0; game.items = [meteor(103)];
  const events = game.tick(0.01); assert.equal(events.filter(e => e.type === 'finish').length, 1);
  assert.equal(game.result.reason, 'health'); assert.equal(game.lives, 0);
  assert.deepEqual(game.tick(0.1), []);
});
test('the timer ends a round at 45 seconds and ignores invalid frame deltas', () => {
  const game = new GameModel(() => 0); game.move(280, -300);
  game.tick(NaN); game.tick(-1); assert.equal(game.time, 0);
  for (let i = 0; i < 451; i++) game.tick(0.1);
  assert.equal(game.result.reason, 'time'); assert.equal(game.result.duration, 45);
  const before = JSON.stringify(game); game.move(0, 0); game.tick(1); assert.equal(JSON.stringify(game), before);
});
