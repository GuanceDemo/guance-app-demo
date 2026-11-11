import { CoverageSurface, CoverageNavigation } from './CoverageSurface';
import { coverageViewport } from './CoverageLayoutModel';
import {
  AudioSource, Camera, Canvas, Color, Component, Director, Layers, Node,
  PhysicsSystem, PhysicsSystem2D, ResolutionPolicy, Rect, RenderTexture, Sprite, SpriteFrame, UITransform, VideoPlayer, director, rendering, sys, view,
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

/** Keep fixture lifecycles isolated while the surface reflows to the physical viewport. */
export class CoverageHost {
  private canvas: Node;
  private camera: Camera;
  private node: Node;
  private disposed = false;
  private surface?: CoverageSurface;
  private directory = false;
  private resizing = false;
  private sceneCamera?: Camera;
  private postOutput?: { texture: RenderTexture; frame: SpriteFrame; node: Node };
  private fieldOfView = 45;
  private readonly resize = () => this.layout();
  private previousResolution = view.getDesignResolutionSize();
  private previousPolicy = view.getResolutionPolicy();
  private restorePhysics = snapshotPhysics();
  private resumePhysics?: () => void;
  private media: Array<AudioSource | VideoPlayer> = [];

  constructor(private root: Node, private mainCamera: Camera,
    private selectCamera: (camera: Camera) => void, private exit: () => void, private track: Track, private navigation: CoverageNavigation = [['Controls', exit]]) {
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
    view.on('canvas-resize', this.resize);
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
        if (!this.disposed) this.setPerspective(page.camera);
      } else {
        const page = this.node.addComponent(Replay3DScene);
        await page.initialize(back, kind === 'lights', stage => track('lights', stage));
        if (!this.disposed) { this.setPerspective(page.camera); this.selectCamera(page.camera); }
      }
    } else if (kind === 'webview') {
      this.node.addComponent(WebViewValidationScene).initialize(back, track, webUrl);
    } else {
      const Scene = scenes[kind];
      if (!Scene) throw new Error('This coverage page is unavailable in Creator 3.8.8.');
      await this.node.addComponent(Scene).initialize(back, track);
    }
    if(this.disposed)return;
    this.surface=new CoverageSurface(this.node,kind,this.navigation);
    if(kind==='postprocess'){
      // Builtin post effects require a whole render target, not a sub-viewport.
      const texture=new RenderTexture(),frame=new SpriteFrame();texture.reset({width:1,height:1});frame.texture=texture;
      const node=new Node('CoveragePostOutput');node.layer=Layers.Enum.UI_2D;node.addComponent(UITransform);this.surface.worldCanvas.addChild(node);
      const sprite=node.addComponent(Sprite);sprite.sizeMode=Sprite.SizeMode.CUSTOM;sprite.spriteFrame=frame;
      this.postOutput={texture,frame,node};this.sceneCamera!.targetTexture=texture;
    }
    this.layout();
  }

  get galleryScrollOffset(): number | undefined { return this.directory?this.surface?.scrollOffset:undefined; }
  get scrollOffset(): number { return this.surface?.scrollOffset ?? 0; }
  gallery(data: Parameters<CoverageSurface['showGallery']>[0]): void {
    this.directory=true;
    this.surface = new CoverageSurface(this.node, 'gallery', this.navigation);
    this.surface.showGallery(data); this.layout();
  }
  update(): void { this.layout(false); this.surface?.update(); }

  private geometryKey = '';
  private currentGeometryKey(): string {
    const frame=view.getFrameSize(),design=view.getDesignResolutionSize(),safe=sys.getSafeAreaRect(false);
    return [frame.width,frame.height,design.width,design.height,safe.x,safe.y,safe.width,safe.height].join(',');
  }

  private setPerspective(camera: Camera): void { this.sceneCamera=camera; this.fieldOfView=camera.fov; }
  private layout(force = true): void {
    if(this.disposed||this.resizing||!this.surface)return;
    // iOS publishes the final safe area after canvas-resize, when rotation completes.
    if(!force && this.geometryKey===this.currentGeometryKey())return;
    this.resizing=true;
    try {
      const frame=view.getFrameSize(),viewport=coverageViewport(frame.width,frame.height);
      const current=view.getDesignResolutionSize();
      if(current.width!==viewport.width||current.height!==viewport.height)view.setDesignResolutionSize(viewport.width,viewport.height,ResolutionPolicy.EXACT_FIT);
      this.canvas.getComponent(UITransform)!.setContentSize(viewport.width,viewport.height);
      const safe=sys.getSafeAreaRect(false);
      const regions=this.surface.resize(viewport,{x:safe.x,y:safe.y,width:safe.width,height:safe.height});
      if(this.sceneCamera){
        const body=regions.body;
        if(this.postOutput){
          const {texture,node}=this.postOutput,pixelScale=Math.min(frame.width/viewport.width,2048/body.width,2048/body.height),width=Math.max(1,Math.round(body.width*pixelScale)),height=Math.max(1,Math.round(body.height*pixelScale));
          if(texture.width!==width||texture.height!==height){texture.resize(width,height);this.postOutput.frame.rect=new Rect(0,0,width,height);rendering.forceResizeAllWindows();}
          node.setPosition(body.x,body.y);node.getComponent(UITransform)!.setContentSize(body.width,body.height);
          this.sceneCamera.rect=new Rect(0,0,1,1);
        }else this.sceneCamera.rect=new Rect((body.x-body.width/2+viewport.width/2)/viewport.width,(body.y-body.height/2+viewport.height/2)/viewport.height,body.width/viewport.width,body.height/viewport.height);
        const fit=Math.min(1,body.width/body.height/(viewport.portrait?1:1.5));
        this.sceneCamera.fov=2*Math.atan(Math.tan(this.fieldOfView*Math.PI/360)/fit)*180/Math.PI;
      }
      this.geometryKey=this.currentGeometryKey();
    } finally {this.resizing=false;}
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
    this.layout();
    this.media.forEach(media => { if (media.isValid && media.node.activeInHierarchy) media.play(); });
    this.media = [];
  }

  destroy(): void {
    if (this.disposed) return;
    this.disposed = true;
    view.off('canvas-resize', this.resize);this.surface?.destroy();
    if(this.postOutput){this.postOutput.node.active=false;if(this.sceneCamera)this.sceneCamera.targetTexture=null;this.postOutput.frame.destroy();this.postOutput.texture.destroy();this.postOutput=undefined;}
    this.sceneCamera=undefined;
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
