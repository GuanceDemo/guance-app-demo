import {
  AudioSource, Camera, Canvas, Color, Component, Director, Layers, Node,
  PhysicsSystem, PhysicsSystem2D, ResolutionPolicy, UITransform, VideoPlayer, director, view,
} from 'cc';
import { CoverageKind } from './CoverageCatalog';
import { ReplayBasicScene } from './ReplayBasicScene';
import { ReplayInputScene } from './ReplayInputScene';
import { ReplayScrollScene } from './ReplayScrollScene';
import { ReplayLayoutScene } from './ReplayLayoutScene';
import { ReplayEffectsScene } from './ReplayEffectsScene';
import { ReplayMotionScene } from './ReplayMotionScene';
import { ReplayAssetScene } from './ReplayAssetScene';
import { WebViewValidationScene } from './WebViewValidationScene';
import { ReplayRenderScene } from './ReplayRenderScene';
import { ReplayGeometryScene } from './ReplayGeometryScene';
import { ReplayRigScene } from './ReplayRigScene';
import { ReplayEvidenceScene } from './ReplayEvidenceScene';
import { ReplaySupportScene } from './ReplaySupportScene';
import { ReplayOptionalScene } from './ReplayOptionalScene';
import { Replay3DScene } from './Replay3DScene';
import { ReplayPostProcessScene } from './ReplayPostProcessScene';

type Track = (caseId: string, stage: string) => void;
type CoverageComponent = Component & { initialize(exit: () => void, track: Track): void | Promise<void> };
const scenes: Partial<Record<CoverageKind, new () => CoverageComponent>> = {
  basic: ReplayBasicScene, input: ReplayInputScene, scroll: ReplayScrollScene, layout: ReplayLayoutScene,
  effects: ReplayEffectsScene, motion: ReplayMotionScene, assets: ReplayAssetScene, render: ReplayRenderScene,
  geometry: ReplayGeometryScene, rig: ReplayRigScene, evidence: ReplayEvidenceScene,
  support: ReplaySupportScene, optional: ReplayOptionalScene,
};

/** Isolate the reference's 960x640 scenes from the demo's portrait UI and camera. */
export class CoverageHost {
  private canvas: Node;
  private camera: Camera;
  private node: Node;
  private disposed = false;
  private previousResolution = view.getDesignResolutionSize();
  private previousPolicy = view.getResolutionPolicy();
  private restorePhysics = snapshotPhysics();
  private resumePhysics?: () => void;
  private media: Array<AudioSource | VideoPlayer> = [];

  constructor(private root: Node, private mainCamera: Camera,
    private selectCamera: (camera: Camera) => void, private exit: () => void, private track: Track) {
    root.active = false;
    mainCamera.enabled = false;
    view.setDesignResolutionSize(960, 640, ResolutionPolicy.SHOW_ALL);
    const scene = director.getScene()!;
    this.canvas = new Node('ComponentCoverageCanvas');
    this.canvas.layer = Layers.Enum.UI_2D;
    this.canvas.addComponent(UITransform).setContentSize(960, 640);
    scene.addChild(this.canvas);
    const cameraNode = new Node('ComponentCoverageCamera');
    cameraNode.setPosition(0, 0, 1000);
    scene.addChild(cameraNode);
    this.camera = cameraNode.addComponent(Camera);
    this.camera.projection = Camera.ProjectionType.ORTHO;
    this.camera.orthoHeight = 320;
    this.camera.visibility = Layers.Enum.UI_2D;
    this.camera.clearColor = new Color(12, 18, 34);
    this.canvas.addComponent(Canvas).cameraComponent = this.camera;
    this.node = new Node('ComponentCoverage');
    this.node.layer = Layers.Enum.UI_2D;
    this.node.addComponent(UITransform).setContentSize(960, 640);
    this.canvas.addChild(this.node);
    this.selectCamera(this.camera);
  }

  async open(kind: CoverageKind, webUrl: string): Promise<void> {
    const back = () => { if (!this.disposed) this.exit(); };
    const track: Track = (id, stage) => { if (!this.disposed) this.track(id, stage); };
    if (kind === 'perspective' || kind === 'lights' || kind === 'postprocess') {
      this.canvas.active = false;
      this.camera.enabled = false;
      this.node.removeFromParent();
      director.getScene()!.addChild(this.node);
      if (kind === 'postprocess') {
        const probe = new Node('CoverageCaptureDisabled');
        this.node.addChild(probe);
        const disabled = probe.addComponent(Camera);
        disabled.enabled = false;
        this.selectCamera(disabled);
        const page = this.node.addComponent(ReplayPostProcessScene);
        await page.initialize(back, track, enabled => {
          if (!this.disposed) this.selectCamera(enabled ? page.camera : disabled);
        });
      } else {
        const page = this.node.addComponent(Replay3DScene);
        await page.initialize(back, kind === 'lights', stage => track('lights', stage));
        if (!this.disposed) this.selectCamera(page.camera);
      }
    } else if (kind === 'webview') {
      this.node.addComponent(WebViewValidationScene).initialize(back, track, webUrl);
    } else {
      const Scene = scenes[kind];
      if (!Scene) throw new Error('This coverage page is unavailable in Creator 3.8.8.');
      await this.node.addComponent(Scene).initialize(back, track);
    }
  }

  pause(): void {
    if (this.disposed || this.resumePhysics) return;
    this.resumePhysics = snapshotPhysics();
    if (PhysicsSystem2D.instance) PhysicsSystem2D.instance.enable = false;
    if (PhysicsSystem.instance) PhysicsSystem.instance.enable = false;
    this.media = [...this.node.getComponentsInChildren(AudioSource).filter(audio => audio.playing),
      ...this.node.getComponentsInChildren(VideoPlayer).filter(video => video.isPlaying)];
    this.media.forEach(media => media.pause());
  }

  resume(): void {
    if (this.disposed) return;
    this.resumePhysics?.(); this.resumePhysics = undefined;
    this.media.forEach(media => { if (media.isValid && media.node.activeInHierarchy) media.play(); });
    this.media = [];
  }

  destroy(): void {
    if (this.disposed) return;
    this.disposed = true;
    this.media = []; this.resumePhysics = undefined;
    this.selectCamera(this.mainCamera);
    this.node.active = false; this.node.destroy();
    this.canvas.active = false; this.canvas.destroy();
    this.camera.enabled = false; this.camera.node.destroy();
    view.setDesignResolutionSize(this.previousResolution.width, this.previousResolution.height, this.previousPolicy);
    this.mainCamera.enabled = true;
    this.root.active = true;
    // Evidence fixtures stop global physics in onDestroy, after Node.destroy() returns.
    director.once(Director.EVENT_AFTER_DRAW, this.restorePhysics);
  }
}

function snapshotPhysics(): () => void {
  const two = PhysicsSystem2D.instance, three = PhysicsSystem.instance;
  const enabled2D = two?.enable, gravity2D = two?.gravity.clone(), auto2D = two?.autoSimulation;
  const enabled3D = three?.enable, gravity3D = three?.gravity.clone(), auto3D = three?.autoSimulation;
  return () => {
    if (two && gravity2D && enabled2D !== undefined && auto2D !== undefined) {
      two.gravity = gravity2D; two.autoSimulation = auto2D; two.enable = enabled2D;
    }
    if (three && gravity3D && enabled3D !== undefined && auto3D !== undefined) {
      three.gravity = gravity3D; three.autoSimulation = auto3D; three.enable = enabled3D;
    }
  };
}
