import { Color, EventTouch, Graphics, Label, Node, UITransform, Vec3, tween, view } from 'cc';
import { box, button, text, theme } from './UI';
import { GameModel, RoundResult } from './GameModel';

const mint = new Color(92, 242, 197), red = new Color(255, 111, 131), gold = new Color(255, 220, 118);
export class GameView {
  readonly node: Node;
  readonly model = new GameModel();
  private arena: Node;
  private ship: Node;
  private hud: Label;
  private hint: Label;
  private pauseOverlay?: Node;
  private sprites = new Map<number, Node>();
  private stars: Node[] = [];
  private elapsed = 0;
  private finished = false;
  constructor(parent: Node, private onFinish: (result: RoundResult) => void,
    private onAction: (name: string, attributes: Record<string, number | string>) => void, private onExit: () => void) {
    this.node = box(parent, 'CrystalDashGame', 0, -5, 664, 936, new Color(12, 22, 42));
    this.hud = text(this.node, '', 0, 420, 610, 56, 25, theme.ink);
    this.arena = box(this.node, 'TouchArena', 0, 35, 620, 720, new Color(9, 17, 33));
    for (let i = 0; i < 32; i++) {
      const star = box(this.arena, 'Star', ((i * 137) % 580) - 290, ((i * 199) % 680) - 340, 3, 3);
      const g = star.addComponent(Graphics); g.fillColor = new Color(88, 117, 157, 150); g.circle(0, 0, i % 3 === 0 ? 2 : 1); g.fill();
      this.stars.push(star);
    }
    this.ship = box(this.arena, 'PlayerShip', 0, -230, 50, 58);
    const g = this.ship.addComponent(Graphics);
    g.fillColor = mint; g.moveTo(0, 29); g.lineTo(23, -22); g.lineTo(0, -11); g.lineTo(-23, -22); g.close(); g.fill();
    g.fillColor = new Color(236, 255, 251); g.circle(0, 1, 6); g.fill();
    const move = (event: EventTouch) => {
      const point = event.getUILocation();
      // This demo's camera and Canvas are centered at world (0, 0), while UI touches use a bottom-left origin.
      const design = view.getDesignResolutionSize();
      const local = this.arena.getComponent(UITransform)!.convertToNodeSpaceAR(new Vec3(point.x - design.width / 2, point.y - design.height / 2));
      this.model.move(local.x, local.y);
    };
    this.arena.on(Node.EventType.TOUCH_START, (event: EventTouch) => { move(event); this.onAction('game_drag', { score: this.model.score }); });
    this.arena.on(Node.EventType.TOUCH_MOVE, move);
    this.hint = text(this.node, 'DRAG TO FLY  ·  Collect gems. Dodge meteors.', 0, -355, 610, 44, 20, theme.muted);
    button(this.node, 'Pause', -160, -420, 292, 62, () => this.pause());
    button(this.node, 'Leave round', 160, -420, 292, 62, () => this.pause(true));
    this.renderHud();
  }
  pause(exit = false): void {
    if (this.model.result || this.pauseOverlay) return;
    this.model.paused = true;
    this.onAction('game_pause', { score: this.model.score });
    const panel = this.pauseOverlay = box(this.node, 'PauseOverlay', 0, 20, 610, 360, theme.paper);
    text(panel, exit ? 'Leave this round?' : 'Round paused', 0, 105, 540, 64, 34);
    text(panel, 'Your timer is paused.', 0, 40, 540, 48, 23, theme.muted);
    button(panel, 'Resume game', 0, -40, 530, 64, () => {
      panel.destroy(); this.pauseOverlay = undefined; this.model.paused = false;
      this.onAction('game_resume', { score: this.model.score });
    }, true);
    button(panel, 'Back to native lobby', 0, -120, 530, 60, () => {
      this.onAction('game_abandon', { score: this.model.score }); this.onExit();
    });
    // Prevent touches on the modal background from reaching the game arena.
    panel.on(Node.EventType.TOUCH_START, (event: EventTouch) => { event.propagationStopped = true; });
  }
  update(dt: number): void {
    if (this.finished) return;
    const events = this.model.tick(dt);
    if (!this.model.paused) {
      this.elapsed += dt;
      this.stars.forEach((star, i) => { const y = star.position.y - dt * (12 + i % 4 * 10); star.setPosition(star.position.x, y < -350 ? 350 : y); });
    }
    this.ship.setPosition(this.model.player.x, this.model.player.y);
    this.ship.setScale(this.model.invulnerable > 0 && Math.floor(this.elapsed * 12) % 2 === 0 ? 0.72 : 1, 1, 1);
    const live = new Set(this.model.items.map(item => item.id));
    for (const [id, sprite] of this.sprites) if (!live.has(id)) { sprite.destroy(); this.sprites.delete(id); }
    for (const item of this.model.items) {
      let sprite = this.sprites.get(item.id);
      if (!sprite) {
        sprite = box(this.arena, item.kind === 'gem' ? 'CollectibleGem' : 'Meteor', item.x, item.y, 44, 44);
        const g = sprite.addComponent(Graphics);
        g.fillColor = item.kind === 'gem' ? mint : red;
        if (item.kind === 'gem') { g.moveTo(0, 22); g.lineTo(17, 0); g.lineTo(0, -22); g.lineTo(-17, 0); g.close(); }
        else { for (let i = 0; i < 7; i++) { const a = i * Math.PI * 2 / 7; const r = i % 2 ? 22 : 27; i ? g.lineTo(Math.cos(a) * r, Math.sin(a) * r) : g.moveTo(Math.cos(a) * r, Math.sin(a) * r); } g.close(); }
        g.fill(); g.fillColor = new Color(255, 255, 255, 130); g.circle(-5, 6, 4); g.fill();
        this.sprites.set(item.id, sprite);
      }
      sprite.setPosition(item.x, item.y); sprite.angle = Math.sin(this.elapsed * 3 + item.id) * 15;
    }
    this.renderHud();
    for (const event of events) {
      if (event.type === 'finish') {
        this.finished = true;
        this.onFinish(this.model.result!);
        return;
      }
      this.onAction(event.type === 'collect' ? 'game_collect' : 'game_hit', { score: event.score, gems: this.model.gems, lives: this.model.lives });
      for (let i = 0; i < 8; i++) {
        const p = box(this.arena, 'Burst', event.x, event.y, 6, 6);
        const g = p.addComponent(Graphics); g.fillColor = event.type === 'collect' ? gold : red; g.circle(0, 0, 4); g.fill();
        const a = i * Math.PI / 4;
        tween(p).to(0.35, { position: new Vec3(event.x + Math.cos(a) * 58, event.y + Math.sin(a) * 58), scale: new Vec3(0, 0, 0) }).call(() => p.destroy()).start();
      }
    }
  }
  private renderHud(): void {
    this.hud.string = `SCORE ${this.model.score}     ${Math.ceil(this.model.duration - this.model.time)}s     ${'♥'.repeat(this.model.lives)}`;
    if (this.model.combo >= 5) this.hint.string = `COMBO ${this.model.combo}  ·  ${Math.min(3, 1 + Math.floor(this.model.combo / 5))}× gem bonus`;
    else this.hint.string = 'DRAG TO FLY  ·  Collect gems. Dodge meteors.';
  }
  destroy(): void { this.node.active = false; this.node.destroy(); }
}
