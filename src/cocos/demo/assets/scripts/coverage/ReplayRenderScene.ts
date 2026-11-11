import { _decorator, Button, Color, Component, ImageAsset, Label, Layers, Material, Mesh, MeshRenderer, Node, RenderRoot2D, Sprite, SpriteFrame, SpriteRenderer, Texture2D, UIMeshRenderer, UISkew, UIStaticBatch, UITransform, Vec3, director, resources, utils } from 'cc';
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = _decorator;
const PANEL = new Color(27, 39, 64);
const ORANGE = new Color(248, 164, 44);
const CYAN = new Color(40, 210, 220);

@ccclass('ReplayRenderScene')
export class ReplayRenderScene extends Component {
  private frames: SpriteFrame[] = [];
  private textures: Texture2D[] = [];
  private images: ImageAsset[] = [];
  private materials: Material[] = [];
  private meshes: Mesh[] = [];
  private independentRoot?: Node;
  private syncRoot?: () => void;
  private disposed = false;

  async initialize(exit: () => void, track: (id: string, stage: string) => void): Promise<void> {
    const load = (name: string) => new Promise<Material>((resolve, reject) => resources.load(name, Material, (e, m) => e ? reject(e) : resolve(m)));
    const [unlit, spriteMaterial] = await Promise.all([load('ReplayUIModel'), load('ReplaySpriteRenderer')]);
    if (!this.isValid || this.disposed) return;
    const white = this.frame(false); const pattern = this.frame(true);
    // Scene models render before Canvas batches; use the camera clear color as background.
    this.panel(this.node, 'Background', 0, 0, 960, 640, new Color(12, 18, 34), white).getComponent(Sprite)!.enabled = false;
    this.label(this.node, 'Replay UI render components / batch 09', 0, 282, 920, 40, 26);
    this.label(this.node, 'Real engine components. Independent root, UI model and skew probes.', 0, 242, 920, 30, 16);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 430);
    const names = ['UIMeshRenderer', 'UIStaticBatch', 'RenderRoot2D', 'SpriteRenderer', 'UISkew'];
    const ys = [170, 95, 20, -55, -140];
    const bodies: Node[] = []; const privacy: ReplayPrivacy[] = []; const notes: Label[] = [];
    names.forEach((name, i) => {
      this.label(group, `I0${i + 1} / ${name}`, -330, ys[i]!, 245, 50, 18);
      this.panel(group, name + 'GuardTop', 0, ys[i]! + 32, 358, 3, new Color(44, 202, 178), white);
      this.panel(group, name + 'GuardBottom', 0, ys[i]! - 32, 358, 3, new Color(44, 202, 178), white);
      this.panel(group, name + 'GuardLeft', -179, ys[i]!, 3, 64, new Color(44, 202, 178), white);
      this.panel(group, name + 'GuardRight', 179, ys[i]!, 3, 64, new Color(44, 202, 178), white);
      const body = this.panel(group, name + 'Private', 0, ys[i]!, 348, 54, PANEL, white);
      bodies.push(body);
      const p = body.addComponent(ReplayPrivacy); p.enabled = false; privacy.push(p);
      notes.push(this.label(group, '', 330, ys[i]!, 245, 50, 14));
    });
    bodies[0]!.getComponent(Sprite)!.enabled = false;
    bodies[3]!.getComponent(Sprite)!.enabled = false;
    const modelNode = this.child(bodies[0]!, 'RealUIModel', 0, 0, 160, 30);
    modelNode.active = false;
    modelNode.setPosition(0, 0, 1); // Camera z=1000, far=1000: keep depth-tested models inside the clip volume.
    const mesh = utils.createMesh({ positions: [-80, -15, 0, 80, -15, 0, 80, 15, 0, -80, 15, 0], uvs: [0, 0, 1, 0, 1, 1, 0, 1], indices: [0, 1, 2, 0, 2, 3], minPos: new Vec3(-80, -15, 0), maxPos: new Vec3(80, 15, 0) });
    this.meshes.push(mesh);
    const model = modelNode.addComponent(MeshRenderer); model.visibility = Layers.Enum.UI_2D; model.mesh = mesh;
    const modelMaterial = new Material(); modelMaterial.copy(unlit); this.materials.push(modelMaterial); model.setSharedMaterial(modelMaterial, 0);
    const proxy = modelNode.addComponent(UIMeshRenderer);
    modelNode.active = true;

