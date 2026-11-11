const { Animation, AnimationClip, Button, Color, Component, Label, Mask, MotionStreak, Node, ParticleSystem, SafeArea, Sprite, SpriteFrame, Texture2D, Toggle, ToggleContainer, Widget } = cc;
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { MotionState, ReplayMotionCoverage } from './acceptance-components/ReplayMotionCoverage';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = cc._decorator;
const BG = new Color(12, 18, 34);
const PANEL = new Color(27, 39, 64);
const TEXT = new Color(239, 244, 255);
const GREEN = new Color(44, 202, 178);

@ccclass('ReplayMotionScene')
export class ReplayMotionScene extends Component {
  private coverage?: ReplayMotionCoverage;
  private frames: cc.SpriteFrame[] = [];
  private textures: cc.Texture2D[] = [];
  private animate?: (dt: number) => void;
  private clip?: cc.AnimationClip;

  initialize(exit: () => void, track: (id: string, stage: string) => void): void {
    const white = this.frame(false);
    const pattern = this.frame(true);
    this.panel(this.node, 'Background', 0, 0, 960, 640, BG, white);
    this.label(this.node, 'Replay motion + safe area / batch 06', 0, 282, 920, 40, 26);
    this.label(this.node, 'Actual engine components. Particles and trails remain inside public green borders.', 0, 242, 920, 30, 16);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 430);
    const names = ['Animation', 'MotionStreak', 'ParticleSystem', 'SafeArea', 'ToggleContainer'];
    const ys = [170, 95, 20, -55, -140];
    const nodes: cc.Node[] = [];
    const privacy: ReplayPrivacy[] = [];
    names.forEach((name, i) => {
      const y = ys[i]!;
      this.label(group, `F0${i + 1} / ${name}`, -330, y, 245, 50, 18);
      this.panel(group, name + 'GuardTop', 0, y + 32, 358, 3, GREEN, white);
      this.panel(group, name + 'GuardBottom', 0, y - 32, 358, 3, GREEN, white);
      this.panel(group, name + 'GuardLeft', -179, y, 3, 64, GREEN, white);
      this.panel(group, name + 'GuardRight', 179, y, 3, 64, GREEN, white);
      const node = this.panel(group, name + 'Private', 0, y, 348, 54, PANEL, white);
      nodes.push(node);
      const protection = node.addComponent(ReplayPrivacy); protection.enabled = false; privacy.push(protection);
    });
    const animated = this.panel(nodes[0]!, 'AnimatedSprite', 0, 0, 290, 40, TEXT, white);
    const animation = animated.addComponent(Animation);
    const clip = AnimationClip.createWithSpriteFrames([white, pattern], 1);
    clip.name = 'CoverageFrames'; this.clip = clip;
    animation.addClip(clip);
    animation.play(clip.name);
    animation.pause();
    const frameText = this.label(group, '', 330, ys[0]!, 245, 50, 16);

    const trailNode = this.child(nodes[1]!, 'MotionStreak', 0, 0, 2, 2);
    const trail = trailNode.addComponent(MotionStreak);
    trail.texture = this.textures[0]!;
    trail.fadeTime = 1.5; trail.minSeg = 1; trail.stroke = 10;
    this.label(group, 'Continuous native trail', 330, ys[1]!, 245, 50, 16);
    const emitterNode = this.child(nodes[2]!, 'Particles', 0, 0, 2, 2);
    emitterNode.active = false;
    const particles = emitterNode.addComponent(ParticleSystem);
    particles.custom = true; particles.spriteFrame = white;
    particles.totalParticles = 48; particles.emissionRate = 24;
    particles.life = 1.2; particles.lifeVar = 0; particles.duration = -1;
    particles.posVar = cc.v2(115, 5);
    particles.speed = 7; particles.speedVar = 0;
    particles.angle = 0; particles.angleVar = 180;
    particles.gravity = cc.v2(0, 0);
    particles.startSize = 9; particles.startSizeVar = 0; particles.endSize = 6; particles.endSizeVar = 0;
    particles.startColorVar = new Color(0, 0, 0, 0); particles.endColorVar = new Color(0, 0, 0, 0);
    emitterNode.active = true;
    this.label(group, '48 max / local texture', 330, ys[2]!, 245, 50, 16);

