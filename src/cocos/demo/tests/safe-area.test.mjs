import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
const url=source=>'data:text/javascript;base64,'+Buffer.from(source).toString('base64');
let raw='',area,frame,design,scale,ratio=1;
const sys={isNative:true,os:'Android',OS:{ANDROID:'Android'},OS_ANDROID:'Android',getSafeAreaRect:()=>area};
const view={getFrameSize:()=>frame,getDesignResolutionSize:()=>design,getScaleX:()=>scale,getScaleY:()=>scale,getDevicePixelRatio:()=>ratio};
const native={reflection:{callStaticMethod:()=>raw}};
globalThis.__safeAreaTest={sys,view,native};
const bridge=url('export const {sys,view,native}=globalThis.__safeAreaTest;');
const code=ts.transpileModule(readFileSync(new URL('../assets/scripts/SafeArea.ts',import.meta.url),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.ES2020}}).outputText.replace(/from ['"](?:cc|\.\/Engine)['"]/g,`from '${bridge}'`);
const {safeAreaRect}=await import(url(code));
const near=(actual,expected)=>assert.ok(Math.abs(actual-expected)<1e-6,`${actual} != ${expected}`);
function portrait(legacy=false,dpr=1){
 ratio=dpr;frame={width:1080/dpr,height:2424/dpr};design={width:720,height:legacy?1280:1616};scale=1.5;
 area={x:0,y:legacy?-168:0,width:720,height:(2424-173)/1.5};
 raw=JSON.stringify({left:0,top:173/2424,right:0,bottom:63/2424});
}

test('Pixel 10 gesture navigation is excluded even when engine cutout insets report no bottom',()=>{
 for(const legacy of [false,true])for(const dpr of [1,2,2.625,3]){
  portrait(legacy,dpr);const safe=safeAreaRect();
  near(safe.y,42+(legacy?-168:0));near(safe.width,720);near(safe.height,(2424-173-63)/1.5);
 }
});

test('engine and system safe areas intersect without doubling insets; landscape sides stay bounded',()=>{
 portrait();area.y=42;area.height-=42;near(safeAreaRect().y,42);
 frame={width:2424,height:1080};design={width:1616,height:720};scale=1.5;ratio=1;
 area={x:173/1.5,y:0,width:(2424-173)/1.5,height:720};
 raw=JSON.stringify({left:173/2424,top:0,right:0,bottom:63/1080});
 const safe=safeAreaRect();near(safe.x,173/1.5);near(safe.y,42);near(safe.width,(2424-173)/1.5);near(safe.height,678);
});

test('browser, missing bridge data, invalid insets and transient zero frames retain engine safe area',()=>{
 portrait();sys.isNative=false;assert.deepEqual(safeAreaRect(),area);sys.isNative=true;
 for(const value of ['', 'invalid', '{}', '{"left":0,"top":0,"right":0,"bottom":-1}', '{"left":0,"top":0.9,"right":0,"bottom":0.2}']){raw=value;assert.deepEqual(safeAreaRect(),area);}
 portrait();frame.width=0;assert.deepEqual(safeAreaRect(),area);
});
