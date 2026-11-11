import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
const source=ts.transpileModule(readFileSync(new URL('../assets/scripts/coverage/CoverageLayoutModel.ts',import.meta.url),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.ES2020}}).outputText;
const {coverageViewport,coverageRegions,commandAreas}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
function contains(a,b){return b.x-b.width/2>=a.x-a.width/2-.001&&b.x+b.width/2<=a.x+a.width/2+.001&&b.y-b.height/2>=a.y-a.height/2-.001&&b.y+b.height/2<=a.y+a.height/2+.001;}
test('phone and tablet viewports fill either orientation with a uniform pixel scale',()=>{
 for(const [width,height]of [[393,852],[852,393],[390,700],[700,390],[768,1024],[1024,768]]){
  const viewport=coverageViewport(width,height);assert.ok(Math.abs(viewport.width/width-viewport.height/height)<1e-10);
  assert.equal(Math.min(viewport.width,viewport.height),720);assert.equal(viewport.portrait,height>=width);
 }
});
test('portrait commands occupy a lower dock, landscape commands a right rail, with a fixed safe bottom navigation',()=>{
 for(const [width,height]of [[393,852],[852,393],[390,700],[700,390],[768,1024],[1024,768]]){
  const viewport=coverageViewport(width,height),safe={x:30,y:34,width:viewport.width-60,height:viewport.height-100};
  const r=coverageRegions(viewport,safe,7);const outer={x:safe.x+safe.width/2-viewport.width/2,y:safe.y+safe.height/2-viewport.height/2,width:safe.width,height:safe.height};
  for(const key of ['header','body','commands','status','navigation'])assert.ok(contains(outer,r[key]),key+' outside '+width+'x'+height);
  if(viewport.portrait)assert.ok(r.commands.y+r.commands.height/2<r.body.y-r.body.height/2);
  else assert.ok(r.commands.x-r.commands.width/2>r.body.x+r.body.width/2);
  assert.ok(r.navigation.y+r.navigation.height/2<=r.body.y-r.body.height/2);
  for(const area of commandAreas(r.commands,7)){assert.ok(contains(r.commands,area));assert.ok(area.width>100&&area.height>40);}
 }
});
