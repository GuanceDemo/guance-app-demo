import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';

async function load(name) {
  const file = new URL(`../assets/scripts/coverage/${name}.ts`, import.meta.url);
  const code = ts.transpileModule(readFileSync(file,'utf8'), {compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.ES2020}}).outputText;
  return import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));
}
const generation = JSON.parse(readFileSync(new URL('../package.json',import.meta.url),'utf8')).creator.version.startsWith('2') ? 2 : 3;
const {coverageFor,coverageCategories} = await load('CoverageCatalog');
test('coverage includes the reference UI suites and only this Creator generation’s extra pages',()=>{
  const entries=coverageFor(generation),ids=entries.map(e=>e.id);
  assert.equal(new Set(ids).size,ids.length);
  assert.equal(entries.length,generation===3?17:11);
  for(const id of ['basic','input','scroll','layout','effects','motion','assets','webview','evidence']) assert.ok(ids.includes(id),id);
  for(const group of coverageCategories) assert.ok(coverageFor(generation,group.id).every(e=>e.category===group.id));
  assert.equal(ids.includes('version-diff'),generation===2);
  assert.equal(ids.includes('postprocess'),generation===3);
  assert.equal(ids.includes('native'),generation===2);
});

for(const group of ['Basic','Scroll','Layout','Effects','Motion','Asset']) {
  const name=`Replay${group}Coverage`,Model=(await load('acceptance-components/'+name))[name];
  test(`${group} coverage preserves interactions through privacy/transforms, resets and disposes`,()=>{
    const commands=new Map(),states=[],events=[];let exits=0;
    const model=new Model({apply:s=>states.push(s),status:()=>{},command:(name,_label,_x,_y,click)=>commands.set(name,click)},(...args)=>events.push(args),()=>exits++);
    const initial={...states.at(-1)};
    const common=new Set(['Privacy','Transform','Visibility','Reset','Exit']);
    for(const [name,click] of commands) if(!common.has(name)) click();
    if(group==='Basic') {model.pressButton();model.toggle(true);}
    const edited={...states.at(-1)};
    assert.notDeepEqual(edited,initial);
    commands.get('Privacy')();commands.get('Transform')();commands.get('Visibility')();
    assert.equal(states.at(-1).privacy,'mask');assert.equal(states.at(-1).moved,true);assert.equal(states.at(-1).visible,false);
    for(const [key,value] of Object.entries(edited)) if(!['privacy','moved','visible'].includes(key)) assert.deepEqual(states.at(-1)[key],value,key);
    commands.get('Privacy')();assert.equal(states.at(-1).privacy,'hide');
    commands.get('Privacy')();assert.equal(states.at(-1).privacy,'default');
    commands.get('Reset')();
    for(const [key,value] of Object.entries(initial)) if(!/revision/i.test(key)) assert.deepEqual(states.at(-1)[key],value,key);
    commands.get('Exit')();const stateCount=states.length,eventCount=events.length;
    for(const click of commands.values())click();model.dispose();
    assert.equal(exits,1);assert.equal(states.length,stateCount);assert.equal(events.length,eventCount);
  });
}
const {ReplayScrollCoverage}=await load('acceptance-components/ReplayScrollCoverage');
test('scroll input clamps finite values and native scroll notifications do not reset scroll position',()=>{
  let applies=0;const events=[],states=[];
  const model=new ReplayScrollCoverage({apply:s=>{applies++;states.push(s);},status:()=>{},command:()=>{}},(...args)=>events.push(args),()=>{});
  model.slide(5);assert.equal(states.at(-1).progress,1);
  model.slide(-2);assert.equal(states.at(-1).progress,0);
  const count=applies;model.slide(NaN);model.slide(Infinity);model.scrolled();
  assert.equal(applies,count);assert.deepEqual(events.at(-1),['ScrollView','dragged']);
  model.dispose();const eventCount=events.length;model.slide(.5);model.scrolled();assert.equal(events.length,eventCount);
});
const {ReplayInputCoverage}=await load('acceptance-components/ReplayInputCoverage');
test('input coverage recreates private inputs, records no contents and ignores stale callbacks after exit',()=>{
  const commands=new Map(),events=[],inputs=[];let exits=0;
  const model=new ReplayInputCoverage({input:(id,kind,_y,phase)=>{
    const input={id,kind,phase,value:'',privacy:'default',destroyed:false,
      setValue(v){this.value=v;},setPassword(v){this.revealed=v;},setVisible(v){this.visible=v;},setPrivacy(v){this.privacy=v;},blur(){},destroy(){this.destroyed=true;}};
    inputs.push(input);return input;
  },button:(name,_title,_x,_y,click)=>commands.set(name,click),status:()=>{},transform:()=>{}},(...args)=>events.push(args),()=>exits++);
  inputs[0].value='USER-TYPED-PRIVATE-TEXT';inputs[0].phase('changed');
  commands.get('InputPrivacy')();commands.get('DynamicInput')();assert.equal(inputs[3].destroyed,true);
  const count=events.length;inputs[3].phase('changed');assert.equal(events.length,count);
  commands.get('DynamicInput')();assert.equal(inputs.at(-1).privacy,'mask');
  commands.get('PasswordVisibility')();assert.equal(inputs[1].revealed,true);
  commands.get('ExitInputCoverage')();const end=events.length;
  for(const click of commands.values())click();for(const input of inputs)input.phase('changed');model.dispose();
  assert.equal(exits,1);assert.equal(events.length,end);assert.ok(inputs.every(input=>input.destroyed));
  assert.equal(JSON.stringify(events).includes('USER-TYPED-PRIVATE-TEXT'),false);
});
