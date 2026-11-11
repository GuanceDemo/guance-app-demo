const { Asset, Button, Color, Component, Label, Node, Size, Sprite, SpriteFrame, SubContextView, Texture2D, TiledMap, TiledMapAsset } = cc;
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { AssetState, ReplayAssetCoverage } from './acceptance-components/ReplayAssetCoverage';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = cc._decorator;
const BG = new Color(12, 18, 34);
const PANEL = new Color(27, 39, 64);
const TEXT = new Color(239, 244, 255);
const GREEN = new Color(44, 202, 178);

@ccclass('ReplayAssetScene')
export class ReplayAssetScene extends Component {
  private coverage?: ReplayAssetCoverage;
  private frames: cc.SpriteFrame[] = [];
  private textures: cc.Texture2D[] = [];
  private assets: cc.Asset[] = [];
  private inspect?: () => void;

  initialize(exit: () => void, track: (id: string, stage: string) => void): void {
    const white = this.frame(false);
    const pattern = this.frame(true);
    this.panel(this.node, 'Background', 0, 0, 960, 640, BG, white);
    this.label(this.node, 'Replay tile maps + skeletal assets / batch 07', 0, 282, 920, 40, 26);
    this.label(this.node, 'Generated local fixtures. Actual TMX, Spine and DragonBones renderers.', 0, 242, 920, 30, 16);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 430);
    const names = ['TiledMap', 'TiledTile', 'Spine Skeleton', 'DragonBones', 'SubContextView'];
    const ys = [170, 95, 20, -55, -140];
    const nodes: cc.Node[] = [];
    const privacy: ReplayPrivacy[] = [];
    names.forEach((name, i) => {
      const y = ys[i]!;
      this.label(group, `G0${i + 1} / ${name}`, -330, y, 245, 50, 18);
      this.panel(group, name + 'GuardTop', 0, y + 32, 358, 3, GREEN, white);
      this.panel(group, name + 'GuardBottom', 0, y - 32, 358, 3, GREEN, white);
      this.panel(group, name + 'GuardLeft', -179, y, 3, 64, GREEN, white);
      this.panel(group, name + 'GuardRight', 179, y, 3, 64, GREEN, white);
      const node = this.panel(group, name + 'Private', 0, y, 348, 54, PANEL, white);
      nodes.push(node);
      const protection = node.addComponent(ReplayPrivacy); protection.enabled = false; privacy.push(protection);
    });
    const maps: cc.TiledMap[] = [];
    for (let i = 0; i < 2; i++) {
      const mapNode = this.child(nodes[i]!, 'TMXMap' + i, 0, 0, 128, 32);
      const map = mapNode.addComponent(TiledMap);
      const asset = new TiledMapAsset();
      asset.textures = [this.textures[1]!]; asset.textureNames = ['coverage.png']; asset.textureSizes = [new Size(32, 32)];
      (asset as cc.TiledMapAsset & { tmxXmlStr: string }).tmxXmlStr = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><map version=\"1.0\" orientation=\"orthogonal\" renderorder=\"right-down\" width=\"8\" height=\"2\" tilewidth=\"16\" tileheight=\"16\"><tileset firstgid=\"1\" name=\"coverage\" tilewidth=\"16\" tileheight=\"16\" tilecount=\"4\" columns=\"2\"><image source=\"coverage.png\" width=\"32\" height=\"32\"/></tileset><layer name=\"Demo\" width=\"8\" height=\"2\"><data encoding=\"csv\">1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1</data></layer></map>";
      map.tmxAsset = asset;
      mapNode.setScale(2, 1.2, 1);

      this.assets.push(asset); maps.push(map);
    }
    const mapText = this.label(group, '', 330, ys[0]!, 245, 50, 16);
    const tileLayer = maps[1]!.getLayer('Demo');
    const tile = tileLayer.getTiledTileAt(3, 0, true)!;
    const tileText = this.label(group, '', 330, ys[1]!, 245, 50, 16);

    const spineNode = this.child(nodes[2]!, 'GeneratedSpine', 0, 0, 40, 40);
    spineNode.active = false; spineNode.setScale(4, 1.2, 1);
    const skeleton = spineNode.addComponent(sp.Skeleton);
    const skeletonData = new sp.SkeletonData();
    skeletonData.skeletonJson = JSON.parse(JSON.stringify({
      skeleton: { hash: 'coverage', spine: '3.8.99', x: -16, y: -16, width: 32, height: 32 },
      bones: [{ name: 'root' }], slots: [{ name: 'box', bone: 'root', attachment: 'box' }],
      skins: [{ name: 'default', attachments: { box: { box: { type: 'region', path: 'box', width: 32, height: 32 } } } }],
      animations: { poseA: { bones: { root: { rotate: [{ time: 0, angle: -8 }, { time: 0.5, angle: 8 }, { time: 1, angle: -8 }] } } }, poseB: { bones: { root: { translate: [{ time: 0, x: -8 }, { time: 0.5, x: 8 }, { time: 1, x: -8 }] } } } },
    }));
    skeletonData.atlasText = 'coverage.png\nsize: 32,32\nformat: RGBA8888\nfilter: Linear,Linear\nrepeat: none\nbox\n  rotate: false\n  xy: 0,0\n  size: 32,32\n  orig: 32,32\n  offset: 0,0\n  index: -1\n';
    skeletonData.textures = [this.textures[1]!];
    (skeletonData as sp.SkeletonData & { textureNames: string[] }).textureNames = ['coverage.png'];
    skeleton.skeletonData = skeletonData;
    spineNode.active = true;
    this.assets.push(skeletonData);
    const spineText = this.label(group, '', 330, ys[2]!, 245, 50, 16);

