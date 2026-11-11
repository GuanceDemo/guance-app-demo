import * as cc from 'cc';
import { _decorator, Button, Camera, Canvas, Color, Component, DirectionalLight, EventHandler, ImageAsset, Label, Layers, LightProbeGroup, Material, Mesh, MeshRenderer, Node, RangedDirectionalLight, Sorting, Sprite, SpriteFrame, Texture2D, UICoordinateTracker, UITransform, Vec3, director, gfx, primitives, resources, utils, view } from 'cc';
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = _decorator;
const PANEL = new Color(27, 39, 64);
const ORANGE = new Color(248, 164, 44);
const CYAN = new Color(40, 210, 220);

/** Sorting, actual coordinate callback, editor-only probes and a bounded light. */
@ccclass('ReplaySupportScene')
export class ReplaySupportScene extends Component {
  private frames: SpriteFrame[] = [];
  private textures: Texture2D[] = [];
  private images: ImageAsset[] = [];
  private materials: Material[] = [];
  private meshes: Mesh[] = [];
  private follower?: Node;
  private trackerStatus?: Label;
  private trackerTarget?: UITransform;
  private disposed = false;
  private previousAmbient?: number;
  private coverageCamera?: Camera;
  private previousCameraVisibility?: number;

  async initialize(exit: () => void, track: (id: string, stage: string) => void): Promise<void> {
    const load = (name: string) => new Promise<Material>((resolve, reject) => resources.load(name, Material, (e, m) => e ? reject(e) : resolve(m)));
    const [unlit, pbr] = await Promise.all([load('ReplayUIModel'), load('Replay3D')]);
    if (!this.isValid || this.disposed) return;
    const white = this.frame();
    this.label(this.node, 'Replay bounded light followup · batch 16', 0, 282, 930, 40, 24);
    this.label(this.node, 'Same PBR receiver: Directional positive control, RangedDirectional color/intensity, native transform readback.', 0, 242, 930, 30, 14);
    const group = this.child(this.node, 'Cases', 0, 0, 960, 430);
    const names = ['Sorting2D', 'Sorting', 'UICoordinateTracker', 'LightProbeGroup', 'RangedDirectionalLight'];
    const ys = [170, 95, 20, -55, -140];
    const bodies: Node[] = [], privacy: ReplayPrivacy[] = [], notes: Label[] = [];
    names.forEach((name, i) => {
      this.label(group, `J0${i + 1} / ${name}`, -330, ys[i]!, 265, 50, 16);
      for (const [suffix, x, y, w, h] of [['Top',0,32,358,3],['Bottom',0,-32,358,3],['Left',-179,0,3,64],['Right',179,0,3,64]] as const) this.panel(group,name+suffix,x,ys[i]!+y,w,h,new Color(44,202,178),white);
      const body = this.panel(group, name + 'Container', 0, ys[i]!, 348, 54, PANEL, white);
      bodies.push(body);const p=body.addComponent(ReplayPrivacy);p.enabled=false;privacy.push(p);
      notes.push(this.label(group, '', 330, ys[i]!, 245, 50, 13));
    });
    const sorting2DPresent = typeof (cc as unknown as Record<string, unknown>).Sorting2D === 'function';
    this.label(bodies[0]!, sorting2DPresent ? 'Sorting2D export present: separate test required' : 'Sorting2D absent from this engine export', 0, 0, 340, 45, 13);
    notes[0]!.string = 'Optional feature export\nNo runtime capture claim';

    bodies[1]!.getComponent(Sprite)!.enabled=false;
    const quad = utils.createMesh({positions:[-65,-18,0,65,-18,0,65,18,0,-65,18,0],indices:[0,1,2,0,2,3],minPos:new Vec3(-65,-18,0),maxPos:new Vec3(65,18,0)});
    this.meshes.push(quad);
    const sorted = (name:string,x:number,color:Color) => {
      const n=this.child(bodies[1]!,name,x,0,130,36);n.active=false;n.setPosition(x,0,1);
      const m=n.addComponent(MeshRenderer);m.visibility=Layers.Enum.UI_2D;m.mesh=quad;
      // Model ordering is observed in the transparent queue, without depth
      // rejecting the later quad. Alpha stays 1 so the overlap has a clear winner.
      const mat=new Material();mat.initialize({effectAsset:unlit.effectAsset,states:{depthStencilState:{depthTest:false,depthWrite:false},blendState:{targets:[{blend:true,blendSrc:gfx.BlendFactor.SRC_ALPHA,blendDst:gfx.BlendFactor.ONE_MINUS_SRC_ALPHA}]}}});mat.setProperty('mainColor',color);
      this.materials.push(mat);m.setSharedMaterial(mat,0);
      const sort=n.addComponent(Sorting);n.active=true;return {node:n,sort,model:m};
    };
    const a=sorted('OrangeSortedModel',-30,ORANGE), b=sorted('CyanSortedModel',30,CYAN);

    this.follower=this.panel(bodies[2]!,'TrackerCallbackSprite',-60,-4,58,28,ORANGE,white);
    const driver=this.child(bodies[2]!,'Tracked3DPoint',-60,-4,0,0);driver.setPosition(-60,-4,20);
    const tracker=driver.addComponent(UICoordinateTracker);
    let ancestor:Node|null=this.node;let camera:Camera|null=null;
    while(ancestor&&!camera){camera=ancestor.getComponent(Canvas)?.cameraComponent??null;ancestor=ancestor.parent;}
    if(!camera)throw new Error('Coverage Canvas camera missing');
    // Builtin pipeline chooses the full forward path only for cameras whose
    // visibility includes DEFAULT. Its UI-only path omits additive light queues.
    this.coverageCamera=camera;this.previousCameraVisibility=camera.visibility;
    camera.visibility|=Layers.Enum.DEFAULT;
    tracker.camera=camera;tracker.target=bodies[2]!;tracker.distance=980;tracker.useScale=true;this.trackerTarget=bodies[2]!.getComponent(UITransform)!;
    const event=new EventHandler();event.target=this.node;event.component='ReplaySupportScene';event.handler='onCoordinate';tracker.syncEvents=[event];
    this.trackerStatus=notes[2];

    const probeNode=this.child(bodies[3]!,'ActualLightProbeGroup',0,0,0,0);
    const probes=probeNode.addComponent(LightProbeGroup);probes.probes=[new Vec3(-1,-1,-1),new Vec3(1,-1,-1),new Vec3(-1,1,-1),new Vec3(1,1,-1),new Vec3(-1,-1,1),new Vec3(1,-1,1),new Vec3(-1,1,1),new Vec3(1,1,1)];
    this.label(bodies[3]!,'Editor probe data; no runtime gizmo/independent image',0,0,340,45,12);

    bodies[4]!.getComponent(Sprite)!.enabled=false;
    const meshNode=this.child(bodies[4]!,'LightReceiver',0,0,1,1);meshNode.active=false;meshNode.setPosition(0,0,80);meshNode.setScale(65,38,30);meshNode.setRotationFromEuler(12,25,0);
    const receiver=meshNode.addComponent(MeshRenderer);receiver.visibility=Layers.Enum.UI_2D;
    const cube=utils.createMesh(primitives.box());this.meshes.push(cube);receiver.mesh=cube;
    const pbrMat=new Material();pbrMat.copy(pbr);pbrMat.setProperty('mainColor',new Color(230,230,230));pbrMat.setProperty('metallic',0);pbrMat.setProperty('roughness',.65);this.materials.push(pbrMat);receiver.setSharedMaterial(pbrMat,0);meshNode.active=true;
    // Create the actual light on an active node, then set its volume transform.
    // Intensity0 keeps an off-state control without relying on node deactivation.
    const lightNode=this.child(bodies[4]!,'ActualRangedDirectionalLight',0,0,0,0);
    const light=lightNode.addComponent(RangedDirectionalLight);light.visibility=Layers.Enum.UI_2D;light.illuminance=0;
    lightNode.setPosition(0,0,300);lightNode.setScale(350,80,600);
    const controlNode=this.child(this.node,'DirectionalPositiveControl',0,0,0,0);
    const control=controlNode.addComponent(DirectionalLight);control.visibility=Layers.Enum.UI_2D;control.illuminance=0;
    const ambient=director.getScene()!.globals.ambient;this.previousAmbient=ambient.skyIllum;ambient.skyIllum=0;

    let variant=false,lightOn=false,moved=false,visible=true,probeOn=true,controlOn=false,luxIndex=0;
    const luxLevels=[65000,650,6.5,.065];
    let mode:'default'|'mask'|'hide'='default';
    const status=this.label(this.node,'',0,-216,930,22,13);
    const apply=(stage:string) => {
      group.setPosition(moved?28:0,moved?-8:0);group.setScale(moved?.85:1,moved?.85:1,1);
      bodies.forEach((n,i)=>{n.active=visible;privacy[i]!.mode=mode==='hide'?ReplayPrivacyMode.Hide:ReplayPrivacyMode.Mask;privacy[i]!.enabled=mode!=='default'&&[1,2,4].indexOf(i)>=0;});
      a.sort.sortingOrder=variant?20:0;b.sort.sortingOrder=variant?0:20;
      driver.setPosition(variant?60:-60,variant?4:-4,variant?220:20);
      this.follower!.getComponent(Sprite)!.color=variant?CYAN:ORANGE;
      probes.enabled=probeOn;
      light.color=variant?new Color(40,220,255):new Color(255,90,40);
      light.illuminance=lightOn&&!controlOn?luxLevels[luxIndex]!:0;control.illuminance=controlOn?65000:0;
      lightNode.setPosition(0,0,variant?320:300);
      notes[1]!.string=`orders A:${a.sort.sortingOrder} B:${b.sort.sortingOrder}\npriorities ${a.model.priority}/${b.model.priority}`;
      notes[3]!.string=`enabled:${probes.enabled} probes:${probes.probes.length}\nBaked lighting not claimed`;
      notes[4]!.string=`ranged:${lightOn&&!controlOn} control:${controlOn}\nlux:${light.illuminance} ${variant?'cyan':'orange'}`;
      status.string=`${stage} | variant:${+variant} ranged:${lightOn&&!controlOn} control:${controlOn} privacy:${mode}`;
      track('page',stage);
      this.scheduleOnce(()=>{
        if(this.disposed||!this.isValid)return;
        const scene=director.getScene()!.renderScene!;
        // JSB exposes methods; the Web backend exposes vector properties.
        const native=scene.rangedDirLights[0];
        const xyz=(v:Readonly<Vec3>|undefined)=>v?[v.x,v.y,v.z]:null;
        const vector=(name:'position'|'scale'|'direction'|'right')=>{
          const source=native as unknown as Record<string,unknown>|undefined;
          const getter=source?.['get'+name[0]!.toUpperCase()+name.slice(1)];
          return xyz((typeof getter==='function'?getter.call(native):source?.[name]) as Readonly<Vec3>|undefined);
        };
        const bounds=receiver.model?.worldBounds;
        console.log('[ReplaySupportScene] ranged-native',JSON.stringify({stage,rangedEnabled:light.enabledInHierarchy,rangedBaked:light.baked,rangedIlluminance:light.illuminance,controlIlluminance:control.illuminance,nativeCount:scene.rangedDirLights.length,native:native?{type:native.type,baked:native.baked,position:vector('position'),scale:vector('scale'),direction:vector('direction'),right:vector('right'),illuminanceHDR:native.illuminanceHDR,illuminanceLDR:native.illuminanceLDR}:null,nodeWorldPosition:xyz(lightNode.worldPosition),nodeWorldScale:xyz(lightNode.worldScale),receiverBounds:bounds?{center:xyz(bounds.center),half:xyz(bounds.halfExtents)}:null,receiverPasses:receiver.getMaterialInstance(0)?.passes.map(p=>({phase:p.phase,phaseID:p.phaseID}))}));
      },.3);
    };
    const commands:Array<[string,()=>void]>=[
      ['Change order / tracker / tint',()=>{variant=!variant;apply('changed');}],
      ['Ranged light on / off',()=>{lightOn=!lightOn;apply(lightOn?'light-on':'light-off');}],
      ['Directional positive control',()=>{controlOn=!controlOn;apply(controlOn?'control-on':'control-off');}],
      ['Move + scale',()=>{moved=!moved;apply('transformed');}],
      ['Hide / show',()=>{visible=!visible;apply(visible?'shown':'hidden');}],
      ['Privacy default / mask / hide',()=>{mode=mode==='default'?'mask':mode==='mask'?'hide':'default';apply('privacy-'+mode);}],
      ['Reset',()=>{variant=false;lightOn=false;moved=false;visible=true;probeOn=true;controlOn=false;luxIndex=0;mode='default';apply('reset');}],
      ['Back',()=>{if(!this.disposed){this.disposed=true;exit();}}],
    ];
    commands.forEach(([caption,click],i)=>{const button=this.panel(this.node,'Command'+i,-345+i%4*230,i<4?-245:-295,218,38,PANEL,white);button.addComponent(Button);button.on('click',()=>{if(!this.disposed)click();});this.label(button,caption,0,0,212,34,12);});
    const luxButton=this.panel(this.node,'LuxSweep',0,215,330,18,PANEL,white);luxButton.addComponent(Button);luxButton.on('click',()=>{luxIndex=(luxIndex+1)%luxLevels.length;apply('lux-'+luxLevels[luxIndex]);});this.label(luxButton,'Ranged lux 65000 / 650 / 6.5 / 0.065',0,0,325,18,11);
    apply('entered');
  }

