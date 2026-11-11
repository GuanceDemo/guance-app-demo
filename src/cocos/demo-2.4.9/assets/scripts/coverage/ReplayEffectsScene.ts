const { Button, Color, Component, Graphics, Label, LabelOutline, LabelShadow, Node, Sprite, SpriteFrame, Texture2D, VideoPlayer, WebView, resources } = cc;
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { EffectsCase, EffectsState, ReplayEffectsCoverage } from './acceptance-components/ReplayEffectsCoverage';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

// Creator 2.4.9's declarations omit VideoClip and incorrectly type clip as string.
const VideoClip = (cc as unknown as { VideoClip: typeof cc.Asset }).VideoClip;
const { ccclass } = cc._decorator;
const BG = new Color(12, 18, 34);
const PANEL = new Color(27, 39, 64);
const TEXT = new Color(239, 244, 255);
const GREEN = new Color(44, 202, 178);

@ccclass('ReplayEffectsScene')
export class ReplayEffectsScene extends Component {
  private coverage?: ReplayEffectsCoverage;
  private frames: cc.SpriteFrame[] = [];
  private textures: cc.Texture2D[] = [];

  initialize(exit: () => void, track: (id: EffectsCase | 'page', stage: string) => void): void {
    const white = this.frame(false);
    this.panel(this.node, 'Background', 0, 0, 960, 640, BG, white);
    this.label(this.node, 'Replay effects + native overlays / batch 05', 0, 282, 920, 40, 26);
    this.label(this.node, 'Local fixtures only. Compare live native content against original SDK frames.', 0, 242, 920, 30, 16);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 430);
    const nodes: cc.Node[] = [];
    const privacy: ReplayPrivacy[] = [];
    const names: EffectsCase[] = ['Graphics', 'LabelOutline', 'LabelShadow', 'WebView', 'VideoPlayer'];
    const ys = [170, 95, 20, -55, -140];
    names.forEach((name, i) => {
      const y = ys[i]!;
      const height = i < 3 ? 54 : 64;
      this.label(group, `E0${i + 1} / ${name}`, -330, y, 245, 50, 19);
      this.panel(group, name + 'GuardTop', 0, y + height / 2 + 5, 358, 3, GREEN, white);
      this.panel(group, name + 'GuardBottom', 0, y - height / 2 - 5, 358, 3, GREEN, white);
      this.panel(group, name + 'GuardLeft', -179, y, 3, height + 10, GREEN, white);
      this.panel(group, name + 'GuardRight', 179, y, 3, height + 10, GREEN, white);
      const node = this.panel(group, name + 'Private', 0, y, 348, height, PANEL, white);
      nodes.push(node);
      const protection = node.addComponent(ReplayPrivacy);
      protection.enabled = false;
      privacy.push(protection);
    });
    const graphics = this.child(nodes[0]!, 'Graphics', 0, 0, 330, 50).addComponent(Graphics);
    const outlineText = this.label(nodes[1]!, 'DEMO OUTLINE', 0, 0, 330, 52, 30);
    const outline = outlineText.node.addComponent(LabelOutline);
    const shadowText = this.label(nodes[2]!, 'DEMO SHADOW', -4, 2, 330, 52, 30);
    const shadow = shadowText.node.addComponent(LabelShadow);
    this.label(group, 'Shapes / paths', 330, ys[0]!, 245, 50, 17);
    this.label(group, 'Magenta / cyan outline', 330, ys[1]!, 245, 50, 16);
    this.label(group, 'Yellow / blue shadow', 330, ys[2]!, 245, 50, 16);