    const dragonNode = this.child(nodes[3]!, 'GeneratedDragonBones', 0, 0, 40, 40);
    dragonNode.active = false; dragonNode.setScale(4, 1.2, 1);
    const dragon = dragonNode.addComponent(dragonBones.ArmatureDisplay);
    const dragonData = new dragonBones.DragonBonesAsset();
    dragonData.dragonBonesJson = JSON.stringify({ name: 'CoverageRig', version: '5.5', compatibleVersion: '5.5', frameRate: 24,
      armature: [{ name: 'DemoArmature', type: 'Armature', frameRate: 24, bone: [{ name: 'root' }], slot: [{ name: 'box', parent: 'root', displayIndex: 0 }],
        skin: [{ name: 'default', slot: [{ name: 'box', display: [{ name: 'box', path: 'box', type: 'image' }] }] }],
        animation: [{ name: 'poseA', duration: 24, playTimes: 0, bone: [{ name: 'root', rotateFrame: [{ duration: 12, rotate: -8 }, { duration: 12, rotate: 8 }] }] }, { name: 'poseB', duration: 24, playTimes: 0, bone: [{ name: 'root', translateFrame: [{ duration: 12, x: -8 }, { duration: 12, x: 8 }] }] }],
      }],
    });
    const dragonAtlas = new dragonBones.DragonBonesAtlasAsset();
    dragonAtlas.atlasJson = JSON.stringify({ name: 'CoverageAtlas', imagePath: 'coverage.png', width: 32, height: 32, SubTexture: [{ name: 'box', x: 0, y: 0, width: 32, height: 32 }] });
    dragonAtlas.texture = this.textures[1]!;
    dragon.dragonAsset = dragonData; dragon.dragonAtlasAsset = dragonAtlas; dragon.armatureName = 'DemoArmature';
    dragonNode.active = true;
    this.assets.push(dragonData, dragonAtlas);
    const dragonText = this.label(group, '', 330, ys[3]!, 245, 50, 16);

    const subNode = this.child(nodes[4]!, 'NativeSubContext', 0, 0, 320, 44);
    const sub = subNode.addComponent(SubContextView);
    const subText = this.label(group, '', 330, ys[4]!, 245, 50, 14);
    this.inspect = () => { subText.string = 'Actual enabled: ' + sub.enabled; };
    const status = this.label(this.node, '', 0, -216, 920, 22, 14);
    let variant = -1;
    const apply = (state: Readonly<AssetState>): void => {
      nodes.forEach((node, i) => { node.active = state.visible; privacy[i]!.mode = state.privacy === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask; privacy[i]!.enabled = state.privacy !== 'default'; });
      group.setPosition(state.moved ? 28 : 0, state.moved ? -8 : 0);
      group.setScale(state.moved ? 0.85 : 1, state.moved ? 0.85 : 1, 1);
      const mapLayer = maps[0]!.getLayer('Demo');
      for (let y = 0; y < 2; y++) for (let x = 0; x < 8; x++) mapLayer.setTileGIDAt(state.variant ? 4 : 1, x, y);
      tile.gid = state.variant ? 3 : 1;
      tile.node.setScale(state.variant ? 1.25 : 1, state.variant ? 1.25 : 1, 1);
      mapText.string = 'Map GID: ' + (state.variant ? 4 : 1);
      tileText.string = 'Tile (3,0): ' + tile.gid;
      if (variant !== state.variant) {
        variant = state.variant;
        skeleton.setAnimation(0, variant ? 'poseB' : 'poseA', true);
        dragon.playAnimation(variant ? 'poseB' : 'poseA', 0);
      }
      skeleton.paused = !state.running; dragon.timeScale = state.running ? 1 : 0;
      spineText.string = (state.variant ? 'poseB' : 'poseA') + (state.running ? ' / playing' : ' / paused');
      dragonText.string = spineText.string;
      this.inspect?.();
    };
    this.coverage = new ReplayAssetCoverage({ apply, status: text => { status.string = text; }, command: (name, text, x, y, click) => {
      const node = this.panel(this.node, name, x, y, 218, 38, PANEL, white); node.addComponent(Button); node.on('click', click); this.label(node, text, 0, 0, 212, 34, 13);
    } }, track, exit);
  }

  update(): void { this.inspect?.(); }

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
    this.inspect = undefined;
    this.assets.forEach(asset => asset.destroy());
    this.frames.forEach(frame => frame.destroy());
    this.textures.forEach(texture => texture.destroy());
  }
}
