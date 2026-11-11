const { Button, Color, Component, Graphics, JsonAsset, Label, Node, resources, WebView } = cc;

const { ccclass } = cc._decorator;
const TEXT = new Color(239, 244, 255);
const PANEL = new Color(27, 39, 64);

@ccclass('WebViewValidationScene')
export class WebViewValidationScene extends Component {
  private closed = false;
  private webNode?: cc.Node;

  initialize(exit: () => void, track: (caseId: string, stage: string) => void, url: string): void {
    this.panel(this.node, 'Background', 0, 0, 960, 640, new Color(12, 18, 34));
    this.label(this.node, 'WebView validation', 0, 282, 450, 40, 26);
    const status = this.label(this.node, 'Reading local configuration...', 0, 235, 900, 32, 17);
    this.button('Back', -370, () => {
      this.closed = true;
      if (this.webNode) this.webNode.active = false;
      track('WebView', 'exit');
      exit();
    });
    let configuredUrl = '';
    const open = (): void => {
      if (this.closed || !this.node.activeInHierarchy || !configuredUrl) return;
      if (this.webNode) {
        this.webNode.active = false;
        this.webNode.destroy();
      }
      // Recreate the native view so reloading the same URL works on both engines.
      const node = this.child(this.node, 'ValidationWebView', 0, -30, 920, 500);
      this.webNode = node;
      const web = node.addComponent(WebView);
      status.string = 'Loading...';
      const report = (text: string, stage: string): void => {
        if (this.closed || this.webNode !== node || !this.node.activeInHierarchy) return;
        status.string = text;
        track('WebView', stage);
      };
      node.on('loading', () => report('Loading...', 'loading'));
      node.on('loaded', () => report('Page loaded', 'loaded'));
      node.on('error', () => report('Load failed. Check network access and retry.', 'error'));
      web.url = configuredUrl;
    };
    this.button('Reload', 370, () => {
      if (!configuredUrl) return;
      track('WebView', 'reload');
      open();
    });
    if (!/^https?:\/\//i.test(url)) {
      status.string = 'WebView URL is not configured';
      this.label(this.node, 'Set the Demo API URL in Connection settings,\nthen reopen WebView coverage.', 0, 0, 880, 140, 22);
    } else {
      configuredUrl = url;
      open();
    }
    track('WebView', 'entered');
  }

  private child(parent: cc.Node, name: string, x: number, y: number, width: number, height: number): cc.Node {
    const node = new Node(name);
    node.setContentSize(width, height);
    node.setPosition(x, y);
    parent.addChild(node);
    return node;
  }

  private panel(parent: cc.Node, name: string, x: number, y: number, width: number, height: number, color: cc.Color): cc.Node {
    const node = this.child(parent, name, x, y, width, height);
    const graphics = node.addComponent(Graphics);
    graphics.fillColor = color;
    graphics.rect(-width / 2, -height / 2, width, height);
    graphics.fill();
    return node;
  }

  private label(parent: cc.Node, text: string, x: number, y: number, width: number, height: number, fontSize: number): cc.Label {
    const node = this.child(parent, 'Label', x, y, width, height);
    const label = node.addComponent(Label);
    label.overflow = Label.Overflow.CLAMP;
    label.string = text;
    label.fontSize = fontSize;
    label.lineHeight = fontSize + 6;
    node.color = TEXT;
    label.horizontalAlign = Label.HorizontalAlign.CENTER;
    label.verticalAlign = Label.VerticalAlign.CENTER;
    return label;
  }

  private button(text: string, x: number, click: () => void): void {
    const node = this.panel(this.node, text, x, 282, 160, 40, PANEL);
    node.addComponent(Button);
    node.on('click', click);
    this.label(node, text, 0, 0, 150, 36, 20);
  }

  onDestroy(): void {
    this.closed = true;
  }
}
