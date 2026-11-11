import { _decorator, Component } from 'cc';
import * as engine from 'cc';
const E:any=engine;
const {ccclass}= _decorator;
const PAGES=[
 ['BoxCollider2D','CircleCollider2D','PolygonCollider2D','RigidBody2D','DistanceJoint2D'],
 ['FixedJoint2D','HingeJoint2D','MouseJoint2D','RelativeJoint2D','SliderJoint2D'],
 ['SpringJoint2D','WheelJoint2D','AudioSource','BlockInputEvents','UIStaticBatch'],
 ['BoxCollider','CapsuleCollider','ConeCollider','CylinderCollider','MeshCollider'],
 ['PlaneCollider','SimplexCollider','SphereCollider','TerrainCollider','ConstantForce'],
 ['RigidBody','ConfigurableConstraint(beta)','FixedConstraint(beta)','HingeConstraint(beta)','PointToPointConstraint(beta)'],
 ['BoxCharacterController','CapsuleCharacterController','LightProbeGroup']
];
@ccclass('ReplayEvidenceScene')
export class ReplayEvidenceScene extends Component {
 private assets:any[]=[];private rows:any[]=[];private board:any;private title:any;private page=0;private tick=0;private white:any;private exit?:()=>void;
 async initialize(exit:()=>void):Promise<void>{
  const canvas:any=this.node.parent;const camera=canvas.getComponent(E.Canvas).cameraComponent;canvas.setPosition(480,320,0);camera.node.setPosition(480,320,1000);this.exit=()=>{canvas.setPosition(0,0,0);camera.node.setPosition(0,0,1000);exit();};const im=new E.ImageAsset({_data:new Uint8Array(16).fill(255),width:2,height:2,format:E.Texture2D.PixelFormat.RGBA8888,_compressed:false});const t=new E.Texture2D();t.image=im;this.white=new E.SpriteFrame();this.white.texture=t;this.white.packable=false;this.assets.push(im,t,this.white);
  this.panel(this.node,'Background',0,0,960,640,[12,18,34]);this.title=this.label(this.node,'',0,282,940,38,23);
  this.label(this.node,'Actual engine components / live interaction and Replay comparison',0,244,930,28,15);
  this.button('Run physics / play',-345,-250,()=>this.run());this.button('Pause audio / toggle blocker',-115,-250,()=>this.secondary());this.button('Next five',115,-250,()=>{this.page=(this.page+1)%PAGES.length;this.load();});this.button('Exit',345,-250,this.exit!);
  this.button('Stop audio / reset',0,-300,()=>{const audio=this.rows.find(r=>r.audio);if(audio){audio.audio.stop();this.report('audio-stopped');}else this.load();});
  this.load();
 }
 private child(parent:any,name:string,x:number,y:number,w=0,h=0):any{const n=new E.Node(name);n.layer=E.Layers.Enum.UI_2D;n.addComponent(E.UITransform).setContentSize(w,h);n.setPosition(x,y,0);parent.addChild(n);return n;}
 private panel(parent:any,name:string,x:number,y:number,w:number,h:number,c:number[]):any{const n=this.child(parent,name,x,y,w,h);const s=n.addComponent(E.Sprite);s.sizeMode=E.Sprite.SizeMode.CUSTOM;s.spriteFrame=this.white;s.color=new E.Color(...c);return n;}
 private label(parent:any,text:string,x:number,y:number,w:number,h:number,size=14):any{const n=this.child(parent,'Label',x,y,w,h);const l=n.addComponent(E.Label);l.string=text;l.fontSize=size;l.lineHeight=size+3;l.overflow=E.Label.Overflow.CLAMP;l.color=new E.Color(239,244,255);l.horizontalAlign=1;l.verticalAlign=1;return l;}
 private button(text:string,x:number,y:number,fn:()=>void):void{const n=this.panel(this.node,text,x,y,220,38,[36,64,103]);n.addComponent(E.Button);n.on('click',fn);this.label(n,text,0,0,216,36,13);}
 private load():void{
  this.unscheduleAllCallbacks();this.rows.forEach(r=>r.audio?.isValid&&r.audio.stop());this.stopPhysics();if(this.board){this.board.active=false;this.board.destroy();}this.rows=[];this.tick=0;
  this.board=this.child(this.node,'EvidencePage'+this.page,0,0,960,440);this.title.string='Full component coverage / Creator 3.8.8 / page '+(this.page+1)+' of '+PAGES.length;
  for(const [i,name]of PAGES[this.page]!.entries()){
   const y=185-i*83;const root=this.child(this.board,name,0,y,920,78);this.panel(root,'RowBackground',0,0,920,76,[23,34,54]);this.label(root,name,-328,0,250,66,16);
   const r:any={name,root,actor:null,component:null,note:this.label(root,'initial',335,0,240,72,12),events:0};this.rows.push(r);
   try{if(name.endsWith('2D'))this.physics2d(r);else if(['AudioSource','BlockInputEvents','UIStaticBatch','LightProbeGroup'].includes(name))this.support(r);else this.physics3d(r);}catch(e){r.error=String(e);r.note.string='TARGET NOT ESTABLISHED\n'+r.error;}
  }
  this.scheduleOnce(()=>this.report('initial'),.3);
 }
 private stopPhysics():void{this.rows.forEach(r=>{if(r.force?.isValid)r.force.enabled=false;});if(E.PhysicsSystem2D.instance)E.PhysicsSystem2D.instance.enable=false;if(E.PhysicsSystem.instance)E.PhysicsSystem.instance.enable=false;}
 private physics2d(r:any):void{
  const sys=E.PhysicsSystem2D.instance;sys.gravity=new E.Vec2(0,-180);sys.enable=false;sys.autoSimulation=true;
  const floor=this.panel(r.root,'Real2DFloor',0,-28,300,6,[44,190,160]);floor.active=false;const fixed=floor.addComponent(E.RigidBody2D);fixed.type=0;const fc=floor.addComponent(E.BoxCollider2D);fc.size=new E.Size(300,6);floor.active=true;
  const n=this.panel(r.root,'Actual2DActor',-100,21,24,24,[255,180,30]);n.active=false;const body=n.addComponent(E.RigidBody2D);body.type=2;body.enabledContactListener=true;body.linearDamping=.2;if(r.name==='MouseJoint2D'){body.gravityScale=0;body.fixedRotation=true;}r.body=body;r.actor=n;
  const colliderName=r.name.includes('Collider')?r.name:'BoxCollider2D';const col=n.addComponent(E[colliderName]);if(colliderName==='BoxCollider2D')col.size=new E.Size(24,24);if(colliderName==='CircleCollider2D')col.radius=12;if(colliderName==='PolygonCollider2D')col.points=[new E.Vec2(-12,-12),new E.Vec2(12,-12),new E.Vec2(0,12)];
  col.on(E.Contact2DType.BEGIN_CONTACT,()=>{r.events++;});r.component=col;
  if(r.name.includes('Joint')){const j=(r.name==='MouseJoint2D'?floor:n).addComponent(E[r.name]);j.connectedBody=r.name==='MouseJoint2D'?null:fixed;j.collideConnected=true;if('autoCalcDistance'in j)j.autoCalcDistance=false;j.anchor=new E.Vec2(0,0);j.connectedAnchor=new E.Vec2(-65,45);if('distance'in j)j.distance=38;if('maxLength'in j)j.maxLength=38;if('maxForce'in j)j.maxForce=1000;if('maxTorque'in j)j.maxTorque=1000;r.component=j;r.joint=j;}
  if(r.name==='RigidBody2D')r.component=body;n.active=true;
 }
 private mesh(parent:any,name:string,x:number,y:number,color:number[]):any{
  const n=this.child(parent,name,x,y);n.active=false;const renderer=n.addComponent(E.MeshRenderer);renderer.visibility=E.Layers.Enum.UI_2D;
  const mesh=E.utils.createMesh(E.primitives.box({width:name==='Real3DFloor'?300:22,height:name==='Real3DFloor'?5:22,length:22}));const mat=new E.Material();mat.initialize({effectName:'builtin-unlit'});mat.setProperty('mainColor',new E.Color(...color));renderer.mesh=mesh;renderer.setSharedMaterial(mat,0);n.getComponent(E.UITransform).setContentSize(22,22);n.addComponent(E.UIMeshRenderer);this.assets.push(mesh,mat);return n;
 }
 private physics3d(r:any):void{
  const sys=E.PhysicsSystem.instance;sys.enable=false;sys.autoSimulation=true;sys.gravity=new E.Vec3(0,-180,0);
  const floor=this.mesh(r.root,'Real3DFloor',0,-29,[44,190,160]);const fixed=floor.addComponent(E.RigidBody);fixed.type=2;const fc=floor.addComponent(E.BoxCollider);fc.size=new E.Vec3(300,5,22);floor.active=true;const group=1<<this.rows.indexOf(r);fixed.setGroup(group);fixed.setMask(group);
  const n=this.mesh(r.root,'Actual3DActor',-100,20,[250,178,30]);r.actor=n;
  const clean=r.name.replace('(beta)','');
  if(clean.includes('CharacterController')){const control=n.addComponent(E[clean]);r.component=control;r.controller=control;if('halfHeight'in control){control.halfHeight=10;control.halfSideExtent=10;control.halfForwardExtent=10;}else{control.height=20;control.radius=10;}n.active=true;return;}
  const b=n.addComponent(E.RigidBody);b.type=1;b.mass=1;b.linearDamping=.2;r.body=b;
  let name=clean.includes('Collider')?clean:'BoxCollider';
  if(name==='TerrainCollider'){
   n.getComponent(E.MeshRenderer).enabled=false;b.type=2;
   const terrain=n.addComponent(E.Terrain);const info=new E.TerrainInfo();info.tileSize=1;info.blockCount=[1,1];info.weightMapSize=32;info.lightMapSize=32;terrain.build(info);const layer=new E.TerrainLayer();layer.detailMap=this.white.texture;terrain.getBlock(0,0).setLayer(0,terrain.addLayer(layer));n.setPosition(-112,-25,-16);fc.enabled=false;
   const c=n.addComponent(E.TerrainCollider);const terrainAsset=terrain.exportAsset();c.terrain=terrainAsset;this.assets.push(terrainAsset);r.component=c;r.terrain=terrain;
   const ball=this.mesh(r.root,'TerrainDropProbe',-88,29,[250,178,30]);r.actor=ball;r.body=ball.addComponent(E.RigidBody);r.body.type=1;ball.addComponent(E.SphereCollider).radius=10;ball.active=true;r.body.setGroup(group);r.body.setMask(group);
  }else{
   const c=n.addComponent(E[name]);r.component=c;if(name==='BoxCollider')c.size=new E.Vec3(22,22,22);if('radius'in c)c.radius=11;if('height'in c)c.height=22;if(name==='MeshCollider'){c.mesh=n.getComponent(E.MeshRenderer).mesh;c.convex=true;}if(name==='PlaneCollider'){b.type=2;c.normal=new E.Vec3(0,1,0);n.setPosition(0,-28,0);n.getComponent(E.MeshRenderer).enabled=false;fc.enabled=false;const ball=this.mesh(r.root,'PlaneDropProbe',-100,20,[250,178,30]);r.actor=ball;r.body=ball.addComponent(E.RigidBody);r.body.type=1;ball.addComponent(E.SphereCollider).radius=11;ball.active=true;r.body.setGroup(group);r.body.setMask(group);}
   if(name==='SimplexCollider') {c.shapeType=3;c.vertex0=new E.Vec3(-11,-11,0);c.vertex1=new E.Vec3(11,-11,0);c.vertex2=new E.Vec3(0,11,0);c.vertex3=new E.Vec3(0,0,15);}
   c.on('onCollisionEnter',()=>r.events++);
  }
  if(clean.includes('Constraint')){n.active=true;const j=n.addComponent(E[clean]);j.connectedBody=fixed;if('pivotA'in j)j.pivotA=new E.Vec3(0,0,0);if('pivotB'in j)j.pivotB=new E.Vec3(-65,40,0);r.component=j;r.joint=j;}
  if(clean==='ConstantForce'){r.component=n.addComponent(E.ConstantForce);r.component.force=new E.Vec3(25,0,0);r.force=r.component;r.force.enabled=false;}
  if(clean==='RigidBody')r.component=b;n.active=true;b.setGroup(group);b.setMask(group);
 }
 private support(r:any):void{
  if(r.name==='AudioSource'){
   const n=this.child(r.root,'ActualAudioSource',0,0);const a=n.addComponent(E.AudioSource);r.audio=a;r.component=a;a.loop=true;a.volume=.5;
   E.resources.load('replay-media/tone',E.AudioClip,(e:any,c:any)=>{if(!this.isValid||!a.isValid||this.rows.indexOf(r)<0)return;if(e){r.error=String(e);this.report('audio-load-error');return;}a.clip=c;r.loaded=true;this.report('audio-ready');});
   this.label(r.root,'440 Hz / 2 s local WAV',0,0,290,50,16);return;
  }
  if(r.name==='BlockInputEvents'){
   const under=this.panel(r.root,'UnderlyingReceiver',0,0,280,54,[43,101,195]);under.on(E.Node.EventType.TOUCH_END,()=>{r.events++;this.report('underlying-click');});
   const overlay=this.panel(r.root,'ActualBlockingOverlay',0,0,230,42,[180,80,50]);r.component=overlay.addComponent(E.BlockInputEvents);this.label(overlay,'Tap here / BlockInputEvents',0,0,225,40,13);return;
  }
  if(r.name==='UIStaticBatch'){
   const n=this.child(r.root,'ActualStaticBatch',0,0,300,54);r.component=n.addComponent(E.UIStaticBatch);r.actor=this.panel(n,'BatchedSprite',-60,0,100,35,[250,178,30]);this.label(n,'Batched child',70,0,140,40,16);return;
  }
  const n=this.child(r.root,'ActualLightProbeGroup',0,0);r.component=n.addComponent(E.LightProbeGroup);r.component.probes=[new E.Vec3(-1,-1,-1),new E.Vec3(1,-1,-1),new E.Vec3(-1,1,-1),new E.Vec3(1,1,-1),new E.Vec3(-1,-1,1),new E.Vec3(1,-1,1),new E.Vec3(-1,1,1),new E.Vec3(1,1,1)];r.error='Runtime probe component exists; baked SH lighting data unavailable. No target lighting effect.';this.label(r.root,'No baked lighting data',0,0,290,50,15);
 }
 private run():void{
  this.tick++;for(const r of this.rows){try{if(r.force)r.force.enabled=true;if(r.body){if(r.name==='MouseJoint2D'){this.scheduleOnce(()=>{r.joint.connectedBody=r.body;r.joint.apply();r.joint.target=new E.Vec2(70,0);},.05);}else if(r.name==='TerrainCollider')r.body.setLinearVelocity(new E.Vec3(0,0,0));else if(r.name.endsWith('2D'))r.body.linearVelocity=new E.Vec2(2.2,0);else r.body.setLinearVelocity(new E.Vec3(75,0,0));}if(r.controller)r.controller.move(new E.Vec3(70,0,0));if(r.audio)r.audio.play();if(r.name==='UIStaticBatch')r.actor.getComponent(E.Sprite).color=new E.Color(30,200,220);}catch(e){r.error=String(e);}}
  if(E.PhysicsSystem2D.instance)E.PhysicsSystem2D.instance.enable=true;if(E.PhysicsSystem.instance)E.PhysicsSystem.instance.enable=true;this.report('running');
  this.scheduleOnce(()=>{this.stopPhysics();this.report('after-1.2s');},1.2);
 }
 update():void{for(const r of this.rows){if(r.name==='MouseJoint2D'&&r.joint?.impl?.impl){r.activeJointFrames=(r.activeJointFrames||0)+1;console.log('[ReplayMouseJoint]',JSON.stringify({activeFrames:r.activeJointFrames,target:r.joint.target,position:r.actor.position,time:Date.now()}));}}}
 private secondary():void{for(const r of this.rows){if(r.audio)r.audio.pause();if(r.name==='BlockInputEvents')r.component.enabled=!r.component.enabled;}this.report('secondary');}
 private report(stage:string):void{
  const records=this.rows.map(r=>{const pos=r.actor?.position;let impl:any;try{impl=r.component?.impl||r.component?._shape||r.component?.constraint||r.component?.body||r.controller?._cct;}catch(e){}
   const rec={name:r.name,componentClass:r.component?E.js.getClassName(r.component):null,enabled:r.component?.enabledInHierarchy,position:pos?{x:pos.x,y:pos.y,z:pos.z}:null,events:r.events,activeJointFrames:r.activeJointFrames||0,backendObject:impl?.constructor?.name||null,audio:r.audio?{loaded:!!r.loaded,state:r.audio.state,playing:r.audio.playing,currentTime:r.audio.currentTime,duration:r.audio.duration}:null,error:r.error||null};
   r.note.string=(r.error?'TARGET UNESTABLISHED\n':stage+' / '+rec.componentClass+'\n')+(pos?'x='+pos.x.toFixed(1)+' y='+pos.y.toFixed(1)+' / ':'')+'events='+r.events+(r.audio?'\nAudio state='+r.audio.state:'')+(r.name==='BlockInputEvents'?'\nblock='+r.component.enabled:'');return rec;});
  console.log('[ReplayEvidenceScene]',JSON.stringify({engine:'3.8.8',page:this.page,stage,tick:this.tick,hostTime:Date.now(),physics3d:E.PhysicsSystem.PHYSICS_BULLET?'bullet':'configured-bullet',physics2d:'box2d',records}));
 }
 onDestroy():void{this.stopPhysics();this.rows.forEach(r=>r.audio?.isValid&&r.audio.stop());this.unscheduleAllCallbacks();this.assets.forEach(a=>a.destroy());}
}
