import { Color, EventTouch, Graphics, Label, Mask, Node, UITransform, Vec3, macro, view } from 'cc';
import { box, button, text, theme } from './UI';
import { MultiTouchModel, TouchPoint } from './MultiTouchModel';

const colors = [theme.primary, new Color(111, 181, 255), new Color(255, 220, 118), theme.danger, new Color(198, 151, 255)];

export class MultiTouchView {
  readonly node: Node;
  private model = new MultiTouchModel();
  private arena: Node;
  private trails: Graphics;
  private card: Node;
  private hud: Label;
  private detail: Label;
  private markers = new Map<number, Node>();
  private previousMultiTouch = macro.ENABLE_MULTI_TOUCH;

  constructor(parent: Node, private onAction: (name: string, attributes: Record<string, number | string>) => void,
    onExit: () => void) {
    macro.ENABLE_MULTI_TOUCH = true;
    this.node = box(parent, 'MultiTouchReplay', 0, -5, 664, 936);
    text(this.node, 'Multi-touch Replay', 0, 424, 630, 52, 34);
    text(this.node, 'Drag 2–5 fingers. Cross paths, lift one, then rejoin.\nThe first two fingers move, pinch and rotate the card.', 0, 358, 630, 76, 22, theme.muted);
    this.hud = text(this.node, '', 0, 288, 630, 54, 22);
    // A fixed arena avoids ScrollView stealing gestures or cancelling sibling touches.
    this.arena = box(this.node, 'MultiTouchArena', 0, -26, 620, 580, theme.paper);
    const clipped = box(this.arena, 'ClippedDrawing', 0, 0, 620, 580);
    clipped.addComponent(Mask).type = Mask.Type.GRAPHICS_RECT;
    this.card = box(clipped, 'GestureCard', 0, 0, 136, 100, theme.pale);
    text(this.card, '↑\nPINCH / ROTATE', 0, 0, 124, 90, 21, theme.primary).horizontalAlign = Label.HorizontalAlign.CENTER;
    this.trails = box(clipped, 'FingerTrails', 0, 0, 620, 580).addComponent(Graphics);
    this.arena.on(Node.EventType.TOUCH_START, this.startTouch, this);
    this.arena.on(Node.EventType.TOUCH_MOVE, this.moveTouch, this);
    this.arena.on(Node.EventType.TOUCH_END, this.endTouch, this);
    this.arena.on(Node.EventType.TOUCH_CANCEL, this.cancelTouch, this);
    this.detail = text(this.node, '', 0, -358, 630, 70, 21, theme.muted);
    button(this.node, 'Reset', -166, -426, 308, 64, () => {
      this.cancelActive(); this.model.reset(); this.render(); this.onAction('multitouch_reset', {});
    });
    button(this.node, 'Back to lab', 166, -426, 308, 64, onExit);
    this.render();
  }
  private point(event: EventTouch): TouchPoint {
    const point = event.getUILocation(), design = view.getDesignResolutionSize();
    return this.arena.getComponent(UITransform)!.convertToNodeSpaceAR(new Vec3(point.x - design.width / 2, point.y - design.height / 2));
  }
  private startTouch(event: EventTouch): void {
    const id = event.getID(); if (id === null) return;
    if (this.model.start(id, this.point(event))) this.report('start', id);
    this.render();
  }
  private moveTouch(event: EventTouch): void {
    const id = event.getID(); if (id === null) return;
    this.model.move(id, this.point(event)); this.render();
  }
  private endTouch(event: EventTouch): void { this.finishTouch(event, false); }
  private cancelTouch(event: EventTouch): void { this.finishTouch(event, true); }
  private finishTouch(event: EventTouch, cancelled: boolean): void {
    const id = event.getID(); if (id === null) return;
    if (!cancelled) this.model.move(id, this.point(event));
    if (this.model.end(id, cancelled)) this.report(cancelled ? 'cancel' : 'end', id);
    this.render();
  }
  private report(phase: string, id: number): void {
    this.onAction(`multitouch_${phase}`, { touch_id: id, active_touches: this.model.active.size, peak_touches: this.model.peak });
  }
  cancelActive(): void {
    for (const id of Array.from(this.model.active.keys())) { this.model.end(id, true); this.report('cancel', id); }
    this.render();
  }
  private render(): void {
    const model = this.model;
    this.hud.string = `ACTIVE ${model.active.size} / 5    PEAK ${model.peak}    DOWN ${model.starts}    UP ${model.ends}    CANCEL ${model.cancels}`;
    this.detail.string = `Scale ${model.pose.scale.toFixed(2)}×  ·  Rotation ${Math.round(model.pose.angle)}°\nHold gestures briefly for Replay. Use a real multi-touch device.`;
    this.card.setPosition(model.pose.x, model.pose.y); this.card.setScale(model.pose.scale, model.pose.scale, 1); this.card.angle = model.pose.angle;
    this.trails.clear();
    for (const trace of model.completed.concat(Array.from(model.active.values()))) {
      const active = model.active.get(trace.id) === trace, color = colors[trace.color];
      this.trails.strokeColor = new Color(color.r, color.g, color.b, active ? 255 : 75);
      this.trails.lineWidth = active ? 5 : 3;
      trace.points.forEach((point, i) => i ? this.trails.lineTo(point.x, point.y) : this.trails.moveTo(point.x, point.y));
      this.trails.stroke();
    }
    for (const [id, marker] of this.markers) if (!model.active.has(id)) {
      marker.active = false; marker.destroy(); this.markers.delete(id);
    }
    for (const [id, trace] of model.active) {
      let marker = this.markers.get(id);
      if (!marker) {
        marker = box(this.arena, `Finger-${id}`, 0, 0, 76, 76);
        const g = marker.addComponent(Graphics); g.fillColor = colors[trace.color]; g.circle(0, 0, 27); g.fill();
        text(marker, String(id), 0, 0, 48, 48, 23, theme.paper).horizontalAlign = Label.HorizontalAlign.CENTER;
        this.markers.set(id, marker);
      }
      const point = trace.points[trace.points.length - 1]; marker.setPosition(point.x, point.y);
    }
  }
  destroy(): void {
    this.cancelActive(); macro.ENABLE_MULTI_TOUCH = this.previousMultiTouch;
    this.node.active = false; this.node.destroy();
  }
}
