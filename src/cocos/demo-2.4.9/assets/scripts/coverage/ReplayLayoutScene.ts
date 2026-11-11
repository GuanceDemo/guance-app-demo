const { Button, Color, Component, Label, Layout, Mask, Node, PageView, PageViewIndicator, Size, Sprite, SpriteFrame, Texture2D, Toggle, ToggleContainer, Widget } = cc;
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { LayoutCase, LayoutState, ReplayLayoutCoverage } from './acceptance-components/ReplayLayoutCoverage';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = cc._decorator;
const BG = new Color(12, 18, 34);
const PANEL = new Color(27, 39, 64);
const TEXT = new Color(239, 244, 255);
const GREEN = new Color(44, 202, 178);
const BLUE = new Color(45, 107, 205);

@ccclass('ReplayLayoutScene')
export class ReplayLayoutScene extends Component {
  private coverage?: ReplayLayoutCoverage;
  private frames: cc.SpriteFrame[] = [];
  private textures: cc.Texture2D[] = [];

  initialize(exit: () => void, track: (id: LayoutCase | 'page', stage: string) => void): void {
    const white = this.frame(false);
    this.panel(this.node, 'Background', 0, 0, 960, 640, BG, white);
    this.label(this.node, 'Replay pages + layout / batch 04', 0, 282, 920, 40, 28);
    this.label(this.node, 'Swipe pages and select A / B / C. Public green borders remain visible.', 0, 242, 920, 30, 16);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 430);
    const privateNodes: cc.Node[] = [];
    const privacy: ReplayPrivacy[] = [];
    const body = (kind: LayoutCase, y: number, height: number): cc.Node => {
      this.panel(group, kind + 'GuardTop', 0, y + height / 2 + 5, 358, 3, GREEN, white);
      this.panel(group, kind + 'GuardBottom', 0, y - height / 2 - 5, 358, 3, GREEN, white);
      this.panel(group, kind + 'GuardLeft', -179, y, 3, height + 10, GREEN, white);
      this.panel(group, kind + 'GuardRight', 179, y, 3, height + 10, GREEN, white);
      const node = this.panel(group, kind + 'Private', 0, y, 348, height, PANEL, white);
      privateNodes.push(node);
      const protection = node.addComponent(ReplayPrivacy);
      protection.enabled = false;
      privacy.push(protection);
      return node;
    };
    this.label(group, 'D01 / PageView', -330, 160, 240, 60, 20);
    const pageBody = body('PageView', 160, 106);
    const pageNode = this.child(pageBody, 'PageView', 0, 0, 326, 92);
    pageNode.active = false;
    const viewport = this.child(pageNode, 'Viewport', 0, 0, 326, 92);
    // The default is rectangular; JSB cannot update Mask type before activation.
    viewport.addComponent(Mask);
    const content = this.child(viewport, 'Content', -163, 0, 326, 92);
    content.setAnchorPoint(0, 0.5);
    const pagesLayout = content.addComponent(Layout);
    pagesLayout.type = Layout.Type.HORIZONTAL;
    pagesLayout.resizeMode = Layout.ResizeMode.CONTAINER;
    const pageColors = [BLUE, new Color(174, 96, 35), new Color(107, 69, 173)];
    for (let i = 0; i < 3; i++) {
      const page = this.panel(content, 'Page' + i, 0, 0, 326, 92, pageColors[i]!, white);
      this.label(page, `DEMO PAGE ${i + 1} / 3`, 0, 10, 310, 30, 24);
      this.label(page, 'Swipe left / right', 0, -23, 310, 24, 16);
    }
    pagesLayout.updateLayout();
    const pager = pageNode.addComponent(PageView);
    pager.content = content;
    pager.direction = PageView.Direction.Horizontal;
    pager.sizeMode = PageView.SizeMode.Unified;
    pager.pageTurningSpeed = 0.15;
    pager.scrollThreshold = 0.2;
    pageNode.on('page-turning', () => this.coverage?.turned(pager.getCurrentPageIndex()));
    const pageText = this.label(group, '', 330, 160, 240, 60, 18);

    this.label(group, 'D02 / PageViewIndicator', -330, 78, 250, 40, 18);
    const indicatorBody = body('PageViewIndicator', 78, 28);
    const indicatorNode = this.child(indicatorBody, 'Indicator', 0, 0, 100, 16);
    indicatorNode.active = false;
    const indicator = indicatorNode.addComponent(PageViewIndicator);
    indicator.spriteFrame = white;
    indicator.cellSize = new Size(16, 12);
    indicator.spacing = 14;
    indicatorNode.active = true;
    pager.indicator = indicator;
    pageNode.active = true;
    this.label(group, 'Active dot follows page', 330, 78, 240, 40, 16);

