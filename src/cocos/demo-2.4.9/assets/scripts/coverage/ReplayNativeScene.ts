import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = cc._decorator;
const ORANGE=cc.color(248,164,44),CYAN=cc.color(40,210,220),PANEL=cc.color(27,39,64);
// Creator 2's bundled declarations omit the gfx/Model/Skeleton asset APIs and
// Light properties. Keep that legacy declaration boundary local to the fixture.
const engine=cc as any;

@ccclass('ReplayNativeScene')
export class ReplayNativeScene extends cc.Component {
  private assets:cc.Asset[]=[];
  private disposed=false;
  private rotating:cc.Node[]=[];
  private elapsed=0;
  async initialize(exit:()=>void,track:(id:string,stage:string)=>void):Promise<void> {
    const effect=await new Promise<cc.EffectAsset>((resolve,reject)=>cc.resources.load('ReplayCoveragePhong',cc.EffectAsset,(e,a)=>e?reject(e):resolve(a)));
    if(!this.isValid||this.disposed||!this.node.activeInHierarchy)return;
    const white=this.frame(false);
    const button=(name:string,caption:string,x:number,y:number,w:number,h:number,click:()=>void,parent=this.node)=>{
      const b=this.panel(parent,name,x,y,w,h,PANEL,white);
      b.addComponent(cc.Button).transition=cc.Button.Transition.NONE;
      b.on('click',()=>{if(!this.disposed)click();});
      this.label(b,caption,0,0,w-24,h-12,20);
      return b;
    };
    button('Back','‹ Categories',-350,276,212,56,()=>{this.disposed=true;exit();});
    this.label(this.node,'3D components · Creator 2',110,276,580,48,28);
    const group=this.child(this.node,'Cases',-138,0,600,430);
    const names=['MeshRenderer','Light','ParticleSystem3D','Skeleton Animation','Skinned Mesh Renderer'];
    const bodies:cc.Node[]=[],privacy:ReplayPrivacy[]=[],notes:cc.Label[]=[],rows:cc.Node[]=[];
    let selected=0;
    names.forEach((name,i)=>{
      const row=this.child(group,name+'Case',0,0,600,430);rows.push(row);
      this.label(row,`M0${i+1} / ${name}`,0,176,590,48,24);
      const preview=this.child(row,name+'Preview',0,32,358,200);preview.setScale(1.25);
      for(const [suffix,x,y,w,h]of [['Top',0,100,358,3],['Bottom',0,-100,358,3],['Left',-179,0,3,200],['Right',179,0,3,200]]as Array<[string,number,number,number,number]>)this.panel(preview,name+suffix,x,y,w,h,cc.color(44,202,178),white);
      const body=this.child(preview,name+'Container',0,0,348,192);bodies.push(body);
      const p=body.addComponent(ReplayPrivacy);p.enabled=false;privacy.push(p);
      notes.push(this.label(row,'',0,-134,570,58,19));
    });
    this.label(this.node,'Perspective + rotating solids · green Replay guards',-138,-186,600,40,18);
    const material=(color:cc.Color)=>{
      const m=cc.Material.create(effect);
      m.define('USE_DIFFUSE_TEXTURE',false);m.define('USE_SPECULAR_TEXTURE',false);m.define('USE_EMISSIVE_TEXTURE',false);
      m.define('USE_EMISSIVE',true);m.define('USE_SPECULAR',true);
      // Explicit pass 0 is required by Creator 2.4.9's multi-pass Phong material.
      m.setProperty('diffuseColor',color,0);m.setProperty('specularColor',cc.color(70,70,70),0);
      m.setProperty('emissiveColor',cc.color(24,24,24),0);this.assets.push(m);return m;
    };
    const flat=this.mesh(false),skinned=this.mesh(true);
    const staticNode=this.child(bodies[0]!,'ActualMesh',0,0,190,140);staticNode.is3DNode=true;
    const mesh=staticNode.addComponent(cc.MeshRenderer);mesh.mesh=flat;mesh.enableAutoBatch=false;mesh.setMaterial(0,material(ORANGE));
    const receiverNode=this.child(bodies[1]!,'PhongReceiver',0,0,190,140);receiverNode.is3DNode=true;
    const receiver=receiverNode.addComponent(cc.MeshRenderer);receiver.mesh=flat;receiver.enableAutoBatch=false;receiver.setMaterial(0,material(cc.Color.WHITE));
    const lightNode=this.child(group,'ActualLight',0,0,0,0);lightNode.is3DNode=true;lightNode.setPosition(0,0,180);lightNode.eulerAngles=cc.v3(-30,-35,0);
    const light=lightNode.addComponent(cc.Light) as any;light.type=engine.Light.Type.DIRECTIONAL;light.intensity=1;
    this.rotating.push(staticNode,receiverNode);

    const particleNode=this.child(bodies[2]!,'Actual3DParticles',0,0,1,1);particleNode.is3DNode=true;particleNode.setPosition(0,0,5);particleNode.active=false;
    const particles=particleNode.addComponent(cc.ParticleSystem3D) as cc.ParticleSystem3D&{getParticleCount:()=>number};particles.playOnAwake=false;particles.capacity=32;particles.startLifetime.constant=100;particles.startSpeed.constant=0;particles.gravityModifier.constant=0;particles.startSize.constant=12;particles.rateOverTime.constant=40;particles.shapeModule.enable=true;particles.shapeModule.radius=64;
    const particleMat=cc.Material.createWithBuiltin('3d-particle',1);particleMat.setProperty('mainTexture',white.getTexture());particleMat.setProperty('tintColor',cc.Color.WHITE);this.assets.push(particleMat);particles.setMaterial(0,particleMat);particleNode.active=true;
    const pulse=(color:cc.Color)=>{particles.stop();particles.clear();particles.startColor.color=color;particles.play();this.scheduleOnce(()=>{if(!this.disposed&&this.isValid){particles.pause();notes[2]!.string=`particles:${particles.getParticleCount()}\npaused bounded CPU pulse`;}},.4);};

    const rig=(parent:cc.Node,name:string)=>{
      const root=this.child(parent,name,0,0,200,48);root.is3DNode=true;root.setPosition(0,0,5);
      const left=this.child(root,'LeftBone',0,0,0,0),right=this.child(root,'RightBone',0,0,0,0);left.is3DNode=right.is3DNode=true;
      const identity=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1];
      // Native cc.deserialize accepts packed build data, not raw editor JSON.
      // Hydrate genuine asset instances using their loader fields and onLoad.
      const model=new engine.Model();model.name=name+'Model';model.nodes.push(
        {name:'Rig',path:'',position:[0,0,0],scale:[1,1,1],quat:[0,0,0,1],children:[1,2]},
        {name:'LeftBone',path:'LeftBone',position:[0,0,0],scale:[1,1,1],quat:[0,0,0,1],children:[],bindpose:{0:identity}},
        {name:'RightBone',path:'RightBone',position:[0,0,0],scale:[1,1,1],quat:[0,0,0,1],children:[],bindpose:{0:identity}},
      );model.onLoad();
      const skeleton=new engine.Skeleton();skeleton.name=name+'Skeleton';skeleton._jointIndices=[1,2];skeleton._skinIndex=0;skeleton._model=model;skeleton.onLoad();this.assets.push(skeleton,model);
      const node=this.child(root,'ActualSkinnedMesh',0,0,190,44);node.is3DNode=true;
      const renderer=node.addComponent(cc.SkinnedMeshRenderer);renderer.mesh=skinned;renderer.rootBone=root;renderer.skeleton=skeleton;renderer.setMaterial(0,material(ORANGE));
      this.rotating.push(root);
      return {root,left,right,model,skeleton,renderer};
    };
    const animated=rig(bodies[3]!,'AnimatedRig');
    const animation=animated.root.addComponent(cc.SkeletonAnimation) as cc.SkeletonAnimation&{model:any};animation.model=animated.model;
    const clip=new cc.SkeletonAnimationClip() as cc.SkeletonAnimationClip&{_nativeAsset:ArrayBuffer;_duration:number;description:object};clip.name='BonePose';clip._duration=1;clip.sample=30;clip.description={RightBone:{position:{offset:0,frameCount:2}}};
    clip._nativeAsset=new Float32Array([0,0,-22,-20,1,0,22,20]).buffer;this.assets.push(clip);animation.addClip(clip);animation.defaultClip=clip;
    animated.root.active=true;animation.play('BonePose');animation.pause();
    const manual=rig(bodies[4]!,'ManualRig');manual.root.active=true;

