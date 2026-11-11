import {
  _decorator, Button, Camera, Canvas, Color, Component, DirectionalLight, Graphics,
  Input, Label, Layers, Material, Mesh, MeshRenderer, Node, PointLight, SphereLight, SpotLight, UITransform, Vec3, director,
  input, primitives, resources, utils, view,
} from 'cc';

import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';

const { ccclass } = _decorator;

/** Real mesh geometry and perspective, with an optional second-camera HUD. */
@ccclass('Replay3DScene')
export class Replay3DScene extends Component {
  camera!: Camera;
  private hud!: Node;
  private hudBanner?: Graphics;
  private cube!: Node;
  private orb!: Node;
  private meshes: Mesh[] = [];
  private materials: Material[] = [];
  private angle = 0;
  private paused = false;
  private onBack?: () => void;
  private baseMaterial!: Material;

  private lightCoverage = false;
  private lightNodes: Node[] = [];
  private lightNames = ['DirectionalLight', 'PointLight', 'SphereLight', 'SpotLight'];
  private lightIndex = 0;
  private lightTint = false;
  private lightOn = true;
  private meshMoved = false;
  private meshVisible = true;
  private meshPrivacy: 'default' | 'mask' | 'hide' = 'default';
  private privacy?: ReplayPrivacy;
  private lightLegend?: Label;
  private previousAmbient?: number;
  private trackLight?: (state: string) => void;

  async initialize(onBack: () => void, lightCoverage = false, trackLight?: (state: string) => void): Promise<void> {
    this.lightCoverage = lightCoverage;
    this.trackLight = trackLight;
    this.onBack = onBack;
    // An explicit resource dependency keeps the PBR effect in native builds.
    this.baseMaterial = await new Promise<Material>((resolve, reject) => {
      resources.load('Replay3D', Material, (error, material) => error ? reject(error) : resolve(material));
    });
    if (!this.isValid || !this.node.activeInHierarchy) return;
    const cameraNode = this.child('PerspectiveCamera');
    cameraNode.setPosition(7, 5, 11);
    cameraNode.lookAt(new Vec3(0, 0.2, 0));
    this.camera = cameraNode.addComponent(Camera);
    this.camera.projection = Camera.ProjectionType.PERSPECTIVE;
    this.camera.fov = 45;
    this.camera.near = 0.1;
    this.camera.far = 100;
    this.camera.visibility = Layers.Enum.DEFAULT;
    this.camera.clearFlags = Camera.ClearFlag.SOLID_COLOR;
    this.camera.clearColor = new Color(12, 18, 34, 255);

    if (lightCoverage) {
      cameraNode.setPosition(4, 3, 6);
      cameraNode.lookAt(new Vec3(0, 0, 0));
      this.createLightCoverage();
      this.createHud();
      this.applyLightState('entered');
      return;
    }

    const lightNode = this.child('KeyLight');
    lightNode.setRotationFromEuler(-45, -30, 0);
    lightNode.addComponent(DirectionalLight).illuminance = 65000;

    this.box('Floor', new Vec3(0, -1.3, 0), new Vec3(10, 0.2, 8), new Color(54, 67, 86));
    // Grid bars recede into depth, making perspective and camera changes visible.
    for (let i = -4; i <= 4; i++) {
      this.box(`GridX${i}`, new Vec3(i, -1.18, 0), new Vec3(0.025, 0.015, 8), new Color(100, 123, 146));
    }
    for (let i = -3; i <= 3; i++) {
      this.box(`GridZ${i}`, new Vec3(0, -1.18, i), new Vec3(10, 0.015, 0.025), new Color(100, 123, 146));
    }
    this.cube = this.box('RotatingOrangeCube', new Vec3(-1.9, 0, 0), new Vec3(1.7, 1.7, 1.7), new Color(245, 140, 35));
    this.orb = this.model('OrbitingCyanSphere', primitives.sphere(0.85), new Color(25, 210, 215));
    // Opaque geometry in front of the orbit verifies depth occlusion.
    this.box('MagentaOccluder', new Vec3(1.6, -0.1, 1.5), new Vec3(0.55, 2.2, 0.55), new Color(225, 55, 155));
    this.box('BlueRearTower', new Vec3(0.4, 0.3, -2.2), new Vec3(1.1, 2.8, 1.1), new Color(65, 115, 245));
    this.createHud();
    this.setPose(0);
    input.on(Input.EventType.TOUCH_END, this.handleTouch, this);
  }

  update(dt: number): void {
    if (this.cube && !this.paused) this.setPose(this.angle + dt * 35);
  }

  /** Deterministic poses also allow live-screen and SDK-frame comparisons. */
  setPose(degrees: number): void {
    this.angle = degrees;
    this.cube.setRotationFromEuler(15 + degrees * 0.4, degrees, 12);
    const radians = degrees * Math.PI / 180;
    this.orb.setPosition(1.1 + Math.sin(radians) * 1.6, 0.15, Math.cos(radians) * 1.7);
  }

