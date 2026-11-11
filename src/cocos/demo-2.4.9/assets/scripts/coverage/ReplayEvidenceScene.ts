import { ReplayEvidenceContact2 } from './ReplayEvidenceContact2';
const E:any=cc;
const {ccclass}=cc._decorator;
const PAGES=[
 ['Box Collider','Circle Collider','Polygon Collider','Rigid Body','Box'],
 ['Chain','Circle','Polygon','Distance','Motor'],
 ['Mouse','PrismaticJoint','Revolute','Rope','Weld'],
 ['Wheel','AudioSource','Block Input Events','Box 3D','Sphere 3D'],
 ['Constant Force 3D','Rigid Body 3D']
];
const CLASSES:any={'Box Collider':'BoxCollider','Circle Collider':'CircleCollider','Polygon Collider':'PolygonCollider','Rigid Body':'RigidBody','Box':'PhysicsBoxCollider','Chain':'PhysicsChainCollider','Circle':'PhysicsCircleCollider','Polygon':'PhysicsPolygonCollider','Distance':'DistanceJoint','Motor':'MotorJoint','Mouse':'MouseJoint','PrismaticJoint':'PrismaticJoint','Revolute':'RevoluteJoint','Rope':'RopeJoint','Weld':'WeldJoint','Wheel':'WheelJoint','Box 3D':'BoxCollider3D','Sphere 3D':'SphereCollider3D','Constant Force 3D':'ConstantForce','Rigid Body 3D':'RigidBody3D'};
@ccclass('ReplayEvidenceScene2')
export class ReplayEvidenceScene extends cc.Component {
 private rows:any[]=[];private assets:any[]=[];private board:any;private title:any;private white:any;private page=0;private running=false;private elapsed=0;private tick=0;
 initialize(exit:()=>void):void{
  const t=new cc.Texture2D();t.initWithData(new Uint8Array(16).fill(255),cc.Texture2D.PixelFormat.RGBA8888,2,2);this.white=new cc.SpriteFrame(t);this.assets.push(t,this.white);
  this.panel(this.node,'Background',0,0,960,640,[12,18,34]);this.title=this.label(this.node,'',0,282,940,38,23);this.label(this.node,'Actual components / Box2D + Cannon / local evidence / privacy not assessed',0,244,930,28,15);
  this.button('Run physics / play',-345,-250,()=>this.run());this.button('Pause audio / toggle blocker',-115,-250,()=>this.secondary());this.button('Next five',115,-250,()=>{this.page=(this.page+1)%PAGES.length;this.load();});this.button('Exit',345,-250,exit);this.button('Stop audio / reset',0,-300,()=>{const a=this.rows.find(r=>r.audio);if(a){a.audio.stop();this.report('audio-stopped');}else this.load();});cc.director.getPhysicsManager().enabled=true;cc.director.getPhysicsManager().enabled=false;this.load();
 }
 private child(parent:any,name:string,x:number,y:number,w=0,h=0):any{const n=new cc.Node(name);n.setContentSize(w,h);n.setPosition(x,y);parent.addChild(n);return n;}
 private panel(parent:any,name:string,x:number,y:number,w:number,h:number,c:number[]):any{const n=this.child(parent,name,x,y,w,h);const s=n.addComponent(cc.Sprite);s.sizeMode=cc.Sprite.SizeMode.CUSTOM;s.spriteFrame=this.white;n.color=cc.color(c[0],c[1],c[2]);return n;}
 private label(parent:any,text:string,x:number,y:number,w:number,h:number,size=14):any{const n=this.child(parent,'Label',x,y,w,h);const l=n.addComponent(cc.Label);l.string=text;l.fontSize=size;l.lineHeight=size+3;l.overflow=cc.Label.Overflow.CLAMP;l.horizontalAlign=cc.Label.HorizontalAlign.CENTER;l.verticalAlign=cc.Label.VerticalAlign.CENTER;n.color=cc.Color.WHITE;n.setContentSize(w,h);return l;}
 private button(text:string,x:number,y:number,fn:()=>void):void{const n=this.panel(this.node,text,x,y,220,38,[36,64,103]);n.addComponent(cc.Button);n.on('click',fn);this.label(n,text,0,0,216,36,13);}
 private stopPhysics():void{this.running=false;this.rows.forEach(r=>{if(r.force?.isValid)r.force.enabled=false;});cc.director.getPhysicsManager().enabled=false;const m=E.director.getPhysics3DManager();if(m)m.enabled=false;}
 private load():void{
  this.unscheduleAllCallbacks();this.rows.forEach(r=>r.audio?.isValid&&r.audio.stop());this.stopPhysics();if(this.board){this.board.active=false;this.board.destroy();}this.rows=[];this.tick=0;this.board=this.child(this.node,'EvidencePage'+this.page,0,0,960,440);this.title.string='Full component coverage / Creator '+cc.ENGINE_VERSION+' / page '+(this.page+1)+' of '+PAGES.length;
  PAGES[this.page]!.forEach((name,i)=>{const root=this.child(this.board,name,0,185-i*83,920,78);this.panel(root,'RowBackground',0,0,920,76,[23,34,54]);this.label(root,name,-328,0,250,66,16);const r:any={name,root,events:0,note:this.label(root,'initial',335,0,240,72,12)};this.rows.push(r);try{if(name.endsWith('3D'))this.three(r);else if(name.indexOf(' Collider')>=0)this.collision(r);else if(name==='AudioSource'||name==='Block Input Events')this.support(r);else this.two(r);}catch(e){r.error=String(e);}});this.scheduleOnce(()=>this.report('initial'),.3);
 }
 private observer(n:any,r:any):void{n.addComponent(ReplayEvidenceContact2).notify=()=>{r.events++;n.color=cc.color(30,215,155);};}
 private collision(r:any):void{
  cc.director.getCollisionManager().enabled=true;const n=this.panel(r.root,'ActualCollisionActor',-100,0,24,24,[255,180,30]);const fixed=this.panel(r.root,'ActualCollisionObstacle',0,0,40,44,[45,100,200]);n.zIndex=1;const c=n.addComponent(E[CLASSES[r.name]]);const target=fixed.addComponent(cc.BoxCollider);target.size=cc.size(40,44);if(r.name==='Box Collider')c.size=cc.size(24,24);if(r.name==='Circle Collider')c.radius=12;if(r.name==='Polygon Collider')c.points=[cc.v2(-12,-12),cc.v2(12,-12),cc.v2(0,12)];this.observer(n,r);r.actor=n;r.component=c;r.manual=true;
 }
 private two(r:any):void{
  const pm=cc.director.getPhysicsManager();pm.enabled=false;pm.gravity=cc.v2(0,-180);pm.enabledAccumulator=true;
  const floor=this.panel(r.root,'ActualBox2DFloor',0,-28,300,6,[44,190,160]);floor.active=false;const fixed=floor.addComponent(cc.RigidBody);fixed.type=cc.RigidBodyType.Static;let fc:any;
  if(r.name==='Chain'){fc=floor.addComponent(cc.PhysicsChainCollider);fc.points=[cc.v2(-150,0),cc.v2(150,0)];fc.loop=false;}else{fc=floor.addComponent(cc.PhysicsBoxCollider);fc.size=cc.size(300,6);}floor.active=true;
  const n=this.panel(r.root,'ActualBox2DActor',-100,21,24,24,[255,180,30]);n.active=false;const b=n.addComponent(cc.RigidBody);b.type=cc.RigidBodyType.Dynamic;b.enabledContactListener=true;b.linearDamping=.2;
  const type=r.name==='Box'||r.name==='Circle'||r.name==='Polygon'?CLASSES[r.name]:'PhysicsBoxCollider';const c=n.addComponent(E[type]);if(type==='PhysicsBoxCollider')c.size=cc.size(24,24);if(type==='PhysicsCircleCollider')c.radius=12;if(type==='PhysicsPolygonCollider')c.points=[cc.v2(-12,-12),cc.v2(12,-12),cc.v2(0,12)];this.observer(n,r);r.actor=n;r.body=b;r.component=r.name==='Rigid Body'?b:r.name==='Chain'?fc:c;
  if(CLASSES[r.name].indexOf('Joint')>=0){n.active=true;const j=(r.name==='Mouse'?floor:n).addComponent(E[CLASSES[r.name]]);j.connectedBody=r.name==='Mouse'?b:fixed;j.collideConnected=true;j.anchor=cc.v2(0,0);j.connectedAnchor=cc.v2(-65,45);if('distance'in j)j.distance=38;if('maxLength'in j)j.maxLength=38;if('maxForce'in j)j.maxForce=1000;if('maxTorque'in j)j.maxTorque=1000;if(r.name==='Mouse'){j.capture=false;b.gravityScale=0;b.fixedRotation=true;}r.component=j;r.joint=j;if(r.name!=='Mouse')j.apply();}
  n.active=true;
 }
 private three(r:any):void{
  const pm=E.director.getPhysics3DManager();if(!pm)throw Error('No3D physics manager');pm.enabled=false;pm.gravity=cc.v3(0,-180,0);
  const floor=this.panel(r.root,'ActualCannonFloor',0,-28,300,5,[44,190,160]);floor.is3DNode=true;floor.setPosition(floor.x,floor.y,5);floor.active=true;const fb=floor.addComponent(E.RigidBody3D);fb.mass=0;floor.addComponent(E.BoxCollider3D).size=cc.v3(300,5,22);floor.active=true;
  const n=this.panel(r.root,'ActualCannonActor',-100,20,22,22,[255,180,30]);n.is3DNode=true;n.setPosition(n.x,n.y,5);n.active=true;const b=n.addComponent(E.RigidBody3D);b.mass=1;b.linearDamping=.2;b.useGravity=true;const c=n.addComponent(r.name==='Sphere 3D'?E.SphereCollider3D:E.BoxCollider3D);if(r.name==='Sphere 3D')c.radius=11;else c.size=cc.v3(22,22,22);r.actor=n;r.body=b;r.component=r.name==='Rigid Body 3D'?b:c;r.is3d=true;
  if(r.name==='Constant Force 3D'){r.component=n.addComponent(E.ConstantForce);r.component.force=cc.v3(25,0,0);r.force=r.component;r.force.enabled=false;}n.active=true;
 }
 private support(r:any):void{
  if(r.name==='AudioSource'){const n=this.child(r.root,'ActualAudioSource',0,0);const a=n.addComponent(cc.AudioSource);a.loop=true;a.volume=.5;a.playOnLoad=false;r.audio=a;r.component=a;cc.resources.load('replay-media/tone',cc.AudioClip,(e:any,c:any)=>{if(!this.isValid||!a.isValid||this.rows.indexOf(r)<0)return;if(e){r.error=String(e);this.report('audio-load-error');return;}a.clip=c;r.loaded=true;this.report('audio-ready');});this.label(r.root,'440 Hz / 2 s local WAV',0,0,290,50,16);return;}
  const under=this.panel(r.root,'UnderlyingReceiver',0,0,280,54,[43,101,195]);under.on(cc.Node.EventType.TOUCH_END,()=>{r.events++;this.report('underlying-click');});const over=this.panel(r.root,'ActualBlockingOverlay',0,0,230,42,[180,80,50]);r.component=over.addComponent(cc.BlockInputEvents);this.label(over,'Tap here / BlockInputEvents',0,0,225,40,13);
 }
 private run():void{
  this.tick++;this.elapsed=0;this.running=true;for(const r of this.rows){try{if(r.body){if(r.is3d)r.body.setLinearVelocity(cc.v3(75,0,0));else if(r.name==='Mouse'){r.joint.target=r.actor.convertToWorldSpaceAR(cc.v2(0,0));r.joint.apply();r.joint.target=r.actor.convertToWorldSpaceAR(cc.v2(70,0));}else r.body.linearVelocity=cc.v2(75,0);}if(r.force)r.force.enabled=true;if(r.audio)r.audio.play();}catch(e){r.error=String(e);}}
  cc.director.getPhysicsManager().enabled=true;const pm=E.director.getPhysics3DManager();if(pm)pm.enabled=true;this.report('running');this.scheduleOnce(()=>{this.stopPhysics();this.report('after-1.2s');},1.2);
 }
 update(dt:number):void{if(!this.running)return;this.elapsed+=dt;this.rows.forEach(r=>{if(r.manual)r.actor.x=-100+Math.min(100,this.elapsed*150);});}
 private secondary():void{this.rows.forEach(r=>{if(r.audio)r.audio.pause();if(r.name==='Block Input Events')r.component.enabled=!r.component.enabled;});this.report('secondary');}
 private report(stage:string):void{const records=this.rows.map(r=>{const p=r.actor?.position;const rec={name:r.name,componentClass:r.component?cc.js.getClassName(r.component):null,enabled:r.component?.enabledInHierarchy,position:p?{x:p.x,y:p.y,z:p.z}:null,events:r.events,backendObject:(r.joint?._joint||r.component?._shape||r.body?._body||r.body?._b2Body)?.constructor?.name||null,audio:r.audio?{loaded:!!r.loaded,state:r.audio.audio?.getState(),playing:r.audio.isPlaying,currentTime:r.audio.getCurrentTime(),duration:r.audio.getDuration()}:null,error:r.error||null};r.note.string=(r.error?'TARGET UNESTABLISHED\n':stage+' / '+rec.componentClass+'\n')+(p?'x='+p.x.toFixed(1)+' y='+p.y.toFixed(1)+' / ':'')+'events='+r.events+(r.audio?'\nAudio state='+r.audio.audio?.getState():'')+(r.name==='Block Input Events'?'\nblock='+r.component.enabled:'');return rec;});console.log('[ReplayEvidenceScene2]',JSON.stringify({engine:cc.ENGINE_VERSION,page:this.page,stage,tick:this.tick,hostTime:Date.now(),physics2d:'Box2D',physics3d:(window as any).CC_PHYSICS_CANNON?'Cannon':'Builtin',records}));}
 onDestroy():void{this.stopPhysics();this.rows.forEach(r=>r.audio?.isValid&&r.audio.stop());this.unscheduleAllCallbacks();this.assets.forEach(a=>a.destroy());}
}
