export type Pickup = { id: number; kind: 'gem' | 'hazard'; x: number; y: number; speed: number };
export type GameEvent = { type: 'collect' | 'hit' | 'finish'; x: number; y: number; score: number };
export type RoundResult = { score: number; gems: number; duration: number; reason: 'time' | 'health' };

/** Pure gameplay state. Rendering and telemetry consume events without changing the simulation. */
export class GameModel {
  readonly duration = 45;
  time = 0;
  score = 0;
  gems = 0;
  lives = 3;
  combo = 0;
  paused = false;
  result?: RoundResult;
  player = { x: 0, y: -230 };
  items: Pickup[] = [];
  invulnerable = 0;
  private spawnIn = 0;
  private sequence = 0;
  constructor(private random: () => number = Math.random) {}

  move(x: number, y: number): void {
    if (this.paused || this.result) return;
    this.player.x = Math.max(-280, Math.min(280, x));
    this.player.y = Math.max(-300, Math.min(280, y));
  }
  tick(dt: number): GameEvent[] {
    if (this.paused || this.result || !Number.isFinite(dt) || dt <= 0) return [];
    // Limit simulation jumps after a dropped frame; app backgrounding pauses the round separately.
    dt = Math.min(dt, 0.1);
    this.time = Math.min(this.duration, this.time + dt);
    this.invulnerable = Math.max(0, this.invulnerable - dt);
    const events: GameEvent[] = [];
    this.spawnIn -= dt;
    if (this.spawnIn <= 0) {
      this.spawnIn = Math.max(0.28, 0.65 - this.time * 0.006);
      const kind = ++this.sequence % 3 === 0 ? 'hazard' : 'gem';
      this.items.push({ id: this.sequence, kind, x: (this.random() * 2 - 1) * 265, y: 350,
        speed: (kind === 'hazard' ? 165 : 135) + this.time * 2 });
    }
    const remaining: Pickup[] = [];
    for (const item of this.items) {
      item.y -= item.speed * dt;
      const hit = Math.hypot(item.x - this.player.x, item.y - this.player.y) < (item.kind === 'gem' ? 39 : 42);
      if (hit && item.kind === 'gem') {
        this.gems++; this.combo++;
        this.score += 10 * Math.min(3, 1 + Math.floor(this.combo / 5));
        events.push({ type: 'collect', x: item.x, y: item.y, score: this.score });
      } else if (hit && item.kind === 'hazard' && this.invulnerable === 0) {
        this.lives--; this.combo = 0; this.invulnerable = 1.2;
        events.push({ type: 'hit', x: item.x, y: item.y, score: this.score });
        if (this.lives === 0) break;
      } else if (item.y > -370) remaining.push(item);
      else if (item.kind === 'gem') this.combo = 0;
    }
    this.items = remaining;
    if (this.lives === 0 || this.time >= this.duration) {
      this.result = { score: this.score, gems: this.gems, duration: Math.round(this.time * 10) / 10,
        reason: this.lives === 0 ? 'health' : 'time' };
      events.push({ type: 'finish', ...this.player, score: this.score });
    }
    return events;
  }
}
