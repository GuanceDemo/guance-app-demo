import {
  assetManager, Button, Color, EditBox, Graphics, ImageAsset, Label, Layers, Mask,
  Node, ScrollView, Sprite, SpriteFrame, Texture2D, UITransform, isValid,
} from 'cc';

export const theme = {
  background: new Color(9, 17, 33), paper: new Color(19, 34, 57),
  ink: new Color(235, 242, 255), muted: new Color(143, 162, 189), primary: new Color(92, 242, 197),
  pale: new Color(25, 40, 62), line: new Color(50, 76, 106), danger: new Color(255, 111, 131),
};

export function box(parent: Node, name: string, x: number, y: number, w: number, h: number, color?: Color): Node {
  const node = new Node(name); node.layer = Layers.Enum.UI_2D;
  node.addComponent(UITransform).setContentSize(w, h); node.setPosition(x, y); parent.addChild(node);
  if (color) {
    const g = node.addComponent(Graphics); g.fillColor = color;
    g.roundRect(-w / 2, -h / 2, w, h, 14); g.fill();
  }
  return node;
}

export function text(parent: Node, value: string, x: number, y: number, w: number, h: number, size = 24, color = theme.ink): Label {
  const node = box(parent, 'Text', x, y, w, h);
  const label = node.addComponent(Label);
  label.string = value; label.fontSize = size; label.lineHeight = size + 8;
  label.color = color; label.overflow = Label.Overflow.SHRINK;
  label.horizontalAlign = Label.HorizontalAlign.LEFT; label.verticalAlign = Label.VerticalAlign.CENTER;
  label.enableWrapText = true;
  return label;
}

export function button(parent: Node, title: string, x: number, y: number, w: number, h: number, click: () => void, primary = false): Node {
  const node = box(parent, title, x, y, w, h, primary ? theme.primary : theme.pale);
  const label = text(node, title, 0, 0, w - 28, h - 10, 25, primary ? theme.paper : theme.primary);
  label.horizontalAlign = Label.HorizontalAlign.CENTER;
  const component = node.addComponent(Button); component.transition = Button.Transition.SCALE;
  component.zoomScale = 0.97;
  node.on(Button.EventType.CLICK, click);
  return node;
}

/** Scrollable pages let every control remain reachable on small screens and with large content. */
export class Page {
  readonly node: Node;
  private content: Node;
  private cursor = 12;
  private scroll: ScrollView;
  private textures: Array<{ frame: SpriteFrame; texture: Texture2D; asset: ImageAsset }> = [];
  private disposed = false;

  constructor(parent: Node) {
    this.node = box(parent, 'Page', 0, -5, 664, 936);
    const viewport = box(this.node, 'Viewport', 0, 0, 664, 936);
    viewport.addComponent(Mask).type = Mask.Type.GRAPHICS_RECT;
    this.content = box(viewport, 'Content', 0, 468, 664, 936);
    this.content.getComponent(UITransform)!.setAnchorPoint(0.5, 1);
    this.scroll = this.node.addComponent(ScrollView);
    this.scroll.content = this.content; this.scroll.horizontal = false; this.scroll.vertical = true;
    this.scroll.inertia = true; this.scroll.elastic = true;
  }
  row(height: number, name = 'Row', color?: Color): Node {
    const node = box(this.content, name, 0, -this.cursor - height / 2, 640, height, color);
    this.cursor += height + 16;
    this.content.getComponent(UITransform)!.setContentSize(664, Math.max(936, this.cursor));
    return node;
  }
  heading(title: string, subtitle: string): void {
    const row = this.row(100);
    text(row, title, 0, 24, 636, 52, 36);
    text(row, subtitle, 0, -27, 636, 46, 22, theme.muted);
  }
  note(value: string, height = 86): Label {
    return text(this.row(height, 'Note', theme.paper), value, 0, 0, 596, height - 16, 23, theme.muted);
  }
  action(title: string, handler: () => void, primary = false): Node {
    return button(this.row(68), title, 0, 0, 640, 68, handler, primary);
  }
  pair(left: string, right: string, onLeft: () => void, onRight: () => void): void {
    const row = this.row(64);
    button(row, left, -166, 0, 308, 64, onLeft);
    button(row, right, 166, 0, 308, 64, onRight);
  }
  field(title: string, value = '', secret = false, multiline = false): EditBox {
    const height = multiline ? 190 : 118;
    const row = this.row(height);
    text(row, title, 0, height / 2 - 20, 636, 38, 23, theme.muted);
    const fieldHeight = height - 46;
    const node = box(row, title, 0, -23, 640, fieldHeight);
    box(node, 'InputBackground', 0, 0, 640, fieldHeight, theme.paper);
    // Configure labels before __preload runs; otherwise EditBox creates orphan default labels.
    node.active = false;
    const edit = node.addComponent(EditBox);
    edit.textLabel = text(node, '', 0, 0, 600, fieldHeight - 10, 24);
    edit.placeholderLabel = text(node, 'Enter ' + title, 0, 0, 600, fieldHeight - 10, 23, theme.muted);
    edit.textLabel.node.getComponent(UITransform)!.setAnchorPoint(0, 1);
    edit.placeholderLabel.node.getComponent(UITransform)!.setAnchorPoint(0, 1);
    edit.textLabel.verticalAlign = Label.VerticalAlign.CENTER;
    edit.placeholderLabel.verticalAlign = Label.VerticalAlign.CENTER;
    edit.inputMode = multiline ? EditBox.InputMode.ANY : EditBox.InputMode.SINGLE_LINE;
    edit.inputFlag = secret ? EditBox.InputFlag.PASSWORD : EditBox.InputFlag.DEFAULT;
    edit.maxLength = multiline ? 32768 : 2048; edit.string = value;
    node.active = true;
    return edit;
  }
  image(parent: Node, url: string, x: number, y: number, w: number, h: number): void {
    const node = box(parent, 'ProductImage', x, y, w, h, theme.background);
    const fallback = text(node, 'Loading image…', 0, 0, w - 8, h - 8, 20, theme.muted);
    assetManager.loadRemote<ImageAsset>(url, { ext: '.png' }, (error, asset) => {
      if (this.disposed || !isValid(node, true)) return;
      if (error || !asset) { fallback.string = 'Image unavailable'; return; }
      fallback.node.active = false;
      asset.addRef();
      const texture = new Texture2D(); texture.image = asset;
      const frame = new SpriteFrame(); frame.texture = texture;
      this.textures.push({ frame, texture, asset });
      // A node must have only one UIRenderer; keep Sprite separate from its Graphics background.
      const imageNode = box(node, 'RemoteImage', 0, 0, w, h);
      const sprite = imageNode.addComponent(Sprite); sprite.sizeMode = Sprite.SizeMode.CUSTOM; sprite.spriteFrame = frame;
      const ratio = Math.min(w / asset.width, h / asset.height);
      imageNode.getComponent(UITransform)!.setContentSize(asset.width * ratio, asset.height * ratio);
    });
  }
  destroy(): void {
    this.disposed = true; this.scroll.stopAutoScroll();
    this.node.active = false; this.node.destroy();
    for (const item of this.textures) { item.frame.destroy(); item.texture.destroy(); item.asset.decRef(); }
    this.textures = [];
  }
}
