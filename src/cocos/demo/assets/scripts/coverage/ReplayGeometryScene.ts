import { _decorator, Billboard, Button, Color, Component, GradientRange, ImageAsset, Label, Layers, LODGroup, Material, Mesh, MeshRenderer, Node, ParticleSystem, ReflectionProbe, ReflectionProbeType, Sprite, SpriteFrame, Texture2D, TextureCube, UITransform, Vec3, director, primitives, resources, utils, Line } from 'cc';
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = _decorator;
const PANEL=new Color(27,39,64),ORANGE=new Color(248,164,44),CYAN=new Color(40,210,220);

@ccclass('ReplayGeometryScene')
export class ReplayGeometryScene extends Component {
  private frames:SpriteFrame[]=[];
  private textures:Texture2D[]=[];
  private cubes:TextureCube[]=[];
  private images:ImageAsset[]=[];
  private materials:Material[]=[];
  private meshes:Mesh[]=[];
  private disposed=false;
  private restoreGlobals?:()=>void;

  async initialize(exit:()=>void,track:(id:string,stage:string)=>void):Promise<void> {
    const load=(name:string)=>new Promise<Material>((resolve,reject)=>resources.load(name,Material,(e,m)=>e?reject(e):resolve(m)));
    const [unlit,pbr]=await Promise.all([load('ReplayUIModel'),load('Replay3D')]);
    if(!this.isValid||this.disposed||!this.node.activeInHierarchy)return;
    const white=this.frame(false),pattern=this.frame(true);
    this.label(this.node,'Replay LOD / billboard / line / particles / probe · batch 13',0,282,930,40,23);
    this.label(this.node,'Forced LOD levels, bounded CPU particles and cubemap preview binding are explicit test scopes.',0,242,930,30,14);
    const group=this.child(this.node,'Cases',0,0,960,430);
    const names=['LOD Group','Billboard','Line','ParticleSystem','ReflectionProbe'];
    const ys=[170,95,20,-55,-140];const bodies:Node[]=[],privacy:ReplayPrivacy[]=[],notes:Label[]=[];
    names.forEach((name,i)=>{
      this.label(group,`K0${i+1} / ${name}`,-330,ys[i]!,255,50,16);
      for(const [suffix,x,y,w,h]of [['Top',0,32,358,3],['Bottom',0,-32,358,3],['Left',-179,0,3,64],['Right',179,0,3,64]]as const)this.panel(group,name+suffix,x,ys[i]!+y,w,h,new Color(44,202,178),white);
      const body=this.child(group,name+'Container',0,ys[i]!,348,54);bodies.push(body);const p=body.addComponent(ReplayPrivacy);p.enabled=false;privacy.push(p);
      notes.push(this.label(group,'',330,ys[i]!,245,50,13));
    });
    const quad=utils.createMesh({positions:[-80,-15,0,80,-15,0,80,15,0,-80,15,0],indices:[0,1,2,0,2,3],minPos:new Vec3(-80,-15,0),maxPos:new Vec3(80,15,0)});
    const triangle=utils.createMesh({positions:[-70,-16,0,70,-16,0,0,16,0],indices:[0,1,2],minPos:new Vec3(-70,-16,0),maxPos:new Vec3(70,16,0)});this.meshes.push(quad,triangle);
    const model=(parent:Node,name:string,mesh:Mesh,color:Color,w:number,h:number)=>{
      const n=this.child(parent,name,0,0,w,h);n.active=false;n.setPosition(0,0,1);
      const m=n.addComponent(MeshRenderer);m.visibility=Layers.Enum.UI_2D;m.mesh=mesh;
      const mat=new Material();mat.copy(unlit);mat.setProperty('mainColor',color);this.materials.push(mat);m.setSharedMaterial(mat,0);n.active=true;return m;
    };
    const high=model(bodies[0]!,'LOD0Quad',quad,ORANGE,160,30),low=model(bodies[0]!,'LOD1Triangle',triangle,CYAN,140,32);
    const lod=bodies[0]!.addComponent(LODGroup);lod.insertLOD(0,.5).renderers=[high];lod.insertLOD(1,.1).renderers=[low];lod.recalculateBounds();

    const billboardNode=this.child(bodies[1]!,'ActualBillboard',0,0,150,40);billboardNode.setPosition(0,0,1);
    const billboard=billboardNode.addComponent(Billboard);billboard.width=140;billboard.height=28;billboard.texture=pattern.texture as Texture2D;

    const lineNode=this.child(bodies[2]!,'ActualLine',0,0,220,40);lineNode.setPosition(0,0,1);
    const line=lineNode.addComponent(Line);line.visibility=Layers.Enum.UI_2D;line.worldSpace=false;
    line.width.constant=7;line.width=line.width;

    const particleNode=this.child(bodies[3]!,'Actual3DParticles',0,0,0,0);particleNode.setPosition(0,0,1);
    const particle=particleNode.addComponent(ParticleSystem);particle.visibility=Layers.Enum.UI_2D;particle.stop();particle.capacity=24;particle.playOnAwake=false;particle.renderer.useGPU=false;
    particle.startLifetime.constant=100;particle.startSpeed.constant=0;particle.gravityModifier.constant=0;particle.rateOverTime.constant=24;particle.startSizeX.constant=16;
    if(particle.shapeModule){particle.shapeModule.enable=true;particle.shapeModule.radius=10;}
    const pulse=(color:Color)=>{
      particle.stop();particle.clear();particle.startColor.color=color;particle.play();
      this.scheduleOnce(()=>{if(!this.isValid||this.disposed||!this.node.activeInHierarchy)return;particle.pause();notes[3]!.string=`CPU particles:${particle.getParticleCount()}\npaused; bounded pulse`;},.3);
    };

    const orangeCube=this.cube(ORANGE),cyanCube=this.cube(CYAN),blackCube=this.cube(Color.BLACK);
    const globals=director.getScene()!.globals,sky=globals.skybox;
    const oldEnv=sky.envmap,oldIBL=sky.useIBL,oldEnabled=sky.enabled,oldAmbient=globals.ambient.skyIllum;
    this.restoreGlobals=()=>{sky.useIBL=false;sky.envmap=oldEnv;sky.useIBL=oldIBL;sky.enabled=oldEnabled;globals.ambient.skyIllum=oldAmbient;};
    sky.envmap=blackCube;sky.useIBL=true;sky.enabled=false;globals.ambient.skyIllum=0;
    const sphere=utils.createMesh(primitives.sphere(1,{segments:16}));this.meshes.push(sphere);
    const sphereNode=this.child(bodies[4]!,'ProbePreviewSphere',0,0,2,2);sphereNode.active=false;sphereNode.setPosition(0,0,40);sphereNode.setScale(28,18,10);
    const preview=sphereNode.addComponent(MeshRenderer);preview.visibility=Layers.Enum.UI_2D;preview.mesh=sphere;preview.bakeSettings.reflectionProbe=ReflectionProbeType.BAKED_CUBEMAP;
    const reflectedMaterial=new Material();reflectedMaterial.initialize({effectAsset:pbr.effectAsset,defines:{USE_REFLECTION_PROBE:1}});reflectedMaterial.setProperty('mainColor',Color.WHITE);reflectedMaterial.setProperty('metallic',1);reflectedMaterial.setProperty('roughness',.1);this.materials.push(reflectedMaterial);preview.setSharedMaterial(reflectedMaterial,0);sphereNode.active=true;
    const probeNode=this.child(bodies[4]!,'ActualReflectionProbe',0,0,0,0);const probe=probeNode.addComponent(ReflectionProbe);probe.visibility=Layers.Enum.UI_2D;probe.size=new Vec3(350,54,150);
    probe.cubemap=orangeCube;probe.previewSphere=sphereNode;

    let variant=false,probeOn=true,moved=false,visible=true,lastVariant:boolean|undefined;
    let mode:'default'|'mask'|'hide'='default';const status=this.label(this.node,'',0,-216,930,22,13);
    const apply=(stage:string)=>{
      group.setPosition(moved?28:0,moved?-8:0);group.setScale(moved?.85:1,moved?.85:1,1);
      bodies.forEach((n,i)=>{n.active=visible;privacy[i]!.mode=mode==='hide'?ReplayPrivacyMode.Hide:ReplayPrivacyMode.Mask;privacy[i]!.enabled=mode!=='default';});
      lod.forceLOD(variant?1:0);billboard.texture=(variant?white:pattern).texture as Texture2D;billboard.width=variant?110:140;billboard.height=variant?34:28;billboard.rotation=variant?8:0;
      const color=new GradientRange();color.color=variant?CYAN:ORANGE;line.color=color;line.width.constant=variant?11:7;line.width=line.width;line.positions=variant?[new Vec3(-100,8,0),new Vec3(0,-10,0),new Vec3(100,8,0)]:[new Vec3(-100,-8,0),new Vec3(0,10,0),new Vec3(100,-8,0)];
      if(lastVariant!==variant){lastVariant=variant;pulse(variant?CYAN:ORANGE);}
      probe.cubemap=probeOn?(variant?cyanCube:orangeCube):null;probe.previewSphere=sphereNode;
      notes[0]!.string=`forced LOD:${variant?1:0}\nquad / triangle`;notes[1]!.string=`${variant?'white':'pattern'} ${billboard.width}x${billboard.height}\nrotation:${billboard.rotation}`;notes[2]!.string=`actual Line; width:${line.width.constant}\nlocal positions`;
      notes[4]!.string=`cube:${probeOn?(variant?'cyan':'orange'):'none'}\nactual probe preview binding`;
      status.string=`${stage} | variant:${+variant} visible:${visible} privacy:${mode}`;track('page',stage);
    };
    const commands:Array<[string,()=>void]>=[
      ['Change five cases',()=>{variant=!variant;apply('changed');}],
      ['Probe cubemap on / off',()=>{probeOn=!probeOn;apply(probeOn?'probe-on':'probe-off');}],
      ['Replay bounded CPU pulse',()=>{pulse(variant?CYAN:ORANGE);apply('particle-pulse');}],
      ['Move + scale',()=>{moved=!moved;apply('transformed');}],
      ['Hide / show',()=>{visible=!visible;apply(visible?'shown':'hidden');}],
      ['Privacy default / mask / hide',()=>{mode=mode==='default'?'mask':mode==='mask'?'hide':'default';apply('privacy-'+mode);}],
      ['Reset',()=>{variant=false;probeOn=true;moved=false;visible=true;mode='default';apply('reset');}],
      ['Back',()=>{if(!this.disposed){this.disposed=true;exit();}}],
    ];
    commands.forEach(([caption,click],i)=>{const button=this.panel(this.node,'Command'+i,-345+i%4*230,i<4?-245:-295,218,38,PANEL,white);button.addComponent(Button);button.on('click',()=>{if(!this.disposed)click();});this.label(button,caption,0,0,212,34,12);});apply('entered');
  }

