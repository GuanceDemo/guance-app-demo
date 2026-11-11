import ReplayPrivacy from '../../guance-cocos-sdk/ReplayPrivacy';
const { ccclass } = cc._decorator;

@ccclass('ReplayVersionDiffScene')
export class ReplayVersionDiffScene extends cc.Component {
  private textures: cc.Texture2D[] = [];
  private frames: cc.SpriteFrame[] = [];
  private elapsed = 0;
  private running = true;
  private revision = 0;
  private shown = true;
  private moved = false;
  private hits = 0;
  private trailNode!: cc.Node;
  private trail!: cc.MotionStreak;
  private report?: (stage: string) => void;

  initialize(exit: () => void, track: (id: string, stage: string) => void): void {
    const white = this.frame(false), pattern = this.frame(true);
    this.panel(this.node, 'Background', 0, 0, 960, 640, cc.color(12, 18, 34), white);
    this.label(this.node, `Creator ${cc.ENGINE_VERSION} / six changed components`, 0, 282, 940, 36, 24);
    this.label(this.node, 'Actual components / local SDK original frames / privacy disabled on targets', 0, 246, 940, 26, 15);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 430);
    const names = ['Label', 'RichText', 'Sprite', 'MotionStreak', 'ParticleSystem', 'SafeArea'];
    const bodies: cc.Node[] = [];
    names.forEach((name, i) => {
      const y = 180 - i * 60;
      this.label(group, name, -330, y, 250, 42, 20);
      this.panel(group, name + 'Border', 0, y, 364, 50, cc.color(44, 202, 178), white);
      const body = this.panel(group, name + 'Target', 0, y, 356, 44, cc.color(27, 39, 64), white);
      body.addComponent(ReplayPrivacy).enabled = false;
      bodies.push(body);
    });
    const label = this.label(bodies[0]!, '', 0, 0, 344, 42, 20);
    const richNode = this.child(bodies[1]!, 'ClickableRichText', 0, 0, 340, 42);
    const rich = richNode.addComponent(cc.RichText);
    rich.fontSize = 20; rich.lineHeight = 24; rich.maxWidth = 340;
    rich.horizontalAlign = cc.macro.TextAlignment.CENTER;
    const hitText = this.label(group, 'clicks: 0', 325, 120, 240, 42, 18);
    (rich as any).richTap249 = () => { this.hits++; hitText.string = 'clicks: ' + this.hits; this.report!('rich-click'); };
    const sprite = this.child(bodies[2]!, 'TextureSwapSprite', 0, 0, 334, 36).addComponent(cc.Sprite);
    sprite.sizeMode = cc.Sprite.SizeMode.CUSTOM;
    this.trailNode = this.child(bodies[3]!, 'NativeMotionStreak', 0, 0, 2, 2);
    this.trail = this.trailNode.addComponent(cc.MotionStreak);
    this.trail.texture = this.textures[0]!; this.trail.fadeTime = 1.3; this.trail.minSeg = 1; this.trail.stroke = 9;
    const particleNode = this.child(bodies[4]!, 'NativeParticleSystem', 0, 0, 2, 2);
    particleNode.active = false;
    const particles = particleNode.addComponent(cc.ParticleSystem);
    particles.custom = true; particles.spriteFrame = white; particles.totalParticles = 40; particles.emissionRate = 30;
    particles.life = 1; particles.lifeVar = 0; particles.duration = -1; particles.posVar = cc.v2(130, 8);
    particles.speed = 4; particles.speedVar = 0; particles.gravity = cc.v2(0, 0);
    particles.startSize = 9; particles.startSizeVar = 0; particles.endSize = 7; particles.endSizeVar = 0;
    particles.startColorVar = particles.endColorVar = cc.color(0, 0, 0, 0);
    particleNode.active = true;
    const viewport = this.child(bodies[5]!, 'ClippedSafeAreaViewport', 0, 0, 348, 40);
    viewport.addComponent(cc.Mask);
    const safeNode = this.panel(viewport, 'ActualSafeArea', 0, 0, 330, 38, cc.color(45, 107, 205), white);
    safeNode.addComponent(cc.Widget);
    const safe = safeNode.addComponent(cc.SafeArea);
    const safeReadout = this.label(group, '', 325, -120, 250, 46, 14);
    this.label(group, 'text + color update', 325, 180, 250, 42, 15);
    this.label(group, 'texture A / B + re-enable', 325, 60, 250, 42, 14);
    this.label(group, 'native moving trail', 325, 0, 250, 42, 15);
    this.label(group, 'real emitted particles', 325, -60, 250, 42, 15);
    const status = this.label(this.node, '', 0, -184, 940, 30, 15);
    this.report = stage => {
      const state = { engine: cc.ENGINE_VERSION, stage, revision: this.revision, shown: this.shown, moved: this.moved, running: this.running, richClicks: this.hits,
        label: label.string, spriteFrame: this.revision % 2 ? 'pattern-B' : 'white-A', spriteActive: sprite.enabledInHierarchy,
        motionStreak: { enabled: this.trail.enabledInHierarchy, pointCount: (this.trail as any)._points.length, position: { x: this.trailNode.x, y: this.trailNode.y } },
        particles: { enabled: particles.enabledInHierarchy, count: particles.particleCount, active: particles.active },
        safeArea: { enabled: safe.enabledInHierarchy, width: safeNode.width, height: safeNode.height, rect: cc.sys.getSafeAreaRect() },
        privacy: bodies.map(n => ({ name: n.name, enabled: n.getComponent(ReplayPrivacy)!.enabledInHierarchy })) };
      status.string = `${stage} / revision ${this.revision} / shown ${this.shown} / rich clicks ${this.hits}`;
      console.log('[Replay249] ' + JSON.stringify(state)); track('six-components', stage);
    };
    const apply = (stage: string) => {
      bodies.forEach(n => n.active = this.shown);
      group.setPosition(this.moved ? 24 : 0, this.moved ? -8 : 0); group.setScale(this.moved ? 0.88 : 1);
      label.string = this.revision % 2 ? 'UPDATED DEMO-249 / line B' : 'Label DEMO-249 / line A';
      label.node.color = this.revision % 2 ? cc.color(255, 118, 158) : cc.color(239, 244, 255);
      rich.string = this.revision % 2 ? '<color=#ff769e><b click="richTap249">TAP UPDATED rich B</b></color>' : '<color=#42d6bd><b click="richTap249">TAP rich DEMO A</b></color>';
      sprite.spriteFrame = this.revision % 2 ? pattern : white;
      sprite.node.color = this.revision % 2 ? cc.color(255, 255, 255) : cc.color(250, 185, 30);
      this.trail.color = this.revision % 2 ? cc.color(230, 65, 170) : cc.color(250, 185, 30);
      particles.startColor = particles.endColor = this.trail.color;
      this.trail.reset(); this.elapsed = 0;
      if (this.running && this.shown) particles.resetSystem(); else particles.stopSystem();
      if (this.shown) safe.updateArea();
      safeReadout.string = `${Math.round(safeNode.width)} x ${Math.round(safeNode.height)}\nactual SafeArea + Widget`;
      this.report!(stage);
      this.scheduleOnce(() => this.report && this.report(stage + '-settled'), 1);
    };
    const commands: Array<[string, () => void]> = [
      ['Change content / texture', () => { this.revision++; apply('changed'); }],
      ['Reset trail + particles', () => apply('effects-reset')],
      ['Move + scale', () => { this.moved = !this.moved; apply('transformed'); }],
      ['Hide / show targets', () => { this.shown = !this.shown; apply(this.shown ? 'shown' : 'hidden'); }],
      ['Refresh SafeArea', () => { safe.updateArea(); apply('safe-area-refreshed'); }],
      ['Stop / resume effects', () => { this.running = !this.running; apply(this.running ? 'running' : 'stopped'); }],
      ['Reset all', () => { this.revision = 0; this.shown = true; this.moved = false; this.running = true; this.hits = 0; hitText.string = 'clicks: 0'; apply('reset'); }],
      ['Back to sample', () => { this.report!('exit'); exit(); }],
    ];
    commands.forEach(([text, click], i) => {
      const n = this.panel(this.node, 'Command' + i, -345 + (i % 4) * 230, i < 4 ? -230 : -282, 218, 40, cc.color(45, 107, 205), white);
      n.addComponent(cc.Button); n.on('click', click); this.label(n, text, 0, 0, 212, 36, 14);
    });
    apply('entered');
  }
  update(dt: number): void {
    if (!this.running || !this.shown || !this.trailNode) return;
    this.elapsed += Math.min(dt, 0.1);
    this.trailNode.setPosition(126 * Math.cos(this.elapsed * 1.8), 9 * Math.sin(this.elapsed * 3.6));
  }
  private frame(pattern: boolean): cc.SpriteFrame {
    const pixels = new Uint8Array(32 * 32 * 4);
    for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) {
      const c = pattern ? ((Math.floor(x / 4) + Math.floor(y / 4)) % 2 ? [40, 185, 235] : [230, 65, 170]) : [255, 255, 255];
      const i = (y * 32 + x) * 4; pixels.set([c[0]!, c[1]!, c[2]!, 255], i);
    }
    const t = new cc.Texture2D(); t.initWithData(pixels, cc.Texture2D.PixelFormat.RGBA8888, 32, 32);
    const f = new cc.SpriteFrame(t); this.textures.push(t); this.frames.push(f); return f;
  }
  private child(parent: cc.Node, name: string, x: number, y: number, w: number, h: number): cc.Node {
    const n = new cc.Node(name); n.setContentSize(w, h); n.setPosition(x, y); parent.addChild(n); return n;
  }
  private panel(parent: cc.Node, name: string, x: number, y: number, w: number, h: number, color: cc.Color, frame: cc.SpriteFrame): cc.Node {
    const n = this.child(parent, name, x, y, w, h); const s = n.addComponent(cc.Sprite); s.sizeMode = cc.Sprite.SizeMode.CUSTOM; s.spriteFrame = frame; n.color = color; return n;
  }
  private label(parent: cc.Node, text: string, x: number, y: number, w: number, h: number, size: number): cc.Label {
    const n = this.child(parent, 'Label', x, y, w, h); const l = n.addComponent(cc.Label);
    l.overflow = cc.Label.Overflow.CLAMP; n.setContentSize(w, h); l.string = text; l.fontSize = size; l.lineHeight = size + 3;
    l.horizontalAlign = cc.Label.HorizontalAlign.CENTER; l.verticalAlign = cc.Label.VerticalAlign.CENTER; n.color = cc.color(239, 244, 255); return l;
  }
  onDestroy(): void { this.report = undefined; this.frames.forEach(f => f.destroy()); this.textures.forEach(t => t.destroy()); }
}