    let variant=false,lightOn=true,moved=false,visible=true,lastVariant:boolean|undefined;
    let mode:'default'|'mask'|'hide'='default';
    this.panel(this.node,'StatusPanel',0,-276,928,64,PANEL,white);
    const status=this.label(this.node,'',0,-276,896,52,18);
    const apply=(stage:string)=>{
      rows.forEach((row,i)=>{row.active=i===selected;});
      group.setPosition(moved?-110:-138,moved?-8:0);group.setScale(moved?.85:1,moved?.85:1,1);
      bodies.forEach((n,i)=>{n.active=visible;privacy[i]!.mode=mode==='hide'?ReplayPrivacyMode.Hide:ReplayPrivacyMode.Mask;privacy[i]!.enabled=mode!=='default';});
      staticNode.setScale(variant?.85:1,variant?1.15:1,1);mesh.getMaterial(0).setProperty('diffuseColor',variant?CYAN:ORANGE,0);
      lightNode.active=visible;light.intensity=lightOn?1:0;light.color=selected===1?(variant?CYAN:ORANGE):cc.Color.WHITE;
      if(lastVariant!==variant){lastVariant=variant;pulse(variant?CYAN:ORANGE);}
      animation.pause();animation.setCurrentTime(variant?.9:.1,'BonePose');animation.sample('BonePose');animated.renderer.getMaterial(0).setProperty('diffuseColor',variant?CYAN:ORANGE,0);
      manual.left.setPosition(0,variant?-20:20,variant?20:-20);manual.right.setPosition(0,variant?20:-20,variant?-20:20);manual.renderer.getMaterial(0).setProperty('diffuseColor',variant?ORANGE:CYAN,0);
      notes[0]!.string=`48 vertices / 24 triangles · rotating solids\nscale:${staticNode.scaleX.toFixed(2)}`;
      notes[1]!.string=`directional intensity:${light.intensity}\n${variant?'cyan':'orange'} / Phong receiver`;
      notes[3]!.string=`2 animated bones / sample:${variant?.9:.1}\nReplay privacy follows the animated mesh`;
      notes[4]!.string=`Weighted mesh / rightBone.y:${manual.right.y}\nReplay privacy follows the animated mesh`;
      status.string=`M0${selected+1} · ${stage} | variant:${+variant} light:${lightOn} visible:${visible} privacy:${mode}`;track('page',stage);
    };
    const commands:Array<[string,()=>void]>=[
      ['Next case  1–5',()=>{selected=(selected+1)%rows.length;apply('case-selected');if(selected===2)pulse(variant?CYAN:ORANGE);}],
      ['Change state',()=>{variant=!variant;apply('changed');}],
      ['Light on / off',()=>{lightOn=!lightOn;apply(lightOn?'light-on':'light-off');}],
      ['Replay particles',()=>{pulse(variant?CYAN:ORANGE);apply('particle-pulse');}],
      ['Move + scale',()=>{moved=!moved;apply('transformed');}],
      ['Hide / show',()=>{visible=!visible;apply(visible?'shown':'hidden');}],
      ['Privacy mode',()=>{mode=mode==='default'?'mask':mode==='mask'?'hide':'default';apply('privacy-'+mode);}],
      ['Reset',()=>{variant=false;lightOn=true;moved=false;visible=true;mode='default';apply('reset');}],
    ];
    const controlPages=[this.child(this.node,'PrimaryControls',0,0,960,440),this.child(this.node,'PrivacyControls',0,0,960,440)];
    commands.forEach(([caption,click],i)=>button('Command'+i,caption,330,170-i%4*80,252,64,click,controlPages[Math.floor(i/4)]!));
    let controls=0;
    controlPages[1]!.active=false;
    button('MoreControls','More controls  1 / 2',330,-180,252,56,()=>{
      controls=1-controls;controlPages.forEach((page,i)=>{page.active=i===controls;});
      more.string=controls?'Basic controls  2 / 2':'More controls  1 / 2';
    });
    const more=this.node.getChildByName('MoreControls')!.children[0]!.getComponent(cc.Label)!;
    apply('entered');
    this.scheduleOnce(()=>console.log('[ReplayNativeScene] diagnostic',JSON.stringify({joints:animated.skeleton.jointPaths,bones:[animated.right.y,manual.right.y],meshSubmeshes:flat.subMeshes.length,skinnedSubmeshes:skinned.subMeshes.length,particleCount:particles.getParticleCount(),lightEnabled:light.enabledInHierarchy})),1);
  }
  private mesh(skin:boolean):cc.Mesh {
    const gfx=engine.gfx,attrs=[{name:gfx.ATTR_POSITION,type:gfx.ATTR_TYPE_FLOAT32,num:3},{name:gfx.ATTR_NORMAL,type:gfx.ATTR_TYPE_FLOAT32,num:3},{name:gfx.ATTR_UV0,type:gfx.ATTR_TYPE_FLOAT32,num:2}];
    if(skin)attrs.push({name:gfx.ATTR_JOINTS,type:gfx.ATTR_TYPE_FLOAT32,num:4},{name:gfx.ATTR_WEIGHTS,type:gfx.ATTR_TYPE_FLOAT32,num:4});
    // Six independently shaded faces per box; genuine volume and depth occlusion.
    const positions:number[]=[],normals:number[]=[],uvs:number[]=[],joints:number[]=[],weights:number[]=[],indices:number[]=[];
    const face=(corners:number[][],normal:number[],bone:number)=>{
      const base=positions.length/3;
      corners.forEach(v=>{positions.push(...v);normals.push(...normal);joints.push(bone,0,0,0);weights.push(1,0,0,0);});
      uvs.push(0,0,1,0,1,1,0,1);indices.push(base,base+1,base+2,base,base+2,base+3);
    };
    for(let b=0;b<2;b++){
      const l=b?10:-90,r=b?90:-10,d=-36,u=36,n=-38,f=38;
      face([[l,d,f],[r,d,f],[r,u,f],[l,u,f]],[0,0,1],b);
      face([[r,d,n],[l,d,n],[l,u,n],[r,u,n]],[0,0,-1],b);
      face([[r,d,f],[r,d,n],[r,u,n],[r,u,f]],[1,0,0],b);
      face([[l,d,n],[l,d,f],[l,u,f],[l,u,n]],[-1,0,0],b);
      face([[l,u,f],[r,u,f],[r,u,n],[l,u,n]],[0,1,0],b);
      face([[l,d,n],[r,d,n],[r,d,f],[l,d,f]],[0,-1,0],b);
    }
    const m=new cc.Mesh();m.init(new gfx.VertexFormat(attrs),positions.length/3,false);
    m.setVertices(gfx.ATTR_POSITION,new Float32Array(positions));m.setVertices(gfx.ATTR_NORMAL,new Float32Array(normals));m.setVertices(gfx.ATTR_UV0,new Float32Array(uvs));if(skin){m.setVertices(gfx.ATTR_JOINTS,new Float32Array(joints));m.setVertices(gfx.ATTR_WEIGHTS,new Float32Array(weights));}m.setIndices(indices);m.setBoundingBox(cc.v3(-100,-64,-60),cc.v3(100,64,60));this.assets.push(m);return m;
  }
  private frame(pattern:boolean):cc.SpriteFrame {const t=new cc.Texture2D();t.initWithData(coverageTexturePixels(pattern),cc.Texture2D.PixelFormat.RGBA8888,32,32);const f=new cc.SpriteFrame(t);this.assets.push(f,t);return f;}
  private child(parent:cc.Node,name:string,x:number,y:number,w:number,h:number):cc.Node {const n=new cc.Node(name);n.setContentSize(w,h);n.setPosition(x,y);parent.addChild(n);return n;}
  private panel(parent:cc.Node,name:string,x:number,y:number,w:number,h:number,color:cc.Color,frame:cc.SpriteFrame):cc.Node {const n=this.child(parent,name,x,y,w,h);n.color=color;const s=n.addComponent(cc.Sprite);s.sizeMode=cc.Sprite.SizeMode.CUSTOM;s.spriteFrame=frame;return n;}
  private label(parent:cc.Node,text:string,x:number,y:number,w:number,h:number,size:number):cc.Label {const n=this.child(parent,'Label',x,y,w,h);const l=n.addComponent(cc.Label);l.overflow=cc.Label.Overflow.CLAMP;n.setContentSize(w,h);l.string=text;l.fontSize=size;l.lineHeight=Math.ceil(size*1.3);n.color=cc.color(239,244,255);l.horizontalAlign=cc.Label.HorizontalAlign.CENTER;l.verticalAlign=cc.Label.VerticalAlign.CENTER;return l;}
  update(dt:number):void {
    this.elapsed+=dt;
    this.rotating.forEach(n=>{if(n.isValid&&n.activeInHierarchy)n.eulerAngles=cc.v3(-18,28+Math.sin(this.elapsed*.7)*42,8);});
  }
  onDestroy():void {this.disposed=true;this.unscheduleAllCallbacks();this.assets.forEach(x=>x.destroy());}
}