  setPaused(paused: boolean): void { this.paused = paused; }
  setHudVisible(visible: boolean): void {
    this.hud.active = visible;
    if (visible && this.hudBanner) {
      // Native Graphics geometry must be uploaded again after reactivation.
      this.hudBanner.clear();
      this.hudBanner.rect(-380, -36, 760, 72);
      this.hudBanner.fill();
    }
  }
  returnTo2D(): void { this.onBack?.(); }

  onDestroy(): void {
    input.off(Input.EventType.TOUCH_END, this.handleTouch, this);
    if (this.previousAmbient !== undefined) {
      const scene = director.getScene();
      if (scene) scene.globals.ambient.skyIllum = this.previousAmbient;
    }
    this.trackLight = undefined;
    this.meshes.forEach((mesh) => mesh.destroy());
    this.materials.forEach((material) => material.destroy());
  }

  private handleTouch(event: { getLocation(): { x: number } }): void {
    // Physical screen thirds stay stable with SHOW_ALL's side margins.
    const x = event.getLocation().x / view.getFrameSize().width;
    if (x < 1 / 3) this.returnTo2D();
    else if (x < 2 / 3) this.setHudVisible(!this.hud.active);
    else this.setPaused(!this.paused);
  }

  private child(name: string): Node {
    const node = new Node(name);
    node.layer = Layers.Enum.DEFAULT;
    this.node.addChild(node);
    return node;
  }

  private model(name: string, geometry: ReturnType<typeof primitives.box>, color: Color): Node {
    const node = this.child(name);
    const renderer = node.addComponent(MeshRenderer);
    const mesh = utils.createMesh(geometry);
    this.meshes.push(mesh);
    renderer.mesh = mesh;
    const material = new Material();
    material.copy(this.baseMaterial);
    material.setProperty('mainColor', color);
    material.setProperty('roughness', 0.65);
    if (this.lightCoverage) material.setProperty('metallic', 0);
    this.materials.push(material);
    renderer.setSharedMaterial(material, 0);
    return node;
  }

  private box(name: string, position: Vec3, scale: Vec3, color: Color): Node {
    const node = this.model(name, primitives.box(), color);
    node.setPosition(position);
    node.setScale(scale);
    return node;
  }

  private createHud(): void {
    this.hud = this.child('IndependentCameraHUD');
    this.hud.layer = Layers.Enum.UI_2D;
    const cameraNode = new Node('HUDCamera');
    cameraNode.layer = Layers.Enum.UI_2D;
    cameraNode.setPosition(0, 0, 1000);
    this.hud.addChild(cameraNode);
    const camera = cameraNode.addComponent(Camera);
    camera.projection = Camera.ProjectionType.ORTHO;
    camera.orthoHeight = view.getVisibleSize().height / 2;
    camera.visibility = Layers.Enum.UI_2D;
    camera.priority = this.camera.priority + 1;
    camera.clearFlags = Camera.ClearFlag.DEPTH_ONLY;
    const canvasNode = new Node('HUDCanvas');
    canvasNode.layer = Layers.Enum.UI_2D;
    this.hud.addChild(canvasNode);
    const size = view.getVisibleSize();
    canvasNode.addComponent(UITransform).setContentSize(size.width, size.height);
    canvasNode.addComponent(Canvas).cameraComponent = camera;
    const banner = new Node('HUD-Visible-On-Screen');
    banner.layer = Layers.Enum.UI_2D;
    canvasNode.addChild(banner);
    banner.setPosition(0, size.height / 2 - 48);
    banner.addComponent(UITransform).setContentSize(760, 72);
    const graphics = banner.addComponent(Graphics);
    this.hudBanner = graphics;
    graphics.fillColor = new Color(35, 190, 90, 255);
    graphics.rect(-380, -36, 760, 72);
    graphics.fill();
    const text = new Node('HUD-Legend');
    text.layer = Layers.Enum.UI_2D;
    banner.addChild(text);
    text.addComponent(UITransform).setContentSize(744, 68);
    const label = text.addComponent(Label);
    label.string = '3D REPLAY · INDEPENDENT HUD\nTap left: Back   |   middle: HUD on/off   |   right: Pause';
    if (this.lightCoverage) this.lightLegend = label;
    label.fontSize = 19;
    label.lineHeight = 28;
    label.color = Color.WHITE;
    label.horizontalAlign = Label.HorizontalAlign.CENTER;
    label.verticalAlign = Label.VerticalAlign.CENTER;
    label.overflow = Label.Overflow.SHRINK;
    if (this.lightCoverage) {
      const commands: Array<[string, () => void]> = [
        ['Next light', () => { this.lightIndex = (this.lightIndex + 1) % this.lightNodes.length; this.applyLightState('light'); }],
        ['Orange / cyan', () => { this.lightTint = !this.lightTint; this.applyLightState('tint'); }],
        ['Light on / off', () => { this.lightOn = !this.lightOn; this.applyLightState('light-enabled'); }],
        ['Mesh move / rotate', () => { this.meshMoved = !this.meshMoved; this.applyLightState('transform'); }],
        ['Mesh hide / show', () => { this.meshVisible = !this.meshVisible; this.applyLightState('visible'); }],
        ['Privacy default / mask / hide', () => { this.meshPrivacy = this.meshPrivacy === 'default' ? 'mask' : this.meshPrivacy === 'mask' ? 'hide' : 'default'; this.applyLightState('privacy'); }],
        ['Reset', () => { this.lightIndex = 0; this.lightTint = false; this.lightOn = true; this.meshMoved = false; this.meshVisible = true; this.meshPrivacy = 'default'; this.applyLightState('reset'); }],
        ['Back', () => this.returnTo2D()],
      ];
      commands.forEach(([caption, click], index) => {
        const button = new Node('LightCommand' + index);
        button.layer = Layers.Enum.UI_2D;
        canvasNode.addChild(button);
        button.setPosition((index % 4 - 1.5) * size.width / 4, -size.height / 2 + (index < 4 ? 86 : 28));
        const width = size.width / 4 - 12;
        button.addComponent(UITransform).setContentSize(width, 44);
        const graphics = button.addComponent(Graphics);
        graphics.fillColor = new Color(27, 39, 64);
        graphics.rect(-width / 2, -22, width, 44);
        graphics.fill();
        button.addComponent(Button).transition = Button.Transition.NONE;
        button.on('click', click);
        const text = new Node('Caption');
        text.layer = Layers.Enum.UI_2D;
        button.addChild(text);
        text.addComponent(UITransform).setContentSize(width - 8, 40);
        const label = text.addComponent(Label);
        label.string = caption;
        label.color = Color.WHITE;
        label.fontSize = 15;
        label.lineHeight = 18;
        label.horizontalAlign = Label.HorizontalAlign.CENTER;
        label.verticalAlign = Label.VerticalAlign.CENTER;
        label.overflow = Label.Overflow.SHRINK;
      });
    }
  }

