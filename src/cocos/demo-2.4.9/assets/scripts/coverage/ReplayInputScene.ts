import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { InputCase, InputKind, InputPhase, ReplayInputCoverage, ReplayInputUI } from './acceptance-components/ReplayInputCoverage';

const { ccclass } = cc._decorator;
const BACKGROUND = new cc.Color(12, 18, 34);
const PANEL = new cc.Color(27, 39, 64);
const TEXT = new cc.Color(239, 244, 255);
const GREEN = new cc.Color(44, 202, 178);
const RED = new cc.Color(180, 50, 70);

@ccclass('ReplayInputScene')
export class ReplayInputScene extends cc.Component {
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
        node.addComponent(cc.Button);
        node.on('click', click);
        this.label(node, text, 0, 0, 210, 32, 16);
      },
      status: text => { status.string = text; },
      transform: moved => {
        group.setPosition(moved ? 35 : 0, moved ? -12 : 0);
        group.setScale(moved ? 0.85 : 1, moved ? 0.85 : 1);
      },
    };
    this.coverage = new ReplayInputCoverage(ui, track, exit);
  }

  private input(parent: cc.Node, id: InputCase, kind: InputKind, y: number, phase: (phase: InputPhase) => void) {
    const row = this.child(parent, id, 0, y, 900, 76);
    this.label(row, `${id} / ${kind}`, -320, 0, 230, 40, 21);
    this.label(row, id === 'I04' ? 'Dynamic + ReplayPrivacy' : 'Automatic EditBox mask', 310, 0, 240, 40, 16);
    // Guards are siblings of the private node so over-masking is visible.
    this.box(row, 'PublicGuardTop', 0, 26, 356, 4, GREEN);
    this.box(row, 'PublicGuardBottom', 0, -26, 356, 4, GREEN);
    this.box(row, 'PublicGuardLeft', -180, 0, 4, 48, GREEN);
    this.box(row, 'PublicGuardRight', 180, 0, 4, 48, GREEN);
    const node = this.child(row, `${id}-EditBox`, 0, 0, 348, 44);
    const background = this.box(node, 'InputBackground', 0, 0, 348, 44, RED);
    const edit = node.addComponent(cc.EditBox);
    // Creator 2's editor-only property notifications do not create labels at runtime.
    edit.textLabel = this.label(node, '', -169, 22, 338, 44, 20);
    edit.placeholderLabel = this.label(node, '', -169, 22, 338, 44, 20);
    edit.inputMode = cc.EditBox.InputMode.SINGLE_LINE;
    edit.inputFlag = kind === 'password' ? cc.EditBox.InputFlag.PASSWORD : kind === 'sensitive' ? cc.EditBox.InputFlag.SENSITIVE : cc.EditBox.InputFlag.DEFAULT;
    edit.maxLength = 32;
    edit.placeholder = 'Enter fictional text';
    [edit.textLabel, edit.placeholderLabel].forEach(label => {
      label.node.setAnchorPoint(0, 1);
      label.node.setPosition(-169, 22);
      label.node.setContentSize(338, 44);
      label.fontSize = 20;
      label.lineHeight = 26;
      label.node.color = TEXT;
      label.horizontalAlign = cc.Label.HorizontalAlign.LEFT;
      label.verticalAlign = cc.Label.VerticalAlign.CENTER;
    });
    node.on('editing-did-began', () => phase('focus'));
    node.on('text-changed', () => phase('changed'));
    node.on('editing-did-ended', () => phase('blur'));
    node.on('editing-return', () => phase('return'));
    let privacy: ReplayPrivacy | undefined;
    return {
      setValue: (value: string) => { edit.string = value; },
      setPassword: (revealed: boolean) => {
        edit.inputFlag = revealed ? cc.EditBox.InputFlag.DEFAULT : cc.EditBox.InputFlag.PASSWORD;
        // Refresh through the public setter; inputFlag's notify hook runs only in the editor.
        edit.string = edit.string;
      },
      setVisible: (visible: boolean) => {
        node.active = visible;
        // Graphics render data can be discarded while an EditBox is inactive.
        if (visible) {
          const graphics = background.getComponent(cc.Graphics)!;
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

  private child(parent: cc.Node, name: string, x: number, y: number, width: number, height: number): cc.Node {
    const node = new cc.Node(name);
    node.setPosition(x, y);
    node.setContentSize(width, height);
    parent.addChild(node);
    return node;
  }

  private box(parent: cc.Node, name: string, x: number, y: number, width: number, height: number, color: cc.Color): cc.Node {
    const node = this.child(parent, name, x, y, width, height);
    const graphics = node.addComponent(cc.Graphics);
    graphics.fillColor = color;
    graphics.rect(-width / 2, -height / 2, width, height);
    graphics.fill();
    return node;
  }

  private label(parent: cc.Node, text: string, x: number, y: number, width: number, height: number, fontSize: number): cc.Label {
    const node = this.child(parent, 'PublicLabel', x, y, width, height);
    const label = node.addComponent(cc.Label);
    label.overflow = cc.Label.Overflow.CLAMP;
    node.setContentSize(width, height);
    label.string = text;
    label.fontSize = fontSize;
    label.lineHeight = Math.ceil(fontSize * 1.3);
    label.node.color = TEXT;
    label.horizontalAlign = cc.Label.HorizontalAlign.CENTER;
    label.verticalAlign = cc.Label.VerticalAlign.CENTER;
    return label;
  }

  onDestroy(): void { this.coverage?.dispose(); }
}
