import { _decorator, Button, Color, Component, Label, Layers, Node, RichText, Sprite, SpriteFrame, Texture2D, Toggle, UITransform } from 'cc';
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { BasicCase, BasicState, ReplayBasicCoverage, coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = _decorator;
const BG = new Color(12, 18, 34);
const PANEL = new Color(27, 39, 64);
const TEXT = new Color(239, 244, 255);
const GREEN = new Color(44, 202, 178);
const BLUE = new Color(45, 107, 205);

@ccclass('ReplayBasicScene')
export class ReplayBasicScene extends Component {
  private coverage?: ReplayBasicCoverage;
  private frames: SpriteFrame[] = [];
  private textures: Texture2D[] = [];

  initialize(exit: () => void, track: (id: BasicCase | 'page', stage: string) => void): void {
    const white = this.frame(false);
    const pattern = this.frame(true);
    this.panel(this.node, 'Background', 0, 0, 960, 640, BG, white);
    this.label(this.node, 'Replay basic controls / batch 02', 0, 282, 920, 40, 28);
    this.label(this.node, '5 real components. Public green borders must remain visible.', 0, 242, 920, 30, 17);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 390);
    const kinds: BasicCase[] = ['Label', 'RichText', 'Sprite', 'Button', 'Toggle'];
    const privateNodes: Node[] = [];
    const privacy: ReplayPrivacy[] = [];
    const bodies = kinds.map((kind, i) => {
      const row = this.child(group, kind + 'Case', 0, 175 - i * 72, 920, 64);
      this.label(row, `B0${i + 1} / ${kind}`, -330, 0, 240, 54, 20);
      this.label(row, ['Wrap / update', 'Color / bold / italic', 'Simple / sliced / filled', 'Tap / disabled', 'Checked / disabled'][i]!, 325, 0, 240, 54, 16);
      this.panel(row, 'PublicTop', 0, 30, 356, 3, GREEN, white);
      this.panel(row, 'PublicBottom', 0, -30, 356, 3, GREEN, white);
      this.panel(row, 'PublicLeft', -180, 0, 3, 58, GREEN, white);
      this.panel(row, 'PublicRight', 180, 0, 3, 58, GREEN, white);
      const body = this.panel(row, kind + 'Private', 0, 0, 348, 54, PANEL, white);
      privateNodes.push(body);
      const protection = body.addComponent(ReplayPrivacy);
      protection.enabled = false;
      privacy.push(protection);
      return body;
    });
    const label = this.label(bodies[0]!, '', 0, 0, 338, 54, 20);
    const richNode = this.child(bodies[1]!, 'RichText', 0, 0, 338, 54);
    const rich = richNode.addComponent(RichText);
    rich.fontSize = 20;
    rich.lineHeight = 24;
    rich.maxWidth = 338;
    rich.horizontalAlign = Label.HorizontalAlign.CENTER;
    const sprite = this.child(bodies[2]!, 'Sprite', 0, 0, 348, 54).addComponent(Sprite);
    sprite.sizeMode = Sprite.SizeMode.CUSTOM;
    sprite.spriteFrame = pattern;
    const button = bodies[3]!.addComponent(Button);
    this.buttonStyle(button, bodies[3]!);
    const buttonText = this.label(bodies[3]!, '', 0, 0, 338, 54, 20);
    bodies[3]!.on('click', () => this.coverage?.pressButton());
    const toggle = bodies[4]!.addComponent(Toggle);
    this.buttonStyle(toggle, bodies[4]!);
    const mark = this.panel(bodies[4]!, 'CheckMark', -135, 0, 22, 22, GREEN, white).getComponent(Sprite)!;
    toggle.checkMark = mark;
    const toggleText = this.label(bodies[4]!, '', 18, 0, 285, 54, 20);
    let applying = false;
    bodies[4]!.on('toggle', () => { if (!applying) this.coverage?.toggle(toggle.isChecked); });
    const status = this.label(this.node, '', 0, -196, 920, 30, 17);
    const apply = (state: Readonly<BasicState>): void => {
      applying = true;
      label.string = state.updated ? 'Two lines: DEMO-3141\nUpdated label / line two' : 'Label DEMO-3141';
      label.color = state.updated ? new Color(255, 207, 86) : TEXT;
      rich.string = state.updated ? '<color=#ff769e><b>UPDATED rich text</b></color>\n<color=#6ce0d5><i>Second styled line</i></color>' : '<color=#42d6bd><b>Rich DEMO-2718</b></color> <color=#ffbd44><i>italic</i></color>';
      sprite.type = [Sprite.Type.SIMPLE, Sprite.Type.SLICED, Sprite.Type.FILLED][state.spriteMode]!;
      sprite.fillType = Sprite.FillType.HORIZONTAL;
      sprite.fillStart = 0;
      sprite.fillRange = 0.55;
      sprite.color = state.updated ? new Color(180, 230, 255) : new Color(255, 255, 255);
      button.interactable = !state.disabled;
      toggle.interactable = !state.disabled;
      toggle.isChecked = state.checked;
      mark.node.active = state.checked;
      buttonText.string = `Tap count: ${state.clicks}${state.disabled ? ' / disabled' : ''}`;
      toggleText.string = `${state.checked ? 'Checked' : 'Unchecked'}${state.disabled ? ' / disabled' : ''}`;
      privateNodes.forEach((node, i) => {
        node.active = state.visible;
        privacy[i]!.mode = state.privacy === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask;
        privacy[i]!.enabled = state.privacy !== 'default';
      });
      group.setPosition(state.moved ? 28 : 0, state.moved ? -8 : 0);
      group.setScale(state.moved ? 0.85 : 1, state.moved ? 0.85 : 1, 1);
      applying = false;
    };
    this.coverage = new ReplayBasicCoverage({
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

  private buttonStyle(button: Button, node: Node): void {
    button.target = node;
    button.transition = Button.Transition.COLOR;
    button.normalColor = BLUE;
    button.pressedColor = new Color(230, 137, 52);
    button.hoverColor = new Color(60, 130, 215);
    button.disabledColor = new Color(90, 95, 105);
    button.duration = 0.05;
  }

  private frame(pattern: boolean): SpriteFrame {
    const texture = new Texture2D();
    texture.reset({ width: 32, height: 32, format: Texture2D.PixelFormat.RGBA8888 });
    texture.uploadData(coverageTexturePixels(pattern));
    const frame = new SpriteFrame();
    frame.texture = texture;frame.packable=false;
    frame.insetLeft = frame.insetRight = frame.insetTop = frame.insetBottom = 6;
    this.textures.push(texture);
    this.frames.push(frame);
    return frame;
  }

  private child(parent: Node, name: string, x: number, y: number, width: number, height: number): Node {
    const node = new Node(name);
    node.layer = Layers.Enum.UI_2D;
    node.addComponent(UITransform).setContentSize(width, height);
    node.setPosition(x, y);
    parent.addChild(node);
    return node;
  }

  private panel(parent: Node, name: string, x: number, y: number, width: number, height: number, color: Color, frame: SpriteFrame): Node {
    const node = this.child(parent, name, x, y, width, height);
    const sprite = node.addComponent(Sprite);
    sprite.sizeMode = Sprite.SizeMode.CUSTOM;
    sprite.spriteFrame = frame;
    sprite.color = color;
    return node;
  }

  private label(parent: Node, text: string, x: number, y: number, width: number, height: number, fontSize: number): Label {
    const node = this.child(parent, 'Label', x, y, width, height);
    const label = node.addComponent(Label);
    label.overflow = Label.Overflow.CLAMP;
    node.getComponent(UITransform)!.setContentSize(width, height);
    label.string = text;
    label.fontSize = fontSize;
    label.lineHeight = 24;
    label.color = TEXT;
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