    const safeViewport = this.child(nodes[3]!, 'SafeAreaViewport', 0, 0, 348, 54);
    safeViewport.addComponent(Mask);
    // SafeArea uses screen coordinates; clip its miniature inspection viewport.
    const safeNode = this.panel(safeViewport, 'SafeArea', 0, 0, 330, 44, new Color(45, 107, 205), white);
    safeNode.addComponent(Widget);
    const safe = safeNode.addComponent(SafeArea);
    this.label(safeNode, 'DEVICE SAFE AREA', 0, 0, 300, 40, 20);
    const safeText = this.label(group, '', 330, ys[3]!, 245, 50, 15);
    const togglesGroup = nodes[4]!.addComponent(ToggleContainer); togglesGroup.allowSwitchOff = false;
    const toggles: cc.Toggle[] = [];
    for (let i = 0; i < 2; i++) {
      const choice = this.panel(nodes[4]!, 'Legacy' + i, -80 + i * 160, 0, 140, 40, new Color(45, 107, 205), white);
      choice.active = false;
      const toggle = choice.addComponent(Toggle); toggle.isChecked = i === 0;
      toggle.checkMark = this.panel(choice, 'Check', -43, 0, 16, 20, GREEN, white).getComponent(Sprite)!;
      this.label(choice, i ? 'B' : 'A', 10, 0, 80, 32, 20); toggles.push(toggle); choice.active = true;
    }
    const extraText = this.label(group, 'Container mutual exclusion', 330, ys[4]!, 245, 50, 15);
    const status = this.label(this.node, '', 0, -216, 920, 22, 14);
    let current: Readonly<MotionState> = { variant: 0, running: true, visible: true, moved: false, privacy: 'default' };
    let running = true; let variant = -1; let wasVisible = true; let elapsed = 0;
    const apply = (state: Readonly<MotionState>): void => {
      current = state;
      nodes.forEach((node, i) => { node.active = state.visible; privacy[i]!.mode = state.privacy === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask; privacy[i]!.enabled = state.privacy !== 'default'; });
      group.setPosition(state.moved ? 28 : 0, state.moved ? -8 : 0);
      group.setScale(state.moved ? 0.85 : 1, state.moved ? 0.85 : 1, 1);
      animation.setCurrentTime(state.variant ? 1.1 : 0.1, clip.name); (animation as cc.Animation & { sample(name: string): void }).sample(clip.name);
      frameText.string = state.variant ? 'Animation frame B' : 'Animation frame A';
      trail.color = state.variant ? new Color(230, 65, 170) : new Color(250, 185, 30);
      if (variant !== state.variant || running !== state.running || (!wasVisible && state.visible)) {
        variant = state.variant; running = state.running;
        const color = state.variant ? new Color(225, 65, 175) : new Color(250, 185, 30);
        particles.startColor = color; particles.endColor = color;
        if (state.running && state.visible) particles.resetSystem(); else particles.stopSystem();
        trail.reset();
      }
      wasVisible = state.visible;
      safe.updateArea();
      safeText.string = Math.round(safeNode.width) + ' x ' + Math.round(safeNode.height) + ' / no notch';
      toggles[state.variant]!.isChecked = true; extraText.string = 'Selected: ' + 'AB'[state.variant];
    };
    this.animate = (dt: number) => {
      if (!current.running || !current.visible) return;
      elapsed += Math.min(dt, 0.1);
      trailNode.setPosition(125 * Math.cos(elapsed * 1.7), 10 * Math.sin(elapsed * 3.4));
    };
    this.coverage = new ReplayMotionCoverage({ apply, status: text => { status.string = text; }, command: (name, text, x, y, click) => {
      const node = this.panel(this.node, name, x, y, 218, 38, PANEL, white); node.addComponent(Button); node.on('click', click); this.label(node, text, 0, 0, 212, 34, 13);
    } }, track, exit);
  }

  update(dt: number): void { this.animate?.(dt); }

  private frame(pattern: boolean): cc.SpriteFrame {
    const texture = new Texture2D();
    texture.initWithData(coverageTexturePixels(pattern), Texture2D.PixelFormat.RGBA8888, 32, 32);
    const frame = new SpriteFrame(texture);
    frame.insetLeft = frame.insetRight = frame.insetTop = frame.insetBottom = 6;
    this.textures.push(texture);
    this.frames.push(frame);
    return frame;
  }

  private child(parent: cc.Node, name: string, x: number, y: number, width: number, height: number): cc.Node {
    const node = new Node(name);
    node.setContentSize(width, height);
    node.setPosition(x, y);
    parent.addChild(node);
    return node;
  }

  private panel(parent: cc.Node, name: string, x: number, y: number, width: number, height: number, color: cc.Color, frame: cc.SpriteFrame): cc.Node {
    const node = this.child(parent, name, x, y, width, height);
    const sprite = node.addComponent(Sprite);
    sprite.sizeMode = Sprite.SizeMode.CUSTOM;
    sprite.spriteFrame = frame;
    node.color = color;
    return node;
  }

  private label(parent: cc.Node, text: string, x: number, y: number, width: number, height: number, fontSize: number): cc.Label {
    const node = this.child(parent, 'Label', x, y, width, height);
    const label = node.addComponent(Label);
    label.overflow = Label.Overflow.CLAMP;
    node.setContentSize(width, height);
    label.string = text;
    label.fontSize = fontSize;
    label.lineHeight = 24;
    node.color = TEXT;
    label.horizontalAlign = Label.HorizontalAlign.CENTER;
    label.verticalAlign = Label.VerticalAlign.CENTER;
    return label;
  }

  onDestroy(): void {
    this.coverage?.dispose();
    this.animate = undefined;
    this.clip?.destroy();
    this.frames.forEach(frame => frame.destroy());
    this.textures.forEach(texture => texture.destroy());
  }
}
