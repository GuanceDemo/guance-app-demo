import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
const generation=JSON.parse(readFileSync(new URL('../package.json',import.meta.url),'utf8')).creator.version.startsWith('2')?2:3;
const url=code=>'data:text/javascript;base64,'+Buffer.from(code).toString('base64');
let state;
class Vec {constructor(x=0,y=0,z=0){Object.assign(this,{x,y,z});}clone(){return new Vec(this.x,this.y,this.z);}}
class Component {isValid=true;}
class Node {
  constructor(name){this.name=name;this.active=true;this.children=[];this.components=[];this.position=new Vec();}
  get x(){return this.position.x;} get y(){return this.position.y;}
  addChild(node){node.parent=this;this.children.push(node);}
  addComponent(Type){const c=new Type();c.node=this;this.components.push(c);return c;}
  setPosition(x,y,z){this.position=typeof x==='object'?x:new Vec(x,y,z);}setContentSize(width,height){this.size=typeof width==='object'?width:{width,height};}
  getContentSize(){return this.size||{width:720,height:1280};}
  getComponent(Type){return this.components.find(c=>c instanceof Type);}
  getComponentsInChildren(Type){return Type===AudioSource?state.audio:[];}
  removeFromParent(){this.parent.children=this.parent.children.filter(n=>n!==this);this.parent=undefined;}
  destroy(){state.destroy.push(this);}
}
class Camera extends Component {enabled=true;fov=45;}
class Canvas extends Component {designResolution={width:720,height:1280};fitWidth=true;fitHeight=true;}
class UITransform extends Component {setContentSize(){}}
class AudioSource extends Component {
  playing=true;isPlaying=true;node={activeInHierarchy:true};
  pause(){this.playing=this.isPlaying=false;state.paused++;}
  play(){this.playing=this.isPlaying=true;state.played++;}
}
class VideoPlayer extends Component {}
class RenderTexture { reset(size){Object.assign(this,size);} resize(width,height){Object.assign(this,{width,height});} destroy(){this.destroyed=true;} }
class SpriteFrame { destroy(){this.destroyed=true;} }
class Sprite extends Component {} Sprite.SizeMode={CUSTOM:1};
const two={enable:true,enabled:true,gravity:new Vec(0,-10),autoSimulation:true,enabledAccumulator:false};
const three={enable:true,enabled:true,gravity:new Vec(0,-9,0),autoSimulation:true};
const collision={enabled:false};
const engine={RenderTexture,SpriteFrame,Sprite,rendering:{forceResizeAllWindows(){}},Node,Camera,Canvas,Component,UITransform,AudioSource,VideoPlayer,Color:class {},color:()=>({}),size:(width,height)=>({width,height}),
  Director:{EVENT_AFTER_DRAW:'draw'},Layers:{Enum:{UI_2D:1}},ResolutionPolicy:{SHOW_ALL:'show-all',EXACT_FIT:'fill'},Rect:class {constructor(x,y,width,height){Object.assign(this,{x,y,width,height});}},sys:{getSafeAreaRect:()=>state.safe??({x:0,y:0,...state.resolution})},
  PhysicsSystem2D:{instance:two},PhysicsSystem:{instance:three},
  view:{getFrameSize:()=>state.frame,on:(_event,callback)=>state.resize=callback,off:(_event,callback)=>{if(state.resize===callback)state.resize=undefined;},getDesignResolutionSize:()=>({...state.resolution}),getResolutionPolicy:()=>state.policy,
    setDesignResolutionSize:(width,height,policy)=>{state.resolution={width,height};state.policy=policy;}},
  director:{getScene:()=>state.scene,once:(_event,callback)=>state.after.push(callback),getPhysicsManager:()=>two,getPhysics3DManager:()=>three,getCollisionManager:()=>collision},
};
Camera.ProjectionType={ORTHO:1};Camera.ClearFlags={COLOR:1,DEPTH:2,STENCIL:4};
globalThis.__coverageEngine=engine;globalThis.cc=engine;
const bridge=url('const e=globalThis.__coverageEngine;export const {Node,Camera,Canvas,Component,UITransform,AudioSource,VideoPlayer,Color,Director,Layers,ResolutionPolicy,PhysicsSystem2D,PhysicsSystem,view,director,sys,Rect,RenderTexture,SpriteFrame,Sprite,rendering}=e;');
const names=['ReplayBasicScene','ReplayInputScene','ReplayScrollScene','ReplayLayoutScene','ReplayEffectsScene','ReplayMotionScene','ReplayAssetScene','WebViewValidationScene','ReplayRenderScene','ReplayGeometryScene','ReplayRigScene','ReplayEvidenceScene','ReplaySupportScene','ReplayOptionalScene','Replay3DScene','ReplayPostProcessScene','ReplayNativeScene','ReplayVersionDiffScene'];
class FakeScene extends Component {
  async initialize(exit,track){
    state.exit=exit;
    if(typeof track==='function')track('fixed-case','entered');
    if(state.reject)throw new Error('resource missing');
    if(state.pending)await state.pending;
    this.camera=new Node('Perspective').addComponent(Camera);
  }
  onDestroy(){two.enable=two.enabled=false;three.enable=three.enabled=false;two.gravity=new Vec(99,99);}
}
engine.FakeScene=FakeScene;
const scenes=url('const C=globalThis.__coverageEngine.FakeScene;'+names.map(n=>`export const ${n}=C;`).join(''));
let code=ts.transpileModule(readFileSync(new URL('../assets/scripts/coverage/CoverageHost.ts',import.meta.url),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.ES2020}}).outputText;
code=code.replace(/from ['"]cc['"]/g,`from '${bridge}'`).replace(/from ['"]\.\/(?:Replay\w+|WebViewValidationScene)['"]/g,`from '${scenes}'`);
const modelCode=ts.transpileModule(readFileSync(new URL('../assets/scripts/coverage/CoverageLayoutModel.ts',import.meta.url),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.ES2020}}).outputText;
const modelUrl=url(modelCode);const {coverageRegions}=await import(modelUrl);engine.coverageRegions=coverageRegions;
const surface=url(`export class CoverageSurface { constructor(root,kind){this.kind=kind;this.worldCanvas=root;} get scrollOffset(){return 0;} update(){} destroy(){} showGallery(){} resize(viewport,safe){const regions=globalThis.__coverageEngine.coverageRegions(viewport,safe,this.kind==='perspective'?3:7);globalThis.__coverageRegions=regions;return regions;} }`);
code=code.replace("'./CoverageSurface'",JSON.stringify(surface)).replace("'./CoverageLayoutModel'",JSON.stringify(modelUrl));
const safeArea=url('export const safeAreaRect=()=>globalThis.__coverageEngine.sys.getSafeAreaRect();');
code=code.replace("'../SafeArea'",JSON.stringify(safeArea));
const {CoverageHost}=await import(url(code));
function fixture(){
 state={frame:{width:1280,height:720},resolution:{width:720,height:1280},policy:{name:'portrait'},scene:new Node('Scene'),destroy:[],after:[],paused:0,played:0,audio:[new AudioSource()]};
 Object.assign(two,{enable:true,enabled:true,gravity:new Vec(0,-10),autoSimulation:true,enabledAccumulator:false});
 Object.assign(three,{enable:true,enabled:true,gravity:new Vec(0,-9,0),autoSimulation:true});collision.enabled=false;
 const canvas=new Node('AppCanvas');canvas.setPosition(360,640);canvas.addComponent(Canvas);const root=new Node('DemoUI');canvas.addChild(root);const camera=new Node('MainCamera').addComponent(Camera),selected=[],events=[];let exits=0;
 const host=new CoverageHost(root,camera,c=>selected.push(c),()=>exits++,(...args)=>events.push(args));
 return {root,camera,host,selected,events,exits:()=>exits};
}
function flush(){
 for(const node of state.destroy.splice(0))for(const component of node.components)component.onDestroy?.();
 for(const restore of state.after.splice(0))restore();
}

test('coverage pause/resume and disposal restore camera, portrait resolution and global physics',async()=>{
 const f=fixture(),originalPolicy={name:'portrait'};await f.host.open('basic','');
 assert.equal(f.root.active,false);assert.equal(f.camera.enabled,false);assert.deepEqual(state.resolution,{width:1280,height:720});
 if(generation===2){assert.equal(f.selected.at(-1).node.x,f.root.parent.x);assert.equal(f.selected.at(-1).node.y,f.root.parent.y);}
 f.host.pause();assert.equal(two[generation===3?'enable':'enabled'],false);assert.equal(state.paused,1);
 f.host.resume();assert.equal(two[generation===3?'enable':'enabled'],true);assert.equal(state.played,1);
 two.gravity=new Vec(0,-180);three.gravity=new Vec(0,-180);collision.enabled=true;
 f.host.destroy();f.host.destroy();flush();
 assert.equal(f.root.active,true);assert.equal(f.camera.enabled,true);assert.equal(f.selected.at(-1),f.camera);
 assert.deepEqual(state.resolution,{width:720,height:1280});assert.deepEqual(state.policy,originalPolicy);
 assert.equal(two[generation===3?'enable':'enabled'],true);assert.equal(three[generation===3?'enable':'enabled'],true);
 assert.equal(two.gravity.y,-10);assert.equal(three.gravity.y,-9);if(generation===2)assert.equal(collision.enabled,false);
 const count=f.events.length;state.exit();assert.equal(f.exits(),0);assert.equal(f.events.length,count);
});

test('a delayed coverage initialization cannot select a destroyed camera after leaving',async()=>{
 const f=fixture();let complete;state.pending=new Promise(resolve=>complete=resolve);
 const pending=f.host.open(generation===3?'perspective':'native','');
 f.host.destroy();flush();const count=f.selected.length;
 complete();await pending;
 assert.equal(f.selected.length,count);assert.equal(f.selected.at(-1),f.camera);
 assert.equal(f.root.active,true);assert.deepEqual(state.resolution,{width:720,height:1280});
});

test('failed asset initialization can be cleaned up without leaving a hidden demo',async()=>{
 const f=fixture();state.reject=true;
 await assert.rejects(f.host.open('assets',''),/resource missing/);
 f.host.destroy();flush();
 assert.equal(f.root.active,true);assert.equal(f.camera.enabled,true);assert.equal(f.selected.at(-1),f.camera);
 assert.deepEqual(state.resolution,{width:720,height:1280});
});

test('perspective and post-processing cameras retain horizontal framing through portrait and landscape rotation', async () => {
 for (const kind of ['perspective', 'postprocess']) {
  const f=fixture(); await f.host.open(kind, '');
  const camera=f.host.node.getComponent(FakeScene).camera;
  assert.equal(camera.fov,45);
  const output=f.host.postOutput;if(kind==='postprocess'){assert.ok(output);assert.equal(camera.targetTexture,output.texture);}
  state.frame={width:393,height:852}; state.resize();
  const portrait=camera.fov;
  assert.ok(portrait>45 && portrait<180);
  const region=globalThis.__coverageRegions.body;
  const halfWidth=Math.tan(portrait*Math.PI/360)*region.width/region.height;
  assert.ok(camera.rect.x>=0 && camera.rect.y>=0 && camera.rect.width<=1 && camera.rect.height<=1);
  assert.ok(Math.abs(halfWidth-Math.tan(45*Math.PI/360))<1e-10);
  state.frame={width:852,height:393}; state.resize();
  assert.equal(camera.fov,45);
  f.host.destroy();if(output){assert.equal(output.texture.destroyed,true);assert.equal(output.frame.destroyed,true);assert.equal(camera.targetTexture,null);}
  assert.equal(state.resize,undefined); flush();
 }
});

test('late safe-area updates after rotation restore full portrait width without a second resize event', async()=>{
 const f=fixture();await f.host.open('basic','');
 for(let i=0;i<5;i++){
  state.frame={width:852,height:393};state.safe=undefined;state.resize();
  state.frame={width:393,height:852};state.safe={x:90,y:0,width:540,height:1560};state.resize();
  assert.equal(globalThis.__coverageRegions.navigation.width,508);
  // UIKit publishes final safe-area insets after its window-size event.
  state.safe={x:0,y:34,width:720,height:1500};f.host.update();
  assert.equal(globalThis.__coverageRegions.navigation.width,688);
 }
 f.host.destroy();flush();
});