    // Native overlays intentionally have no imitation Cocos text underneath.
    const webNode = this.child(nodes[3]!, 'LocalWebView', 0, 0, 332, 60);
    const web = webNode.addComponent(WebView);
    const webStatus = this.label(group, 'WebView loading', 330, ys[3]!, 245, 50, 16);
    webNode.on('loaded', () => { webStatus.string = 'Local WebView loaded'; });
    webNode.on('error', () => { webStatus.string = 'Local WebView error'; });
    const videoNode = this.child(nodes[4]!, 'LocalVideoPlayer', 0, 0, 332, 60);
    const video = videoNode.addComponent(VideoPlayer);
    video.resourceType = VideoPlayer.ResourceType.LOCAL;
    video.keepAspectRatio = false;
    // The bundled clip is silent; muting also permits browser autoplay.
    video.mute = true;
    const videoStatus = this.label(group, 'Local video loading', 330, ys[4]!, 245, 50, 16);
    let playing = true;
    let visible = true;
    videoNode.on('ready-to-play', () => { videoStatus.string = 'Local video ready'; if (playing && visible) video.play(); });
    videoNode.on('playing', () => { videoStatus.string = 'Local video playing'; });
    videoNode.on('paused', () => { videoStatus.string = 'Local video paused'; });
    videoNode.on('completed', () => { if (playing && visible) { video.currentTime = 0; video.play(); } });
    videoNode.on('error', () => { videoStatus.string = 'Local fixture unavailable'; });
    resources.load('replay-media/coverage', VideoClip, (error, clip) => {
      if (!this.isValid || !this.node.activeInHierarchy || !video.isValid) return;
      if (error) { videoStatus.string = 'Local video load failed'; console.error('[ReplayEffectsScene] video fixture', error); return; }
      (video as unknown as { clip: cc.Asset }).clip = clip;
    });
    const status = this.label(this.node, '', 0, -216, 920, 22, 15);
    let revision = -1;
    let wasPlaying = true;
    const apply = (state: Readonly<EffectsState>): void => {
      playing = state.playing;
      visible = state.visible;
      nodes.forEach((node, i) => {
        node.active = visible;
        privacy[i]!.mode = state.privacy === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask;
        privacy[i]!.enabled = state.privacy !== 'default';
      });
      group.setPosition(state.moved ? 28 : 0, state.moved ? -8 : 0);
      group.setScale(state.moved ? 0.85 : 1, state.moved ? 0.85 : 1, 1);
      // Redraw after reactivation; JSB does not retain every Graphics render buffer.
      graphics.clear();
      graphics.fillColor = state.revision % 2 ? new Color(230, 80, 160) : new Color(255, 180, 30);
      graphics.rect(-145, -17, state.revision % 2 ? 145 : 95, 34);
      graphics.fill();
      graphics.fillColor = new Color(40, 185, 235);
      graphics.circle(90, 0, state.revision % 2 ? 12 : 22);
      graphics.fill();
      graphics.strokeColor = GREEN;
      graphics.lineWidth = 4;
      graphics.moveTo(-30, -20); graphics.lineTo(10, 18); graphics.lineTo(45, -14); graphics.stroke();
      outline.color = state.revision % 2 ? new Color(20, 225, 240) : new Color(240, 40, 180);
      outline.width = state.revision % 2 ? 2 : 5;
      shadow.color = state.revision % 2 ? new Color(30, 150, 255) : new Color(250, 210, 30);
      shadow.offset = cc.v2(state.revision % 2 ? -5 : 5, -4);
      shadow.blur = state.revision % 2 ? 1 : 2;
      if (revision !== state.revision) {
        revision = state.revision;
        const html = '<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1"><body style="margin:0;background:' + (revision % 2 ? '#e060b0' : '#20dca0') + ';color:#102040;font: bold 22px sans-serif;text-align:center">LOCAL WEBVIEW ' + revision + '</body>';
        web.url = 'data:text/html;charset=utf-8,' + encodeURIComponent(html);
      }
      if (wasPlaying !== playing) { if (playing && visible) video.play(); else video.pause(); wasPlaying = playing; }
    };
    this.coverage = new ReplayEffectsCoverage({
      apply,
      status: text => { status.string = text; },
      command: (name, text, x, y, click) => {
        const node = this.panel(this.node, name, x, y, 218, 38, PANEL, white);
        node.addComponent(Button);
        node.on('click', click);
        this.label(node, text, 0, 0, 212, 34, 14);
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
