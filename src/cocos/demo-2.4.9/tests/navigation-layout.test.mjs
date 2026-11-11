import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
const url=source=>'data:text/javascript;base64,'+Buffer.from(source).toString('base64');
const compile=name=>ts.transpileModule(readFileSync(new URL(`../assets/scripts/${name}.ts`,import.meta.url),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.ES2020}}).outputText;
const {navigationGeometry}=await import(url(compile('NavigationModel')));

test('tab size and position are independent of device pixel ratio and page resolution',()=>{
  for(const frame of [{width:393,height:852},{width:852,height:393},{width:320,height:568},{width:1024,height:768}]) {
    const unit=Math.min(frame.width,frame.height)/720;
    for(const dpr of [1,2,3])for(const design of [{width:720,height:1280},{width:frame.width/unit,height:frame.height/unit}]) {
      const pixelScale=Math.min(frame.width/design.width,frame.height/design.height)*dpr;
      const width=frame.width*dpr/pixelScale,height=frame.height*dpr/pixelScale;
      const safe={x:(design.width-width)/2,y:(design.height-height)/2+34*dpr/pixelScale,width,height:height-96*dpr/pixelScale};
      const result=navigationGeometry(frame,design,safe,pixelScale,dpr);
      const close=(a,b)=>assert.ok(Math.abs(a-b)<1e-6,`${a} != ${b}`);
      close(result.width*result.scale*pixelScale/dpr,frame.width-32*unit);
      close(result.scale*76*pixelScale/dpr,76*unit);
      close(result.y*pixelScale/dpr,-frame.height/2+34+54*unit);
      close(result.x,0);
    }
  }
});

const theme={primary:'mint',pale:'dark',paper:'paper'};
class Graphics {clear(){} roundRect(...args){this.rect=args;} fill(){}}
class UITransform {setContentSize(width,height){this.size={width,height};}}
class Label {} Label.Overflow={SHRINK:1};
class Node {
  constructor(name){this.name=name;this.sizeComponent=new UITransform();this.graphics=new Graphics();this.label=new Label();this.label.node={setContentSize:(...args)=>this.label.size=args,getComponent:()=>({setContentSize:(...args)=>this.label.size=args})};}
  setContentSize(...args){this.sizeComponent.setContentSize(...args);}
  setPosition(x,y){this.position={x,y};}
  getComponent(Type){return Type===Graphics?this.graphics:this.sizeComponent;}
  getComponentInChildren(){return this.label;}
}
globalThis.__navigationLayoutTest={Graphics,Label,UITransform,Node,theme};
const bridge=url('export const {Graphics,Label,UITransform,Node}=globalThis.__navigationLayoutTest;');
const ui=url('export const {theme}=globalThis.__navigationLayoutTest;');
const {layoutNavigation}=await import(url(compile('Navigation').replace(/from ['"](?:cc|\.\/Engine)['"]/g,`from '${bridge}'`).replace("'./UI'",JSON.stringify(ui))));

test('all four tabs share geometry and only the current tab is highlighted',()=>{
  const parent=new Node('Navigation'),buttons=['Lobby','Controls','Lab','Settings'].map(name=>new Node(name));
  for(const width of [688,1200,1800,688])for(const selected of ['Lab','Controls','Settings','Lobby']){
    layoutNavigation(parent,buttons,width,selected);
    assert.deepEqual(parent.sizeComponent.size,{width,height:76});
    buttons.forEach((node,i)=>{
      const item=(width-36)/4;
      assert.deepEqual(node.sizeComponent.size,{width:item,height:76});
      assert.equal(node.position.x,-width/2+item/2+i*(item+12));
      assert.equal(node.graphics.fillColor,node.name===selected?'mint':'dark');
      assert.equal(node.label.node.color,node.name===selected?'paper':'mint');
      assert.equal(node.label.fontSize,26);assert.equal(node.label.enableWrapText,false);
    });
  }
});


test('the main bar has three equal tabs and a standalone fixture has one full-width Back',()=>{
  for(const names of [['Lobby','Lab','Settings'],['Back to Controls']]) {
    const parent=new Node('Navigation'),buttons=names.map(name=>new Node(name));
    layoutNavigation(parent,buttons,688,names[0]);
    const width=(688-12*(names.length-1))/names.length;
    for(const node of buttons)assert.equal(node.sizeComponent.size.width,width);
    assert.equal(buttons[0].position.x-width/2,-344);
    assert.ok(Math.abs(buttons.at(-1).position.x+width/2-344)<1e-6);
  }
});