  onCoordinate(position:Vec3,scale:number):void {
    if(!this.follower)return;
    // The existing sample camera uses a centered UI stage. convertToUINode adds
    // the design half-size for a bottom-left-origin Canvas; remove that constant
    // as a local-space vector, including the container's scale, in this callback.
    const size=view.getVisibleSize(), target=this.trackerTarget!;
    const center=target.convertToNodeSpaceAR(new Vec3(size.width/2,size.height/2,0));
    const origin=target.convertToNodeSpaceAR(Vec3.ZERO);
    const x=position.x-center.x+origin.x,y=position.y-center.y+origin.y;
    this.follower.setPosition(x,y,0);this.follower.setScale(scale,scale,1);
    if(this.trackerStatus)this.trackerStatus.string=`callback x:${x.toFixed(1)} y:${y.toFixed(1)}\nscale:${scale.toFixed(2)}`;
  }
  private frame():SpriteFrame {const image=new ImageAsset({_data:coverageTexturePixels(false),width:32,height:32,format:Texture2D.PixelFormat.RGBA8888,_compressed:false});const texture=new Texture2D();texture.image=image;const frame=new SpriteFrame();frame.texture=texture;frame.packable=false;this.images.push(image);this.textures.push(texture);this.frames.push(frame);return frame;}
  private child(parent:Node,name:string,x:number,y:number,w:number,h:number):Node {const n=new Node(name);n.layer=Layers.Enum.UI_2D;n.addComponent(UITransform).setContentSize(w,h);n.setPosition(x,y);parent.addChild(n);return n;}
  private panel(parent:Node,name:string,x:number,y:number,w:number,h:number,color:Color,frame:SpriteFrame):Node {const n=this.child(parent,name,x,y,w,h);const s=n.addComponent(Sprite);s.sizeMode=Sprite.SizeMode.CUSTOM;s.spriteFrame=frame;s.color=color;return n;}
  private label(parent:Node,text:string,x:number,y:number,w:number,h:number,size:number):Label {const n=this.child(parent,'Label',x,y,w,h);const l=n.addComponent(Label);l.overflow=Label.Overflow.CLAMP;n.getComponent(UITransform)!.setContentSize(w,h);l.string=text;l.fontSize=size;l.lineHeight=20;l.color=new Color(239,244,255);l.horizontalAlign=Label.HorizontalAlign.CENTER;l.verticalAlign=Label.VerticalAlign.CENTER;return l;}
  onDestroy():void {this.disposed=true;this.follower=undefined;if(this.coverageCamera?.isValid&&this.previousCameraVisibility!==undefined)this.coverageCamera.visibility=this.previousCameraVisibility;if(this.previousAmbient!==undefined){const scene=director.getScene();if(scene)scene.globals.ambient.skyIllum=this.previousAmbient;}this.frames.forEach(x=>x.destroy());this.textures.forEach(x=>x.destroy());this.images.forEach(x=>x.destroy());this.materials.forEach(x=>x.destroy());this.meshes.forEach(x=>x.destroy());}
}
