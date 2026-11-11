import { _decorator, AnimationClip, Button, Color, Component, DirectionalLight, EffectAsset, HeightField, ImageAsset, Label, Layers, Mat4, Material, Mesh, Node, SkeletalAnimation, Skeleton, SkinnedMeshBatchRenderer, SkinnedMeshRenderer, SkinnedMeshUnit, Sprite, SpriteFrame, Terrain, TerrainInfo, TerrainLayer, Texture2D, UITransform, Vec2, Vec3, Vec4, animation, gfx, js, resources, utils } from 'cc';
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';
import { createReplayBatchEffect } from './ReplayBatchedEffect';
import { ReplayBatchRenderer } from './ReplayBatchRenderer';

const { ccclass } = _decorator;
const ORANGE=new Color(248,164,44),CYAN=new Color(40,210,220),PANEL=new Color(27,39,64);

@ccclass('ReplayRigScene')
export class ReplayRigScene extends Component {
  private assets:Array<{destroy:()=>boolean}>=[];
  private disposed=false;
  async initialize(exit:()=>void,track:(id:string,stage:string)=>void):Promise<void> {
    const base=await new Promise<Material>((resolve,reject)=>resources.load('ReplayUIModel',Material,(e,m)=>e?reject(e):resolve(m)));
    if(!this.isValid||this.disposed||!this.node.activeInHierarchy)return;
    const white=this.frame(false),pattern=this.frame(true);
    this.label(this.node,'Replay skeleton / skinning / animation graph / terrain · batch 14',0,282,930,40,22);
    this.label(this.node,'Actual two-joint meshes, two cooked batch units, Boolean graph transition, one 32x32 terrain block.',0,242,930,30,14);
    const group=this.child(this.node,'Cases',0,0,960,430);
    const names=['SkeletalAnimation','SkinnedMeshRenderer','SkinnedMeshBatchRenderer','Animation Controller','Terrain'];
    const ys=[170,95,20,-55,-140],bodies:Node[]=[],privacy:ReplayPrivacy[]=[],notes:Label[]=[];
    names.forEach((name,i)=>{
      this.label(group,`L0${i+1} / ${name}`,-330,ys[i]!,255,50,15);
      for(const [suffix,x,y,w,h]of [['Top',0,32,358,3],['Bottom',0,-32,358,3],['Left',-179,0,3,64],['Right',179,0,3,64]]as const)this.panel(group,name+suffix,x,ys[i]!+y,w,h,new Color(44,202,178),white);
      const body=this.child(group,name+'Container',0,ys[i]!,348,54);bodies.push(body);
      const p=body.addComponent(ReplayPrivacy);p.enabled=false;privacy.push(p);notes.push(this.label(group,'',330,ys[i]!,245,50,12));
    });
    const material=(color:Color)=>{const m=new Material();m.copy(base);m.setProperty('mainColor',color);m.setProperty('color',color);m.setProperty('tilingOffset',new Vec4(1,1,0,0));m.setProperty('mainTexture',white.texture);this.assets.push(m);return m;};
    const rig=(body:Node)=>{
      const root=this.child(body,'Rig',0,0,200,48);root.active=false;root.setPosition(0,0,1);
      const left=this.child(root,'LeftBone',0,0,0,0),right=this.child(root,'RightBone',0,0,0,0);
      const skeleton=new Skeleton();skeleton.joints=['LeftBone','RightBone'];skeleton.bindposes=[new Mat4(),new Mat4()];this.assets.push(skeleton);
      return {root,left,right,skeleton};
    };
    const skinned=(root:Node,skeleton:Skeleton,mesh:Mesh,mat:Material,name:string)=>{
      const n=this.child(root,name,0,0,200,48);const r=n.addComponent(SkinnedMeshRenderer);r.visibility=Layers.Enum.UI_2D;r.mesh=mesh;r.skeleton=skeleton;r.skinningRoot=root;r.setSharedMaterial(mat,0);return r;
    };
    const full=this.mesh(),leftMesh=this.mesh(0),rightMesh=this.mesh(1);
    const animated=rig(bodies[0]!),animMat=material(ORANGE),animatedRenderer=skinned(animated.root,animated.skeleton,full,animMat,'AnimatedMesh');
    const skeletal=animated.root.addComponent(SkeletalAnimation);skeletal.useBakedAnimation=false;
    const clip=this.positionClip('RightBone',new Vec3(0,-8,0),new Vec3(0,8,0),'BonePose');skeletal.addClip(clip);skeletal.defaultClip=clip;
    animated.root.active=true;const state=skeletal.play('BonePose')!;skeletal.pause();

    const manual=rig(bodies[1]!),manualMat=material(CYAN),manualRenderer=skinned(manual.root,manual.skeleton,full,manualMat,'DeformedMesh');manual.root.active=true;

    const batched=rig(bodies[2]!),unitMats=[material(ORANGE),material(CYAN)];
    const unitRenderers=[skinned(batched.root,batched.skeleton,leftMesh,unitMats[0]!,'SourceLeft'),skinned(batched.root,batched.skeleton,rightMesh,unitMats[1]!,'SourceRight')];
    unitRenderers.forEach(r=>r.enabled=false);
    const batchNode=this.child(batched.root,'ActualCookedBatch',0,0,200,48);const batch=batchNode.addComponent(ReplayBatchRenderer);batch.visibility=Layers.Enum.UI_2D;batch.skinningRoot=batched.root;batch.atlasSize=64;batch.batchableTextureNames=['mainTexture'];
    batch.units=unitRenderers.map((r,i)=>{const u=new SkinnedMeshUnit();u.copyFrom=r;u.offset=new Vec2(i*.5,0);u.size=new Vec2(.5,.5);return u;});
    const batchEffect=createReplayBatchEffect();this.assets.push(batchEffect);const batchMat=new Material();batchMat.initialize({effectAsset:batchEffect,defines:{USE_COLOR:true,USE_TEXTURE:true,BATCH_TEXTURE:true}});this.assets.push(batchMat);batch.setSharedMaterial(batchMat,0);
    const batchAnimation=batched.root.addComponent(SkeletalAnimation);batchAnimation.useBakedAnimation=false;batched.root.active=true;
    let batchFailure='';
    const recook=()=>{try{batch.cook();batchFailure='';}catch(error){batchFailure=String(error);console.error('[ReplayRigScene] batch cook failed',error instanceof Error?error.stack:batchFailure);}};
    recook();

    // Runtime authoring classes are registered for asset deserialization, while the
    // controller is a normal public runtime export. Use the public class registry.
    const Graph=js.getClassByName('cc.animation.AnimationGraph') as any;
    const Motion=js.getClassByName('cc.animation.ClipMotion') as any;
    const Condition=js.getClassByName('cc.animation.UnaryCondition') as any;
    if(!Graph||!Motion||!Condition)throw new Error('Animation graph authoring classes absent from native runtime');
    const graph=new Graph();this.assets.push(graph);graph.addVariable('variant',animation.VariableType.BOOLEAN,false);
    const machine=graph.addLayer().stateMachine;
    const motionStates=[new Vec3(-60,-4,0),new Vec3(60,4,0)].map((p,i)=>{const s=machine.addMotion();s.name='Pose'+i;s.motion=new Motion();s.motion.clip=this.positionClip('GraphSprite',p,p,s.name);return s;});
    machine.connect(machine.entryState,motionStates[0]);
    for(const [from,to,truth]of [[0,1,true],[1,0,false]]as const){const t=machine.connect(motionStates[from],motionStates[to]);t.duration=0;t.exitConditionEnabled=false;const c=new Condition();c.operator=truth?Condition.Operator.TRUTHY:Condition.Operator.FALSY;c.operand.variable='variant';t.conditions=[c];}
    const graphRoot=this.child(bodies[3]!,'GraphRoot',0,0,0,0);graphRoot.active=false;
    const graphSprite=this.panel(graphRoot,'GraphSprite',0,0,52,24,ORANGE,pattern);
    const controller=graphRoot.addComponent(animation.AnimationController);controller.graph=graph;graphRoot.active=true;

    // The installed legacy terrain shader uses translation only. A genuine
    // descending height ramp is visible to the existing front-facing camera;
    // rotating/scaling a flat XZ plane cannot establish this baseline.
    const terrainNode=this.child(bodies[4]!,'ActualTerrain',-64,-12,1,1);terrainNode.active=false;terrainNode.setPosition(-64,-12,80);
    const terrain=terrainNode.addComponent(Terrain);terrain.usePBR=false;terrain.lodEnable=false;
    const info=new TerrainInfo();info.tileSize=4;info.blockCount=[1,1];info.weightMapSize=32;info.lightMapSize=32;terrain.build(info);
    const terrainLayers=[ORANGE,CYAN].map(color=>{const l=new TerrainLayer();l.detailMap=this.solid(color);l.tileSize=8;return terrain.addLayer(l);});terrain.getBlock(0,0).setLayer(0,terrainLayers[0]!);terrainNode.active=true;
    const lightNode=this.child(this.node,'TerrainLight',0,0,0,0);const light=lightNode.addComponent(DirectionalLight);light.visibility=Layers.Enum.UI_2D;light.illuminance=65000;
    this.scheduleOnce(()=>{
      const shape=(v:any)=>v?{center:[v.center.x,v.center.y,v.center.z],half:[v.halfExtents.x,v.halfExtents.y,v.halfExtents.z]}:null;
      const model=(r:SkinnedMeshRenderer)=>({enabled:r.model?.enabled,visibility:r.visibility,position:[r.node.worldPosition.x,r.node.worldPosition.y,r.node.worldPosition.z],bounds:shape(r.model?.worldBounds)});
      console.log('[ReplayRigScene] native-diagnostic',JSON.stringify({attributes:full.struct.vertexBundles.map(v=>v.attributes.map(a=>({name:a.name,format:a.format}))),uv:Array.from(full.readAttribute(0,gfx.AttributeName.ATTR_TEX_COORD)??[]),joints:Array.from(full.readAttribute(0,gfx.AttributeName.ATTR_JOINTS)??[]),weights:Array.from(full.readAttribute(0,gfx.AttributeName.ATTR_WEIGHTS)??[]),skeletonValid:animated.skeleton.validate(),bones:animated.skeleton.joints,animated:model(animatedRenderer),manual:model(manualRenderer),terrainVisible:terrain.getBlock(0,0).visible,terrainPosition:[terrainNode.worldPosition.x,terrainNode.worldPosition.y,terrainNode.worldPosition.z],terrainModel:shape((terrain.getBlock(0,0) as any)._renderable?._model?.worldBounds)}));
    },1);

    let variant=false,moved=false,visible=true,baked=false;let mode:'default'|'mask'|'hide'='default';
    const status=this.label(this.node,'',0,-216,930,22,13);
    const apply=(stage:string)=>{
      group.setPosition(moved?28:0,moved?-8:0);group.setScale(moved?.85:1,moved?.85:1,1);
      bodies.forEach((n,i)=>{n.active=visible;privacy[i]!.mode=mode==='hide'?ReplayPrivacyMode.Hide:ReplayPrivacyMode.Mask;privacy[i]!.enabled=mode!=='default';});
      if(skeletal.useBakedAnimation!==baked){skeletal.useBakedAnimation=baked;skeletal.play('BonePose');skeletal.pause();}
      const s=skeletal.getState('BonePose')!;s.time=variant?.9:.1;s.sample();
      for(const m of [animMat,animatedRenderer.getMaterialInstance(0)])m?.setProperty('mainColor',variant?CYAN:ORANGE);
      manual.right.setPosition(0,variant?8:-8,0);manual.left.setPosition(0,variant?-5:5,0);
      for(const m of [manualMat,manualRenderer.getMaterialInstance(0)])m?.setProperty('mainColor',variant?ORANGE:CYAN);
      batched.right.setPosition(0,variant?8:-8,0);batched.left.setPosition(0,variant?-5:5,0);
      unitMats.forEach((m,i)=>{const c=(variant?1-i:i)?CYAN:ORANGE;m.setProperty('mainColor',c);m.setProperty('color',c);});batch.cookMaterials();
      controller.setValue('variant',variant);
      terrain.getBlock(0,0).setLayer(0,terrainLayers[+variant]!);
      // Terrain.importHeightField consumes encoded uint16 heights: zero metres
      // is 32768 and each metre is 128 units in this engine version.
      const hf=new HeightField(33,33);for(let j=0;j<33;j++)for(let i=0;i<33;i++)hf.set(i,j,32768+(32-j)*(variant?.5:.75)*128);terrain.importHeightField(hf,1);
      notes[0]!.string=`${baked?'baked':'CPU'} sampled ${s.time.toFixed(1)}\n2 bones / 8 vertices`;
      notes[1]!.string=`bone.y:${manual.right.position.y}\nactual skinning model`;
      notes[2]!.string=`units:${batch.units.length};sources disabled\n${batchFailure?'native cook failed; see log':'cooked mesh:'+!!batch.mesh}`;
      notes[4]!.string=`1 block / 32x32 tiles\n${variant?'cyan ramp height16':'orange ramp height24'}`;
      status.string=`${stage} | variant:${+variant} visible:${visible} privacy:${mode}`;track('page',stage);
      this.scheduleOnce(()=>{if(this.isValid&&!this.disposed)notes[3]!.string=`graph layers:${controller.layerCount}\nx:${graphSprite.position.x.toFixed(1)} bool:${controller.getValue('variant')}`;},.2);
    };
    const commands:Array<[string,()=>void]>=[
      ['Change five cases',()=>{variant=!variant;apply('changed');}],
      ['CPU / baked animation',()=>{baked=!baked;apply(baked?'baked':'cpu');}],
      ['Recook batch',()=>{recook();apply('recooked');}],
      ['Move + scale',()=>{moved=!moved;apply('transformed');}],
      ['Hide / show',()=>{visible=!visible;apply(visible?'shown':'hidden');}],
      ['Privacy default / mask / hide',()=>{mode=mode==='default'?'mask':mode==='mask'?'hide':'default';apply('privacy-'+mode);}],
      ['Reset',()=>{variant=false;moved=false;visible=true;baked=false;mode='default';apply('reset');}],
      ['Back',()=>{if(!this.disposed){this.disposed=true;exit();}}],
    ];
    commands.forEach(([caption,click],i)=>{const b=this.panel(this.node,'Command'+i,-345+i%4*230,i<4?-245:-295,218,38,PANEL,white);b.addComponent(Button);b.on('click',()=>{if(!this.disposed)click();});this.label(b,caption,0,0,212,34,12);});apply('entered');
  }
  private mesh(only?:number):Mesh {
    const positions:number[]=[],normals:number[]=[],uvs:number[]=[],joints:number[]=[],weights:number[]=[],indices:number[]=[];
    for(let b=0;b<2;b++){if(only!==undefined&&only!==b)continue;const start=positions.length/3,x0=b?10:-90,x1=b?90:-10;positions.push(x0,-12,0,x1,-12,0,x1,12,0,x0,12,0);uvs.push(0,0,1,0,1,1,0,1);for(let i=0;i<4;i++){normals.push(0,0,1);joints.push(b,0,0,0);weights.push(1,0,0,0);}indices.push(start,start+1,start+2,start,start+2,start+3);}
    // Explicit interleaved data makes UVs, joints and weights auditable through
    // native readback. The earlier helper-based baseline failure was not isolated.
    const count=positions.length/3,stride=56,data=new Uint8Array(count*stride+indices.length*2),dv=new DataView(data.buffer);
    for(let v=0;v<count;v++){
      for(let k=0;k<3;k++){dv.setFloat32(v*stride+k*4,positions[v*3+k]!,true);dv.setFloat32(v*stride+12+k*4,normals[v*3+k]!,true);}
      for(let k=0;k<2;k++)dv.setFloat32(v*stride+24+k*4,uvs[v*2+k]!,true);
      for(let k=0;k<4;k++){dv.setUint16(v*stride+32+k*2,joints[v*4+k]!,true);dv.setFloat32(v*stride+40+k*4,weights[v*4+k]!,true);}
    }
    indices.forEach((x,i)=>dv.setUint16(count*stride+i*2,x,true));
    const m=new Mesh();m.reset({struct:{vertexBundles:[{attributes:[new gfx.Attribute(gfx.AttributeName.ATTR_POSITION,gfx.Format.RGB32F),new gfx.Attribute(gfx.AttributeName.ATTR_NORMAL,gfx.Format.RGB32F),new gfx.Attribute(gfx.AttributeName.ATTR_TEX_COORD,gfx.Format.RG32F),new gfx.Attribute(gfx.AttributeName.ATTR_JOINTS,gfx.Format.RGBA16UI),new gfx.Attribute(gfx.AttributeName.ATTR_WEIGHTS,gfx.Format.RGBA32F)],view:{offset:0,length:count*stride,count,stride}}],primitives:[{primitiveMode:gfx.PrimitiveMode.TRIANGLE_LIST,vertexBundelIndices:[0],indexView:{offset:count*stride,length:indices.length*2,count:indices.length,stride:2}}],minPosition:new Vec3(-90,-24,0),maxPosition:new Vec3(90,24,0)},data});
    console.log('[ReplayRigScene] mesh',JSON.stringify(m.struct));this.assets.push(m);return m;
  }
  private positionClip(path:string,a:Vec3,b:Vec3,name:string):AnimationClip {const c=new AnimationClip();c.name=name;c.duration=1;c.sample=30;const t=new animation.VectorTrack();t.componentsCount=3;t.path.toHierarchy(path).toProperty('position');for(let i=0;i<3;i++)t.channels()[i]!.curve.assignSorted([[0,{value:[a.x,a.y,a.z][i]!}],[1,{value:[b.x,b.y,b.z][i]!}]]);c.addTrack(t);this.assets.push(c);return c;}
  private frame(pattern:boolean):SpriteFrame {const im=new ImageAsset({_data:coverageTexturePixels(pattern),width:32,height:32,format:Texture2D.PixelFormat.RGBA8888,_compressed:false});const t=new Texture2D();t.image=im;const f=new SpriteFrame();f.texture=t;f.packable=false;this.assets.push(f,t,im);return f;}
  private solid(c:Color):Texture2D {const pixels=new Uint8Array(32*32*4);for(let i=0;i<pixels.length;i+=4){pixels[i]=c.r;pixels[i+1]=c.g;pixels[i+2]=c.b;pixels[i+3]=255;}const im=new ImageAsset({_data:pixels,width:32,height:32,format:Texture2D.PixelFormat.RGBA8888,_compressed:false});const t=new Texture2D();t.image=im;this.assets.push(t,im);return t;}
  private child(parent:Node,name:string,x:number,y:number,w:number,h:number):Node {const n=new Node(name);n.layer=Layers.Enum.UI_2D;n.addComponent(UITransform).setContentSize(w,h);n.setPosition(x,y);parent.addChild(n);return n;}
  private panel(parent:Node,name:string,x:number,y:number,w:number,h:number,color:Color,frame:SpriteFrame):Node {const n=this.child(parent,name,x,y,w,h);const s=n.addComponent(Sprite);s.sizeMode=Sprite.SizeMode.CUSTOM;s.spriteFrame=frame;s.color=color;return n;}
  private label(parent:Node,text:string,x:number,y:number,w:number,h:number,size:number):Label {const n=this.child(parent,'Label',x,y,w,h);const l=n.addComponent(Label);l.overflow=Label.Overflow.CLAMP;n.getComponent(UITransform)!.setContentSize(w,h);l.string=text;l.fontSize=size;l.lineHeight=20;l.color=new Color(239,244,255);l.horizontalAlign=Label.HorizontalAlign.CENTER;l.verticalAlign=Label.VerticalAlign.CENTER;return l;}
  onDestroy():void {this.disposed=true;this.unscheduleAllCallbacks();this.assets.forEach(x=>x.destroy());}
}