  private createLightCoverage(): void {
    this.paused = true;
    const ambient = director.getScene()!.globals.ambient;
    this.previousAmbient = ambient.skyIllum;
    ambient.skyIllum = 0;
    this.box('PublicFloor', new Vec3(0, -1.25, 0), new Vec3(7, 0.15, 5), new Color(180, 180, 180));
    this.cube = this.box('PrivateMeshRenderer', new Vec3(0, 0, 0), new Vec3(1.8, 1.8, 1.8), new Color(235, 235, 235));
    // A real 3D mesh has no UITransform. Keep that condition for privacy verification.
    this.privacy = this.cube.addComponent(ReplayPrivacy);
    this.privacy.enabled = false;
    this.lightNames.forEach((name, index) => {
      const node = this.child(name);
      node.active = false;
      node.setPosition(2.5, 3.5, 3);
      node.lookAt(new Vec3(0, 0, 0));
      if (index === 0) node.addComponent(DirectionalLight).illuminance = 65000;
      else if (index === 1) { const light = node.addComponent(PointLight); light.range = 9; light.luminance = 5000; }
      else if (index === 2) { const light = node.addComponent(SphereLight); light.range = 9; light.size = 0.15; light.luminance = 5000; }
      else { const light = node.addComponent(SpotLight); light.range = 9; light.spotAngle = 70; light.luminance = 5000; }
      this.lightNodes.push(node);
    });
  }

  private applyLightState(stage: string): void {
    this.cube.active = this.meshVisible;
    this.cube.setPosition(this.meshMoved ? 0.7 : 0, this.meshMoved ? 0.2 : 0, 0);
    this.cube.setRotationFromEuler(this.meshMoved ? 20 : 0, this.meshMoved ? 38 : 0, this.meshMoved ? 12 : 0);
    this.lightNodes.forEach((node, index) => {
      node.active = index === this.lightIndex && this.lightOn;
      const light = node.getComponent(DirectionalLight) || node.getComponent(PointLight) || node.getComponent(SphereLight) || node.getComponent(SpotLight);
      if (light) light.color = this.lightTint ? new Color(40, 220, 255) : new Color(255, 90, 40);
    });
    if (this.privacy) {
      this.privacy.mode = this.meshPrivacy === 'hide' ? ReplayPrivacyMode.Hide : ReplayPrivacyMode.Mask;
      this.privacy.enabled = this.meshPrivacy !== 'default';
    }
    const state = this.lightNames[this.lightIndex] + ' / ' + (this.lightTint ? 'cyan' : 'orange') + ' / light:' + this.lightOn + ' / mesh:' + this.meshVisible + ' / moved:' + this.meshMoved + ' / privacy:' + this.meshPrivacy;
    if (this.lightLegend) this.lightLegend.string = '3D mesh + four real lights · batch 08\n' + state;
    this.trackLight?.(stage + ' / ' + state);
  }
}
