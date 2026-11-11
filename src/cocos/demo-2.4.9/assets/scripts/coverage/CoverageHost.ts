import { CoverageKind } from './CoverageCatalog';
import { ReplayBasicScene } from './ReplayBasicScene';
import { ReplayInputScene } from './ReplayInputScene';
import { ReplayScrollScene } from './ReplayScrollScene';
import { ReplayLayoutScene } from './ReplayLayoutScene';
import { ReplayEffectsScene } from './ReplayEffectsScene';
import { ReplayMotionScene } from './ReplayMotionScene';
import { ReplayAssetScene } from './ReplayAssetScene';
import { WebViewValidationScene } from './WebViewValidationScene';
import { ReplayNativeScene } from './ReplayNativeScene';
import { ReplayEvidenceScene } from './ReplayEvidenceScene';
import { ReplayVersionDiffScene } from './ReplayVersionDiffScene';

type Track = (caseId: string, stage: string) => void;
type CoverageComponent = cc.Component & { initialize(exit: () => void, track: Track): void | Promise<void> };
const scenes: Partial<Record<CoverageKind, new () => CoverageComponent>> = {
  basic: ReplayBasicScene, input: ReplayInputScene, scroll: ReplayScrollScene, layout: ReplayLayoutScene,
  effects: ReplayEffectsScene, motion: ReplayMotionScene, assets: ReplayAssetScene,
  native: ReplayNativeScene, evidence: ReplayEvidenceScene, 'version-diff': ReplayVersionDiffScene,
};

/** Reuse Creator 2's single Canvas while isolating the reference camera and viewport. */
export class CoverageHost {
  private canvas: cc.Canvas;
  private previousCanvas: { resolution: cc.Size; width: boolean; height: boolean; position: cc.Vec3; size: cc.Size };
  private camera: cc.Camera;
  private node: cc.Node;
  private disposed = false;
  private previousResolution = cc.view.getDesignResolutionSize();
  private previousPolicy = cc.view.getResolutionPolicy();
  private restorePhysics = snapshotPhysics();
  private resumePhysics?: () => void;
  private audio: cc.AudioSource[] = [];

  constructor(private root: cc.Node, private mainCamera: cc.Camera,
    private selectCamera: (camera: cc.Camera) => void, private exit: () => void, private track: Track) {
    root.active = false;
    mainCamera.enabled = false;
    this.canvas = root.parent!.getComponent(cc.Canvas)!;
    this.previousCanvas = { resolution: this.canvas.designResolution, width: this.canvas.fitWidth,
      height: this.canvas.fitHeight, position: this.canvas.node.position.clone(), size: this.canvas.node.getContentSize() };
    this.canvas.designResolution = cc.size(960, 640);
    this.canvas.fitWidth = true; this.canvas.fitHeight = true;
    this.canvas.node.setPosition(480, 320);
    this.canvas.node.setContentSize(960, 640);
    const scene = cc.director.getScene()!;
    this.camera = new cc.Node('ComponentCoverageCamera').addComponent(cc.Camera);
    scene.addChild(this.camera.node);
    this.camera.node.setPosition(this.canvas.node.x, this.canvas.node.y, 1000);
    this.camera.ortho = true;
    this.camera.orthoSize = 320;
    this.camera.backgroundColor = cc.color(12, 18, 34);
    this.camera.clearFlags = cc.Camera.ClearFlags.COLOR | cc.Camera.ClearFlags.DEPTH | cc.Camera.ClearFlags.STENCIL;
    cc.view.setDesignResolutionSize(960, 640, cc.ResolutionPolicy.SHOW_ALL);
    this.node = new cc.Node('ComponentCoverage');
    this.node.setContentSize(960, 640);
    this.canvas.node.addChild(this.node);
    this.selectCamera(this.camera);
  }

  async open(kind: CoverageKind, webUrl: string): Promise<void> {
    const back = () => { if (!this.disposed) this.exit(); };
    const track: Track = (id, stage) => { if (!this.disposed) this.track(id, stage); };
    if (kind === 'webview') {
      this.node.addComponent(WebViewValidationScene).initialize(back, track, webUrl);
    } else {
      const Scene = scenes[kind];
      if (!Scene) throw new Error('This coverage page is unavailable in Creator 2.4.9.');
      if (kind === 'native') this.camera.ortho = false;
      await this.node.addComponent(Scene).initialize(back, track);
    }
  }

  pause(): void {
    if (this.disposed || this.resumePhysics) return;
    this.resumePhysics = snapshotPhysics();
    cc.director.getPhysicsManager().enabled = false;
    const physics3D = getPhysics3D();
    if (physics3D) physics3D.enabled = false;
    this.audio = this.node.getComponentsInChildren(cc.AudioSource).filter(audio => audio.isPlaying);
    this.audio.forEach(audio => audio.pause());
  }

  resume(): void {
    if (this.disposed) return;
    this.resumePhysics?.(); this.resumePhysics = undefined;
    this.audio.forEach(audio => { if (audio.isValid && audio.node.activeInHierarchy) audio.play(); });
    this.audio = [];
  }

  destroy(): void {
    if (this.disposed) return;
    this.disposed = true;
    this.audio = []; this.resumePhysics = undefined;
    this.selectCamera(this.mainCamera);
    this.node.active = false; this.node.destroy();
    this.camera.enabled = false; this.camera.node.destroy();
    this.canvas.designResolution = this.previousCanvas.resolution;
    this.canvas.fitWidth = this.previousCanvas.width; this.canvas.fitHeight = this.previousCanvas.height;
    this.canvas.node.setPosition(this.previousCanvas.position);
    this.canvas.node.setContentSize(this.previousCanvas.size);
    cc.view.setDesignResolutionSize(this.previousResolution.width, this.previousResolution.height, this.previousPolicy);
    this.mainCamera.enabled = true;
    this.root.active = true;
    cc.director.once(cc.Director.EVENT_AFTER_DRAW, this.restorePhysics);
  }
}

// Creator 2's declarations do not include the runtime 3D physics manager.
interface Physics3D { enabled: boolean; gravity: cc.Vec3 }
function getPhysics3D(): Physics3D | undefined {
  return (cc.director as cc.Director & { getPhysics3DManager?(): Physics3D | undefined }).getPhysics3DManager?.();
}
function snapshotPhysics(): () => void {
  const collision = cc.director.getCollisionManager(), enabledCollision = collision.enabled;
  const physics = cc.director.getPhysicsManager();
  const enabled2D = physics.enabled, gravity2D = physics.gravity.clone(), accumulator = physics.enabledAccumulator;
  const physics3D = getPhysics3D(), enabled3D = physics3D?.enabled, gravity3D = physics3D?.gravity.clone();
  return () => {
    collision.enabled = enabledCollision;
    physics.enabled = enabled2D; physics.gravity = gravity2D; physics.enabledAccumulator = accumulator;
    if (physics3D && enabled3D !== undefined && gravity3D) { physics3D.enabled = enabled3D; physics3D.gravity = gravity3D; }
  };
}
