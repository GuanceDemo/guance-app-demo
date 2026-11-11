const { Button, Color, Component, Label, Mask, Node, ProgressBar, Scrollbar, ScrollView, Slider, Sprite, SpriteFrame, Texture2D } = cc;
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { ScrollCase, ScrollState, ReplayScrollCoverage } from './acceptance-components/ReplayScrollCoverage';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = cc._decorator;
const BG = new Color(12, 18, 34);
const PANEL = new Color(27, 39, 64);
const TEXT = new Color(239, 244, 255);
const GREEN = new Color(44, 202, 178);
const BLUE = new Color(45, 107, 205);

@ccclass('ReplayScrollScene')
export class ReplayScrollScene extends Component {
  private coverage?: ReplayScrollCoverage;
  private frames: cc.SpriteFrame[] = [];
  private textures: cc.Texture2D[] = [];

  initialize(exit: () => void, track: (id: ScrollCase | 'page', stage: string) => void): void {
    const white = this.frame(false);
    const pattern = this.frame(true);
    this.panel(this.node, 'Background', 0, 0, 960, 640, BG, white);
    this.label(this.node, 'Replay scrolling + clipping / batch 03', 0, 282, 920, 40, 28);
    this.label(this.node, 'Drag the slider and list. Public green borders remain visible.', 0, 242, 920, 30, 17);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 430);
    const privateNodes: cc.Node[] = [];
    const privacy: ReplayPrivacy[] = [];
    const body = (kind: ScrollCase, x: number, y: number, width: number, height: number): cc.Node => {
      this.panel(group, kind + 'GuardTop', x, y + height / 2 + 5, width + 10, 3, GREEN, white);
      this.panel(group, kind + 'GuardBottom', x, y - height / 2 - 5, width + 10, 3, GREEN, white);
      this.panel(group, kind + 'GuardLeft', x - width / 2 - 5, y, 3, height + 10, GREEN, white);
      this.panel(group, kind + 'GuardRight', x + width / 2 + 5, y, 3, height + 10, GREEN, white);
      const node = this.panel(group, kind + 'Private', x, y, width, height, PANEL, white);
      privateNodes.push(node);
      const protection = node.addComponent(ReplayPrivacy);
      protection.enabled = false;
      privacy.push(protection);
      return node;
    };
    this.label(group, 'C01 / Slider', -330, 178, 240, 46, 20);
    const sliderBody = body('Slider', 0, 178, 348, 46);
    const sliderNode = this.child(sliderBody, 'Slider', 0, 0, 304, 40);
    this.panel(sliderNode, 'Track', 0, 0, 304, 6, BLUE, white);
    const handle = this.panel(sliderNode, 'Handle', 0, 0, 24, 34, GREEN, white);
    const slider = sliderNode.addComponent(Slider);
    // Runtime-created sliders bind handle events when enabled.
    slider.enabled = false;
    slider.handle = handle.addComponent(Button);
    slider.direction = Slider.Direction.Horizontal;
    slider.enabled = true;
    sliderNode.on('slide', () => this.coverage?.slide(slider.progress));
    const progressText = this.label(group, '', 330, 178, 240, 46, 20);

    this.label(group, 'C02 / ProgressBar', -330, 100, 240, 46, 20);
    const progressBody = body('ProgressBar', 0, 100, 348, 46);
    this.panel(progressBody, 'Track', 0, 0, 314, 20, BG, white);
    const progressNode = this.child(progressBody, 'ProgressBar', 0, 0, 314, 20);
    const fill = this.panel(progressNode, 'Fill', 0, 0, 314, 20, BLUE, white).getComponent(Sprite)!;
    const progress = progressNode.addComponent(ProgressBar);
    progress.mode = ProgressBar.Mode.HORIZONTAL;
    progress.barSprite = fill;
    progress.totalLength = 314;
    this.label(group, 'Linked to slider', 330, 100, 240, 46, 18);

    this.label(group, 'C03 / ScrollView', -335, -28, 240, 50, 20);
    const scrollBody = body('ScrollView', -28, -28, 292, 148);
    const viewport = this.child(scrollBody, 'Viewport', 0, 0, 292, 148);
    viewport.addComponent(Mask).type = Mask.Type.RECT;
    const content = this.child(viewport, 'Content', 0, 74, 292, 320);
    content.setAnchorPoint(0.5, 1);
    for (let i = 0; i < 8; i++) {
      const row = this.panel(content, 'Row' + i, 0, -20 - i * 40, 280, 36, i % 2 ? BLUE : new Color(71, 62, 115), white);
      this.label(row, `DEMO row 0${i + 1} / clip edges`, 0, 0, 274, 36, 18);
    }
    const scroll = scrollBody.addComponent(ScrollView);
    scroll.content = content;
    scroll.horizontal = false;
    scroll.vertical = true;
    scroll.inertia = false;
    scroll.elastic = false;
    scrollBody.on('scroll-ended', () => this.coverage?.scrolled());
    const barBody = body('ScrollBar', 154, -28, 24, 148);
    const bar = barBody.addComponent(Scrollbar);
    bar.direction = Scrollbar.Direction.VERTICAL;
    bar.enableAutoHide = false;
    bar.handle = this.panel(barBody, 'Handle', 0, 0, 12, 56, GREEN, white).getComponent(Sprite)!;
    scroll.verticalScrollBar = bar;
    this.label(group, 'C04 / ScrollBar', 330, -28, 240, 50, 20);

    this.label(group, 'C05 / Mask', -330, -160, 240, 54, 20);
    const maskBody = body('Mask', 0, -160, 348, 58);
    const clip = this.child(maskBody, 'Clip', 0, 0, 260, 52);
    const mask = clip.addComponent(Mask);
    this.panel(clip, 'OversizedPattern', 0, 0, 440, 92, TEXT, pattern);
    this.label(clip, 'CLIPPED DEMO', 0, 0, 340, 32, 20);
    const maskText = this.label(group, '', 330, -160, 240, 54, 18);
    const status = this.label(this.node, '', 0, -208, 920, 24, 16);
    let appliedScrollRevision = -1;
    const apply = (state: Readonly<ScrollState>): void => {
      slider.progress = state.progress;
      progress.progress = state.progress;
      progressText.string = `${Math.round(state.progress * 100)}% / drag handle`;
      mask.type = state.ellipse ? Mask.Type.ELLIPSE : Mask.Type.RECT;
      maskText.string = state.ellipse ? 'Ellipse clip' : 'Rectangle clip';
      privateNodes.forEach((node, i) => {
        node.active = state.visible;
        privacy[i]!.mode = state.privacy === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask;
        privacy[i]!.enabled = state.privacy !== 'default';
      });
      group.setPosition(state.moved ? 28 : 0, state.moved ? -8 : 0);
      group.setScale(state.moved ? 0.85 : 1);
      if (appliedScrollRevision !== state.scrollRevision) {
        appliedScrollRevision = state.scrollRevision;
        if (state.bottom) scroll.scrollToBottom(0); else scroll.scrollToTop(0);
      }
    };
    this.coverage = new ReplayScrollCoverage({
      apply,
      status: text => { status.string = text; },
      command: (name, text, x, y, click) => {
        const node = this.panel(this.node, name, x, y, 218, 38, PANEL, white);
        node.addComponent(Button);
        node.on('click', click);
        this.label(node, text, 0, 0, 212, 34, 15);
      },
    }, track, exit);
  }

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
    this.frames.forEach(frame => frame.destroy());
    this.textures.forEach(texture => texture.destroy());
  }
}