    const staticNode = this.child(bodies[1]!, 'RealStaticBatch', 0, 0, 250, 38);
    const staticBatch = staticNode.addComponent(UIStaticBatch);
    const staticSprite = this.panel(staticNode, 'DynamicChildSprite', -65, 0, 110, 30, ORANGE, white).getComponent(Sprite)!;
    const staticLabel = this.label(staticNode, 'Child A', 60, 0, 100, 32, 17);

    // This root is deliberately outside the Canvas hierarchy, so disabling it
    // cannot be hidden by the parent Canvas continuing to collect its children.
    const anchor = bodies[2]!;
    const root = new Node('IndependentRenderRoot2D'); root.active = false; root.layer = Layers.Enum.UI_2D;
    root.addComponent(UITransform).setContentSize(348, 54);
    director.getScene()!.addChild(root); this.independentRoot = root;
    const renderRoot = root.addComponent(RenderRoot2D);
    const rootPanel = this.panel(root, 'RootOnlySprite', 0, 0, 200, 34, ORANGE, white).getComponent(Sprite)!;
    const rootLabel = this.label(root, 'Root A', 0, 0, 190, 30, 18);
    privacy[2]!.enabled = false;
    const rootPrivacy = root.addComponent(ReplayPrivacy); rootPrivacy.enabled = false; privacy[2] = rootPrivacy;
    this.syncRoot = () => { root.setWorldPosition(anchor.worldPosition); root.setWorldRotation(anchor.worldRotation); root.setWorldScale(anchor.worldScale); };

    const spriteNode = this.child(bodies[3]!, 'RealSpriteRenderer', 0, 0, 0.32, 0.32);
    spriteNode.active = false;
    spriteNode.setPosition(0, 0, 1);
    spriteNode.setScale(500, 100, 1); // SpriteFrame mesh uses 100 pixels per world unit.
    const renderer = spriteNode.addComponent(SpriteRenderer); renderer.visibility = Layers.Enum.UI_2D;
    const spriteMat = new Material(); spriteMat.copy(spriteMaterial); this.materials.push(spriteMat); renderer.setSharedMaterial(spriteMat, 0);
    renderer.spriteFrame = pattern;
    // SpriteRenderer is drawn directly by the scene camera for an independent model probe.
    spriteNode.active = true;