  private frame(pattern:boolean):SpriteFrame {const im=new ImageAsset({_data:coverageTexturePixels(pattern),width:32,height:32,format:Texture2D.PixelFormat.RGBA8888,_compressed:false});const t=new Texture2D();t.image=im;const f=new SpriteFrame();f.texture=t;f.packable=false;this.images.push(im);this.textures.push(t);this.frames.push(f);return f;}
  private cube(color:Color):TextureCube {const pixels=new Uint8Array(16*16*4);for(let i=0;i<pixels.length;i+=4){pixels[i]=color.r;pixels[i+1]=color.g;pixels[i+2]=color.b;pixels[i+3]=255;}const im=new ImageAsset({_data:pixels,width:16,height:16,format:Texture2D.PixelFormat.RGBA8888,_compressed:false});this.images.push(im);const cube=new TextureCube();cube.image={front:im,back:im,left:im,right:im,top:im,bottom:im};this.cubes.push(cube);return cube;}
  private child(parent:Node,name:string,x:number,y:number,w:number,h:number):Node {const n=new Node(name);n.layer=Layers.Enum.UI_2D;n.addComponent(UITransform).setContentSize(w,h);n.setPosition(x,y);parent.addChild(n);return n;}
  private panel(parent:Node,name:string,x:number,y:number,w:number,h:number,color:Color,frame:SpriteFrame):Node {const n=this.child(parent,name,x,y,w,h);const s=n.addComponent(Sprite);s.sizeMode=Sprite.SizeMode.CUSTOM;s.spriteFrame=frame;s.color=color;return n;}
  private label(parent:Node,text:string,x:number,y:number,w:number,h:number,size:number):Label {const n=this.child(parent,'Label',x,y,w,h);const l=n.addComponent(Label);l.overflow=Label.Overflow.CLAMP;n.getComponent(UITransform)!.setContentSize(w,h);l.string=text;l.fontSize=size;l.lineHeight=20;l.color=new Color(239,244,255);l.horizontalAlign=Label.HorizontalAlign.CENTER;l.verticalAlign=Label.VerticalAlign.CENTER;return l;}
  onDestroy():void {this.disposed=true;this.unscheduleAllCallbacks();this.restoreGlobals?.();this.restoreGlobals=undefined;this.frames.forEach(x=>x.destroy());this.textures.forEach(x=>x.destroy());this.cubes.forEach(x=>x.destroy());this.images.forEach(x=>x.destroy());this.materials.forEach(x=>x.destroy());this.meshes.forEach(x=>x.destroy());}
}
