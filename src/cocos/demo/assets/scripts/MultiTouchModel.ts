export interface TouchPoint { x: number; y: number }
export interface TouchTrace { id: number; color: number; points: TouchPoint[] }
interface Pose extends TouchPoint { scale: number; angle: number }

/** Independent touch ownership; the oldest two active fingers drive the card. */
export class MultiTouchModel {
  readonly active = new Map<number, TouchTrace>();
  readonly completed: TouchTrace[] = [];
  pose: Pose = { x: 0, y: 0, scale: 1, angle: 0 };
  peak = 0;
  starts = 0;
  ends = 0;
  cancels = 0;
  private gesture?: { a: TouchPoint; b: TouchPoint; pose: Pose };

  start(id: number, point: TouchPoint): boolean {
    if (this.active.has(id) || this.active.size >= 5) return false;
    // Creator's loose spread transform assumes arrays; materialize Map iterators explicitly.
    const used = new Set(Array.from(this.active.values(), touch => touch.color));
    let color = 0; while (used.has(color)) ++color;
    this.active.set(id, { id, color, points: [this.clamp(point)] });
    ++this.starts; this.peak = Math.max(this.peak, this.active.size);
    this.rebase(); return true;
  }
  move(id: number, point: TouchPoint): void {
    const touch = this.active.get(id); if (!touch) return;
    const next = this.clamp(point), last = touch.points[touch.points.length - 1];
    if (next.x === last.x && next.y === last.y) return;
    touch.points.push(next);
    if (touch.points.length > 80) touch.points.shift();
    const pair = this.pair(); if (!pair || !this.gesture) return;
    const [a, b] = pair, base = this.gesture;
    const distance = Math.hypot(base.b.x - base.a.x, base.b.y - base.a.y);
    const nextDistance = Math.hypot(b.x - a.x, b.y - a.y);
    // Rebase a coincident pair before it can create unstable scale or angles.
    if (distance < 12 || nextDistance < 12) { this.rebase(); return; }
    const delta = Math.atan2(b.y - a.y, b.x - a.x) - Math.atan2(base.b.y - base.a.y, base.b.x - base.a.x);
    this.pose = {
      x: Math.max(-180, Math.min(180, base.pose.x + (a.x + b.x - base.a.x - base.b.x) / 2)),
      y: Math.max(-200, Math.min(200, base.pose.y + (a.y + b.y - base.a.y - base.b.y) / 2)),
      scale: Math.max(0.5, Math.min(2, base.pose.scale * (nextDistance / distance))),
      angle: base.pose.angle + Math.atan2(Math.sin(delta), Math.cos(delta)) * 180 / Math.PI,
    };
    this.rebase();
  }
  end(id: number, cancelled = false): boolean {
    const touch = this.active.get(id); if (!touch) return false;
    this.completed.push(touch); if (this.completed.length > 5) this.completed.shift();
    this.active.delete(id);
    if (cancelled) ++this.cancels; else ++this.ends;
    this.rebase(); return true;
  }
  reset(): void {
    this.active.clear(); this.completed.length = 0; this.gesture = undefined;
    this.pose = { x: 0, y: 0, scale: 1, angle: 0 };
    this.peak = this.starts = this.ends = this.cancels = 0;
  }
  private clamp(point: TouchPoint): TouchPoint {
    return { x: Math.max(-300, Math.min(300, point.x)), y: Math.max(-280, Math.min(280, point.y)) };
  }
  private pair(): TouchPoint[] | undefined {
    const touches = Array.from(this.active.values());
    return touches.length < 2 ? undefined : touches.slice(0, 2).map(touch => touch.points[touch.points.length - 1]);
  }
  private rebase(): void {
    const pair = this.pair();
    this.gesture = pair ? { a: pair[0], b: pair[1], pose: { ...this.pose } } : undefined;
  }
}