    const skewNode = this.panel(bodies[4]!, 'RealSkewedSprite', 0, 0, 160, 30, ORANGE, white);
    const skew = skewNode.addComponent(UISkew);
    let variant = false, rootEnabled = true, rotational = false, moved = false, visible = true, uiProxyEnabled = true;
    let appliedProxy = true;
    let mode: 'default' | 'mask' | 'hide' = 'default';
    const status = this.label(this.node, '', 0, -216, 920, 22, 14);
    const apply = (stage: string) => {
      group.setPosition(moved ? 28 : 0, moved ? -8 : 0); group.setScale(moved ? .85 : 1, moved ? .85 : 1, 1);
      bodies.forEach((n, i) => { n.active = visible; privacy[i]!.mode = mode === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask; privacy[i]!.enabled = mode !== 'default'; });
      root.active = visible; renderRoot.enabled = rootEnabled; this.syncRoot?.();
      if (appliedProxy !== uiProxyEnabled) {
        appliedProxy = uiProxyEnabled; proxy.enabled = uiProxyEnabled;
        model.enabled = false; model.enabled = true;
      }
      modelMaterial.setProperty('mainColor', variant ? CYAN : ORANGE);
      model.getMaterialInstance(0)?.setProperty('mainColor', variant ? CYAN : ORANGE); modelNode.setRotationFromEuler(0, 0, variant ? 8 : 0);
      staticSprite.color = variant ? CYAN : ORANGE; staticLabel.string = variant ? 'Child B' : 'Child A';
      rootPanel.color = variant ? CYAN : ORANGE; rootLabel.string = variant ? 'Root B' : 'Root A';
      renderer.spriteFrame = variant ? white : pattern;
      skew.x = variant ? 30 : 0; skew.y = variant ? 5 : 0; skew.rotational = rotational;
      skewNode.getComponent(Sprite)!.color = variant ? CYAN : ORANGE;
      notes[0]!.string = 'model:' + !!model.model + ' subs:' + (model.model?.subModels.length || 0) + '\nUI proxy:' + proxy.enabled;
      notes[1]!.string = 'batches: ' + staticBatch.drawBatchList.length + ' / enabled:' + staticBatch.enabled;
      notes[2]!.string = 'independent root: ' + renderRoot.enabled;
      notes[3]!.string = (variant ? 'White' : 'Pattern') + ' subs:' + (renderer.model?.subModels.length || 0) + '\nScene model (no proxy)';
      notes[4]!.string = `x:${skew.x} y:${skew.y} rotational:${skew.rotational}`;
      status.string = `${stage} | variant:${+variant} root:${rootEnabled} privacy:${mode}`;
      track('page', stage);
    };
    const commands: Array<[string, () => void]> = [
      ['Change five cases', () => { variant = !variant; apply('changed'); }],
      ['RenderRoot on / off', () => { rootEnabled = !rootEnabled; apply(rootEnabled ? 'root-on' : 'root-off'); }],
      ['Static dirty / proxy / skew', () => { staticBatch.markAsDirty(); rotational = !rotational; uiProxyEnabled = !uiProxyEnabled; apply('static-dirty-proxy-skew'); }],
      ['Move + scale', () => { moved = !moved; apply('transformed'); }],
      ['Hide / show', () => { visible = !visible; apply(visible ? 'shown' : 'hidden'); }],
      ['Privacy default / mask / hide', () => { mode = mode === 'default' ? 'mask' : mode === 'mask' ? 'hide' : 'default'; apply('privacy-' + mode); }],
      ['Reset', () => { variant = false; rootEnabled = true; rotational = false; moved = false; visible = true; uiProxyEnabled = true; mode = 'default'; apply('reset'); }],
      ['Back', () => { if (!this.disposed) { this.disposed = true; exit(); } }],
    ];
    commands.forEach(([caption, click], i) => {
      const button = this.panel(this.node, 'Command' + i, -345 + i % 4 * 230, i < 4 ? -245 : -295, 218, 38, PANEL, white);
      button.addComponent(Button); button.on('click', () => { if (!this.disposed) click(); });
      this.label(button, caption, 0, 0, 212, 34, 13);
    });
    apply('entered');
  }

  lateUpdate(): void { this.syncRoot?.(); }
  private frame(pattern: boolean): SpriteFrame {
    const image = new ImageAsset({ _data: coverageTexturePixels(pattern), width: 32, height: 32, format: Texture2D.PixelFormat.RGBA8888, _compressed: false });
    const texture = new Texture2D(); texture.image = image;
    const frame = new SpriteFrame(); frame.texture = texture;frame.packable=false;
    this.images.push(image); this.textures.push(texture); this.frames.push(frame); return frame;
  }
  private child(parent: Node, name: string, x: number, y: number, w: number, h: number): Node {
    const n = new Node(name); n.layer = Layers.Enum.UI_2D; n.addComponent(UITransform).setContentSize(w, h); n.setPosition(x, y); parent.addChild(n); return n;
  }
  private panel(parent: Node, name: string, x: number, y: number, w: number, h: number, color: Color, frame: SpriteFrame): Node {
    const n = this.child(parent, name, x, y, w, h); const s = n.addComponent(Sprite); s.sizeMode = Sprite.SizeMode.CUSTOM; s.spriteFrame = frame; s.color = color; return n;
  }
  private label(parent: Node, text: string, x: number, y: number, w: number, h: number, size: number): Label {
    const n = this.child(parent, 'Label', x, y, w, h); const l = n.addComponent(Label); l.overflow = Label.Overflow.CLAMP; n.getComponent(UITransform)!.setContentSize(w, h); l.string = text; l.fontSize = size; l.lineHeight = 24; l.color = new Color(239, 244, 255); l.horizontalAlign = Label.HorizontalAlign.CENTER; l.verticalAlign = Label.VerticalAlign.CENTER; return l;
  }
  onDestroy(): void {
    this.disposed = true; this.syncRoot = undefined;
    if (this.independentRoot) { this.independentRoot.active = false; this.independentRoot.destroy(); }
    this.frames.forEach(x => x.destroy()); this.textures.forEach(x => x.destroy()); this.images.forEach(x => x.destroy()); this.materials.forEach(x => x.destroy()); this.meshes.forEach(x => x.destroy());
  }
}
