import { _decorator, Button, Color, Component, EditBox, Graphics, Label, Layers, Node, UITransform } from 'cc';
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { InputCase, InputKind, InputPhase, ReplayInputCoverage, ReplayInputUI } from './acceptance-components/ReplayInputCoverage';

const { ccclass } = _decorator;
const BACKGROUND = new Color(12, 18, 34);
const PANEL = new Color(27, 39, 64);
const TEXT = new Color(239, 244, 255);
const GREEN = new Color(44, 202, 178);
const RED = new Color(180, 50, 70);

@ccclass('ReplayInputScene')
export class ReplayInputScene extends Component {
  private coverage?: ReplayInputCoverage;

  initialize(exit: () => void, track: (id: InputCase | 'page', stage: string) => void): void {
    this.box(this.node, 'Background', 0, 0, 960, 640, BACKGROUND);
    this.label(this.node, 'Replay input coverage', 0, 278, 900, 40, 30);
    this.label(this.node, 'Use fictional text only. Replay must cover inputs; green edges must remain visible.', 0, 237, 930, 28, 17);
    const group = this.child(this.node, 'InputCases', 0, 0, 960, 360);
    const status = this.label(this.node, '', 0, -195, 920, 32, 17);
    const ui: ReplayInputUI = {
      input: (id, kind, y, phase) => this.input(group, id, kind, y, phase),
      button: (name, text, x, y, click) => {
        const node = this.box(this.node, name, x, y, 218, 38, PANEL);
        node.addComponent(Button);
        node.on(Button.EventType.CLICK, click);
        this.label(node, text, 0, 0, 210, 32, 16);
      },
      status: text => { status.string = text; },
      transform: moved => {
        group.setPosition(moved ? 35 : 0, moved ? -12 : 0);
        group.setScale(moved ? 0.85 : 1, moved ? 0.85 : 1, 1);
      },
    };
    this.coverage = new ReplayInputCoverage(ui, track, exit);
  }

  private input(parent: Node, id: InputCase, kind: InputKind, y: number, phase: (phase: InputPhase) => void) {
    const row = this.child(parent, id, 0, y, 900, 76);
    this.label(row, `${id} / ${kind}`, -320, 0, 230, 40, 21);
    this.label(row, id === 'I04' ? 'Dynamic + ReplayPrivacy' : 'Automatic EditBox mask', 310, 0, 240, 40, 16);
    // Guards are siblings of the private node so over-masking is visible.
    this.box(row, 'PublicGuardTop', 0, 26, 356, 4, GREEN);
    this.box(row, 'PublicGuardBottom', 0, -26, 356, 4, GREEN);
    this.box(row, 'PublicGuardLeft', -180, 0, 4, 48, GREEN);
    this.box(row, 'PublicGuardRight', 180, 0, 4, 48, GREEN);
    const node = this.child(row, `${id}-EditBox`, 0, 0, 348, 44);
    // EditBox owns a Sprite on its node; Graphics must use a separate child renderer.
    const background = this.box(node, 'InputBackground', 0, 0, 348, 44, RED);
    const edit = node.addComponent(EditBox);
    edit.inputMode = EditBox.InputMode.SINGLE_LINE;
    edit.inputFlag = kind === 'password' ? EditBox.InputFlag.PASSWORD : kind === 'sensitive' ? EditBox.InputFlag.SENSITIVE : EditBox.InputFlag.DEFAULT;
    edit.maxLength = 32;
    edit.placeholder = 'Enter fictional text';
    // EditBox creates and positions its own text and placeholder labels.
    [edit.textLabel, edit.placeholderLabel].forEach(label => {
      if (!label) return;
      label.fontSize = 20;
      label.lineHeight = 26;
      label.overflow = Label.Overflow.CLAMP;
      label.node.getComponent(UITransform)!.setAnchorPoint(0, 1);
      label.node.getComponent(UITransform)!.setContentSize(338, 44);
      label.color = TEXT;
      label.horizontalAlign = Label.HorizontalAlign.LEFT;
      label.verticalAlign = Label.VerticalAlign.CENTER;
    });
    node.on('editing-did-began', () => phase('focus'));
    node.on('text-changed', () => phase('changed'));
    node.on('editing-did-ended', () => phase('blur'));
    node.on('editing-return', () => phase('return'));
    let privacy: ReplayPrivacy | undefined;
    return {
      setValue: (value: string) => { edit.string = value; },
      setPassword: (revealed: boolean) => { edit.inputFlag = revealed ? EditBox.InputFlag.DEFAULT : EditBox.InputFlag.PASSWORD; },
      setVisible: (visible: boolean) => {
        node.active = visible;
        // Graphics render data can be discarded while an EditBox is inactive.
        if (visible) {
          const graphics = background.getComponent(Graphics)!;
          graphics.clear();
          graphics.fillColor = RED;
          graphics.rect(-174, -22, 348, 44);
          graphics.fill();
        }
      },
      setPrivacy: (mode: 'default' | 'mask' | 'hide') => {
        if (mode === 'default') { if (privacy) privacy.enabled = false; return; }
        if (!privacy) privacy = node.addComponent(ReplayPrivacy);
        privacy.enabled = true;
        privacy.mode = mode === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask;
      },
      blur: () => edit.blur(),
      destroy: () => { row.active = false; row.destroy(); },
    };
  }

  private child(parent: Node, name: string, x: number, y: number, width: number, height: number): Node {
    const node = new Node(name);
    node.layer = Layers.Enum.UI_2D;
    node.setPosition(x, y);
    node.addComponent(UITransform).setContentSize(width, height);
    parent.addChild(node);
    return node;
  }

  private box(parent: Node, name: string, x: number, y: number, width: number, height: number, color: Color): Node {
    const node = this.child(parent, name, x, y, width, height);
    const graphics = node.addComponent(Graphics);
    graphics.fillColor = color;
    graphics.rect(-width / 2, -height / 2, width, height);
    graphics.fill();
    return node;
  }

  private label(parent: Node, text: string, x: number, y: number, width: number, height: number, fontSize: number): Label {
    const node = this.child(parent, 'PublicLabel', x, y, width, height);
    const label = node.addComponent(Label);
    label.overflow = Label.Overflow.CLAMP;
    node.getComponent(UITransform)!.setContentSize(width, height);
    label.string = text;
    label.fontSize = fontSize;
    label.lineHeight = Math.ceil(fontSize * 1.3);
    label.color = TEXT;
    label.horizontalAlign = Label.HorizontalAlign.CENTER;
    label.verticalAlign = Label.VerticalAlign.CENTER;
    return label;
  }

  onDestroy(): void { this.coverage?.dispose(); }
}