    this.label(group, 'D03 / ToggleContainer', -330, 10, 250, 50, 18);
    const toggleBody = body('ToggleContainer', 10, 50);
    const choices = this.child(toggleBody, 'Choices', 0, 0, 330, 44);
    choices.active = false;
    let applying = false;
    const toggles: cc.Toggle[] = [];
    for (let i = 0; i < 3; i++) {
      const choice = this.panel(choices, 'Choice' + i, -108 + i * 108, 0, 98, 38, BLUE, white);
      const toggle = choice.addComponent(Toggle);
      const mark = this.panel(choice, 'CheckMark', -31, 0, 14, 18, GREEN, white).getComponent(Sprite)!;
      toggle.checkMark = mark;
      toggle.isChecked = i === 0;
      this.label(choice, 'ABC'[i]!, 13, 0, 50, 34, 20);
      choice.on('toggle', () => { if (!applying && toggle.isChecked) this.coverage?.selected(i); });
      toggles.push(toggle);
    }
    choices.addComponent(ToggleContainer).allowSwitchOff = false;
    choices.active = true;
    const choiceText = this.label(group, '', 330, 10, 240, 50, 18);

    this.label(group, 'D04 / Layout', -330, -70, 240, 60, 20);
    const layoutBody = body('Layout', -70, 82);
    const layoutNode = this.child(layoutBody, 'Layout', 0, 0, 310, 72);
    const tiles: cc.Node[] = [];
    const tileLabels: cc.Label[] = [];
    for (let i = 0; i < 4; i++) {
      const tile = this.panel(layoutNode, 'Tile' + i, 0, 0, 62, 28, pageColors[i % 3]!, white);
      tiles.push(tile);
      tileLabels.push(this.label(tile, 'ABCD'[i]!, 0, 0, 58, 28, 14));
    }
    const layout = layoutNode.addComponent(Layout);
    layout.resizeMode = Layout.ResizeMode.NONE;
    layout.paddingLeft = layout.paddingRight = 6;
    layout.paddingTop = layout.paddingBottom = 2;
    const layoutText = this.label(group, '', 330, -70, 240, 60, 18);

    this.label(group, 'D05 / Widget', -330, -164, 240, 60, 20);
    const widgetBody = body('Widget', -164, 64);
    const aligned = this.panel(widgetBody, 'Aligned', 0, 0, 84, 34, BLUE, white);
    const widgetLabel = this.label(aligned, 'DEMO', 0, 0, 80, 32, 18);
    const widget = aligned.addComponent(Widget);
    widget.alignMode = Widget.AlignMode.ALWAYS;
    widget.isAlignVerticalCenter = true;
    widget.verticalCenter = 0;
    const widgetText = this.label(group, '', 330, -164, 240, 60, 18);
    const status = this.label(this.node, '', 0, -216, 920, 22, 15);
    let pageRevision = -1;
    let selectionRevision = -1;
    let layoutMode = -1;
    const apply = (state: Readonly<LayoutState>): void => {
      applying = true;
      pageText.string = `Page ${state.page + 1} / 3`;
      choiceText.string = `Selected: ${'ABC'[state.selected]}`;
      if (selectionRevision !== state.selectionRevision) {
        selectionRevision = state.selectionRevision;
        toggles.forEach((toggle, i) => { toggle.isChecked = i === state.selected; });
      }
      if (layoutMode !== state.layout) {
        layoutMode = state.layout;
        const column = state.layout === 1;
        layoutNode.setContentSize(state.layout === 2 ? 180 : 310, 72);
        layout.type = [Layout.Type.HORIZONTAL, Layout.Type.VERTICAL, Layout.Type.GRID][state.layout]!;
        layout.spacingX = 8;
        layout.spacingY = column ? 4 : 6;
        tiles.forEach((tile, i) => {
          tile.setPosition(0, 0);
          tile.setContentSize(column ? 120 : state.layout === 2 ? 76 : 62, column ? 14 : 28);
          tileLabels[i]!.node.setContentSize(column ? 116 : 58, column ? 14 : 28);
          tileLabels[i]!.lineHeight = column ? 14 : 18;
          tileLabels[i]!.fontSize = column ? 12 : 14;
        });
        layout.updateLayout();
      }
      layoutText.string = ['Horizontal row', 'Vertical column', '2 x 2 grid'][state.layout]!;
      widget.isAlignHorizontalCenter = false;
      widget.isAlignLeft = false;
      widget.isAlignRight = false;
      aligned.setContentSize(84, 34);
      widget.isAlignHorizontalCenter = state.alignment === 1;
      widget.isAlignLeft = state.alignment === 0 || state.alignment === 3;
      widget.isAlignRight = state.alignment === 2 || state.alignment === 3;
      widget.left = widget.right = 12;
      widget.horizontalCenter = 0;
      widget.updateAlignment();
      widgetLabel.node.setContentSize(aligned.width - 4, 32);
      widgetText.string = ['Left aligned', 'Centered', 'Right aligned', 'Stretched'][state.alignment]!;
      privateNodes.forEach((node, i) => {
        node.active = state.visible;
        privacy[i]!.mode = state.privacy === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask;
        privacy[i]!.enabled = state.privacy !== 'default';
      });
      group.setPosition(state.moved ? 28 : 0, state.moved ? -8 : 0);
      group.setScale(state.moved ? 0.85 : 1);
      if (pageRevision !== state.pageRevision) {
        pageRevision = state.pageRevision;
        pager.scrollToPage(state.page, 0.15);
      }
      applying = false;
    };
    this.coverage = new ReplayLayoutCoverage({
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
