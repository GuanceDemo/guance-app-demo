import { Button, Color, Graphics, Label, Mask, Node, ScrollView, ViewGroup, Vec2, isValid } from '../Engine';
import { layoutNavigation } from '../Navigation';
import { box, button, text, theme } from '../UI';
import { Area, CoverageRegions, CoverageViewport, commandAreas, coverageRegions } from './CoverageLayoutModel';
import { CoverageCategory, CoverageEntry } from './CoverageCatalog';

export type CoverageNavigation = Array<[string, () => void]>;
interface Original { node: Node; x: number; y: number; width: number; height: number }
interface Slot { node: Node; width: number; height: number; labels: Label[] }
interface Row { owner: Node; node: Node; title: Slot; control: Slot; note: Slot }
interface Gallery { entries: ReadonlyArray<CoverageEntry>; filter: CoverageCategory | 'all'; selectFilter: (filter: CoverageCategory | 'all') => void; open: (entry: CoverageEntry) => void; offset: number }

function size(node: Node): {width:number;height:number} {
  return node.getContentSize();
}
function setSize(node: Node, width: number, height: number): void {
  node.setContentSize(width, height);
}
function snapshot(node: Node): Original { const s=size(node); return {node,x:node.position.x,y:node.position.y,width:s.width,height:s.height}; }
function valid(node: Node): boolean { for(let current:Node|null=node;current;current=current.parent){if(!isValid(current,true))return false;}return true; }
function panelSize(node: Node, width: number, height: number): void {
  setSize(node,width,height);
  const graphics=node.getComponent(Graphics);
  if(graphics){graphics.clear();graphics.roundRect(-width/2,-height/2,width,height,12);graphics.fill();}
}
function labelSize(label: Label, width: number, height: number, fontSize: number): void {
  setSize(label.node,width,height);label.fontSize=fontSize;label.lineHeight=fontSize+6;
  label.overflow=Label.Overflow.SHRINK;label.enableWrapText=true;
}
function named(root: Node, name: string): Node | undefined {
  if(root.name===name)return root;
  for(const child of root.children){const found=named(child,name);if(found)return found;}
  return undefined;
}

/** Reflow existing test nodes; their components, values and privacy boundaries stay alive. */
export class CoverageSurface {
  private scope: Node;
  private navigation: Node;
  private backdrop: Graphics;
  private navButtons: Node[]=[];
  private originals=new Map<Node,Original>();
  private groups: Node[]=[];
  private rows: Row[]=[];
  private commands: Original[]=[];
  private headings: Original[]=[];
  private status: Original[]=[];
  private notes: Original[]=[];
  private body: Node;
  private content: Node;
  private scroll: ScrollView;
  private fingerprint='';
  private viewport?: CoverageViewport;
  private safe?: Area;
  private regions?: CoverageRegions;
  private gallery?: Gallery;
  private galleryNodes: Node[]=[];
  private disposed=false;
  private readonly world: boolean;

  constructor(private root: Node, private kind: string, navigation: CoverageNavigation) {
    this.world=['perspective','lights','postprocess'].includes(kind);
    this.scope=this.world ? named(root,'HUDCanvas')! : root;
    const backdrop=box(this.scope,'CoverageResponsiveBackdrop',0,0,1,1);backdrop.setSiblingIndex(0);this.backdrop=backdrop.addComponent(Graphics);this.backdrop.fillColor=new Color(12,18,34);
    this.navigation=box(this.scope,'CoverageResponsiveNavigation',0,0,1,1,theme.background);
    navigation.forEach(([title,handler])=>this.navButtons.push(button(this.navigation,title,0,0,1,76,handler,true)));
    this.body=box(this.scope,'CoverageResponsiveBody',0,0,1,1);
    this.body.addComponent(Mask).type=Mask.Type.RECT;
    this.content=box(this.body,'CoverageResponsiveContent',0,0,1,1);
    this.content.setAnchorPoint(0.5,1);
    this.scroll=this.body.addComponent(ScrollView);this.scroll.content=this.content;
    this.scroll.horizontal=false;this.scroll.vertical=true;this.scroll.inertia=true;
    this.body.on('scrolling',()=>this.syncPhysics());
    if(!this.world)this.discover();else this.discoverChrome();
  }

  get scrollOffset(): number { return Math.max(0,this.scroll.getScrollOffset().y); }
  showGallery(gallery: Gallery): void { this.gallery=gallery; }

  resize(viewport: CoverageViewport, safe: Area): CoverageRegions {
    if(this.gallery&&this.viewport)this.gallery.offset=this.scrollOffset;
    this.viewport=viewport;this.safe=safe;setSize(this.scope,viewport.width,viewport.height);
    this.regions=coverageRegions(viewport,safe,this.gallery?0:this.visibleCommands().length);
    this.apply();return this.regions;
  }

  update(): void {
    if(this.disposed||this.gallery||!this.viewport||!this.safe)return;
    const fingerprint=this.signature();
    if(fingerprint===this.fingerprint)return;
    this.discover();this.regions=coverageRegions(this.viewport,this.safe,this.visibleCommands().length);this.apply();
  }

  private original(node: Node): Original {
    let value=this.originals.get(node);if(!value){value=snapshot(node);this.originals.set(node,value);}return value;
  }
  private own(node: Node): boolean {return node.name.startsWith('CoverageResponsive');}
  private signature(): string {
    return [this.scope,...this.groups].filter(valid).map(node=>node.children.filter(n=>valid(n)&&!this.own(n)).map(n=>n.uuid).join(',')).join('|')+'|'+this.commands.map(item=>item.node.activeInHierarchy).join(',');
  }
  private visibleCommands(): Original[] { return this.commands.filter(item=>valid(item.node)&&item.node.activeInHierarchy); }
  private discoverChrome(): void {
    const nodes=[...this.scope.children,...this.scope.children.filter(n=>/^(PrimaryControls|PrivacyControls)$/.test(n.name)).flatMap(n=>n.children)];
    for(const node of nodes){
      if(this.own(node)||!valid(node))continue;
      const original=this.original(node);
      const label=node.getComponent(Label)??node.getComponentInChildren(Label);
      if(node.name==='Background'||node.name==='StatusPanel'){node.active=false;continue;}
      if(node.getComponent(Button)){
        const caption=node.getComponentsInChildren(Label).map(l=>l.string).join(' ');
        if(/^(?:Back|Exit|‹\s*Categories)/i.test(caption.trim())){node.active=false;continue;}
        if(!this.commands.some(item=>item.node===node))this.commands.push(original);
      }else if(label){
        if(original.y>220||(this.kind==='native'&&label.string.startsWith('Perspective +'))){
          if(!this.headings.some(item=>item.node===node))this.headings.push(original);
        }else if(original.y< -140){
          if(!this.status.some(item=>item.node===node))this.status.push(original);
        }else if(original.y>0&&original.y<=220&&!this.notes.some(item=>item.node===node))this.notes.push(original);
      }
    }
    this.headings.sort((a,b)=>b.y-a.y);
  }
  private discover(): void {
    this.discoverChrome();
    for(const group of this.scope.children.filter(n=>/^(Cases|InputCases|TransformGroup|EvidencePage\d+)$/.test(n.name))){
      if(!this.groups.includes(group)){this.original(group);this.groups.push(group);}
    }
    this.rows=this.rows.filter(row=>valid(row.owner));this.groups=this.groups.filter(valid);
    for(const group of this.groups){
      const children=group.children.filter(n=>valid(n)&&!this.own(n));
      const containers=children.filter(n=>n.children.some(c=>c.getComponent(Label)&&c.position.x< -200));
      if(containers.length){
        for(const row of containers){
          if(this.rows.some(item=>item.owner===row))continue;
          const original=this.original(row);
          const anchor=box(group,'CoverageResponsiveRow',0,0,1,1);
          row.removeFromParent();anchor.addChild(row);row.setPosition(0,0);
          this.rows.push(this.makeRow(row,row.children.filter(n=>valid(n)),0,anchor,original));
        }
      }else if(children.length){
        const labels=children.filter(n=>n.getComponent(Label)&&n.position.x< -200).sort((a,b)=>b.position.y-a.position.y);
        if(labels.length){
          const groups=labels.map(label=>({label,y:label.position.y,nodes:[] as Node[]}));
          const centers=children.filter(n=>/(Private|Container|Target)$/.test(n.name));
          for(const node of children){
            const center=centers.find(c=>node.name.startsWith(c.name.replace(/(Private|Container|Target)$/,'')));
            const y=center?.position.y??node.position.y;
            const row=groups.reduce((best,item)=>Math.abs(item.y-y)<Math.abs(best.y-y)?item:best,groups[0]!);
            row.nodes.push(node);
          }
          for(const row of groups){const anchor=box(group,'CoverageResponsiveRow',0,0,1,1);this.rows.push(this.makeRow(group,row.nodes,row.y,anchor));}
        }else if(!this.rows.some(row=>row.owner===group)){
          const anchor=box(group,'CoverageResponsiveRow',0,0,1,1);
          this.rows.push(this.makeRow(group,children,0,anchor));
        }
      }
      if(group.parent!==this.content){
        const original=this.original(group);const origin=box(this.content,'CoverageResponsiveGroup',-original.x,-original.y,1,1);
        group.removeFromParent();origin.addChild(group);
      }
    }
    this.fingerprint=this.signature();
  }
  private makeRow(owner: Node, nodes: Node[], y: number, anchor: Node, original?: Original): Row {
    const background=box(anchor,'CoverageResponsiveCard',0,0,1,1,theme.paper);background.setSiblingIndex(0);
    for(const node of nodes.filter(n=>n.name==='RowBackground'))node.active=false;
    const title=nodes.filter(n=>n.getComponent(Label)&&n.position.x< -200);
    const note=nodes.filter(n=>n.getComponent(Label)&&n.position.x>200);
    const controls=nodes.filter(n=>!title.includes(n)&&!note.includes(n)&&n.name!=='RowBackground');
    const parent=original?owner:anchor;
    const slot=(items:Node[],name:string,centerX:number):Slot=>{
      const outer=box(parent,'CoverageResponsive'+name,0,0,1,1);
      if(name==='Control'){
        // An outer page scroll must leave Slider/EditBox/PageView gestures to the real control.
        outer.addComponent(ViewGroup);
        for(const event of [Node.EventType.TOUCH_START,Node.EventType.TOUCH_MOVE,Node.EventType.TOUCH_END,Node.EventType.TOUCH_CANCEL])outer.on(event,()=>{},undefined,true);
      }
      const origin=box(outer,'CoverageResponsiveOrigin',-centerX,-y,1,1);
      let left=Infinity,right=-Infinity,top=-Infinity,bottom=Infinity;
      for(const node of items){const s=this.original(node);left=Math.min(left,s.x-s.width/2);right=Math.max(right,s.x+s.width/2);top=Math.max(top,s.y+s.height/2);bottom=Math.min(bottom,s.y-s.height/2);node.removeFromParent();origin.addChild(node);}
      return {node:outer,width:items.length?right-left:0,height:items.length?top-bottom:0,labels:items.map(n=>n.getComponent(Label)).filter((l):l is Label=>!!l)};
    };
    const titleX=title.length?this.original(title[0]!).x:0,noteX=note.length?this.original(note[0]!).x:0;
    const row={owner,node:anchor,title:slot(title,'Title',titleX),control:slot(controls,'Control',0),note:slot(note,'Note',noteX)};
    // The fixture may still transform its original row or whole Cases group.
    return row;
  }
  private apply(): void {
    if(!this.regions||!this.viewport)return;
    const r=this.regions,p=this.viewport.portrait;
    const w=this.viewport.width,h=this.viewport.height,g=this.backdrop;g.clear();
    if(this.world){
      const b=r.body,left=b.x-b.width/2,right=b.x+b.width/2,bottom=b.y-b.height/2,top=b.y+b.height/2;
      g.rect(-w/2,top,w,h/2-top);g.rect(-w/2,-h/2,w,bottom+h/2);
      g.rect(-w/2,bottom,left+w/2,b.height);g.rect(right,bottom,w/2-right,b.height);
    }else g.rect(-w/2,-h/2,w,h);
    g.fill();
    this.navigation.setPosition(r.navigation.x,r.navigation.y);panelSize(this.navigation,r.navigation.width,r.navigation.height);
    layoutNavigation(this.navigation,this.navButtons,r.navigation.width,this.navButtons[0]?.name??'');
    if(this.gallery){this.renderGallery();return;}
    this.headings.forEach((item,i)=>{item.node.setPosition(r.header.x,r.header.y+(i===0?24:-28));const label=item.node.getComponent(Label)??item.node.getComponentInChildren(Label)!;if(label.node!==item.node){panelSize(item.node,r.header.width,96);label.node.setPosition(0,0);}labelSize(label,r.header.width,this.headings.length===1?96:48,i===0?32:22);});
    this.status.forEach((item,i)=>{const height=r.status.height/this.status.length;item.node.setPosition(r.status.x,r.status.y+r.status.height/2-height*(i+.5));labelSize(item.node.getComponent(Label)!,Math.max(1,r.status.width),height,22);});
    this.notes.forEach((item,i)=>{item.node.setPosition(r.body.x,r.body.y+r.body.height/2-44-i*64);labelSize(item.node.getComponent(Label)!,r.body.width-32,72,24);});
    const commands=this.visibleCommands(),areas=commandAreas(r.commands,commands.length);
    commands.forEach((item,i)=>{const area=areas[i]!;item.node.setPosition(area.x,area.y);panelSize(item.node,area.width,area.height);for(const label of item.node.getComponentsInChildren(Label)){label.node.setPosition(0,0);labelSize(label,area.width-16,area.height-10,24);}});
    if(!this.world){this.layoutRows();this.syncPhysics(true);}else this.body.active=false;
    this.fingerprint=this.signature();
  }
  private syncPhysics(resizeShapes=false): void {
    if(this.kind!=='evidence')return;
    this.scope.getComponentsInChildren(cc.RigidBody).filter(body=>valid(body.node)).forEach(body=>{body.syncPosition(false);body.syncRotation(false);});
    if(resizeShapes)this.scope.getComponentsInChildren(cc.PhysicsCollider).filter(collider=>valid(collider.node)).forEach(collider=>collider.apply());
    // Creator 2 omits its runtime 3D manager from the bundled declarations.
    const manager=cc.director.getPhysics3DManager() as unknown as {physicsWorld?:{syncSceneToPhysics?():void}}|undefined;
    manager?.physicsWorld?.syncSceneToPhysics?.();
  }
  private layoutRows(): void {
    const r=this.regions!,p=this.viewport!.portrait,evidence=p&&this.kind==='evidence';
    this.body.setPosition(r.body.x,r.body.y);setSize(this.body,r.body.width,r.body.height);
    const rows=this.rows.filter(row=>valid(row.owner));
    if(this.kind==='native'){
      // Only one engine-native 3D case is visible at a time.
      for(const row of rows)this.placeWholeRow(row,r.body.width,r.body.height);
      setSize(this.content,r.body.width,r.body.height);this.content.setPosition(0,r.body.height/2);return;
    }
    const heights=rows.map(row=>{
      const controlWidth=p?r.body.width-56:r.body.width*.43;
      const scale=Math.min(p?(evidence?1.3:1.45):1.2,controlWidth/Math.max(1,row.control.width));
      return Math.max(p?152:88,row.control.height*scale+(p?(evidence?128:88):12));
    });
    const gap=p?12:8,minimum=heights.reduce((sum,height)=>sum+height,0)+Math.max(0,rows.length-1)*gap,extra=Math.max(0,r.body.height-minimum)/Math.max(1,rows.length);
    const contentHeight=Math.max(r.body.height,minimum);
    setSize(this.content,r.body.width,contentHeight);this.content.setPosition(0,r.body.height/2);
    let top=0;
    rows.forEach((row,i)=>{
      const height=heights[i]!+extra;row.node.setPosition(0,-top-height/2);top+=height+gap;
      panelSize(row.node.children[0]!,r.body.width,height-6);
      const titleWidth=p?r.body.width-40:r.body.width*.24,noteWidth=p?r.body.width-40:r.body.width*.23;
      const contentWidth=p?r.body.width-56:r.body.width*.43;
      const scale=Math.min(p?(evidence?1.3:1.45):1.2,contentWidth/Math.max(1,row.control.width));
      row.control.node.setPosition(0,p?(evidence?14:-3):0);row.control.node.setScale(scale,scale,1);
      row.title.node.setPosition(p?0:-(r.body.width-titleWidth)/2+12,p?height/2-22:0);
      row.note.node.setPosition(p?0:(r.body.width-noteWidth)/2-12,p?-height/2+(evidence?34:22):0);
      row.title.labels.forEach(label=>labelSize(label,titleWidth,p?36:height-12,p?26:24));
      row.note.labels.forEach(label=>labelSize(label,noteWidth,p?(evidence?64:36):height-12,22));
    });
    if(this.kind==='webview'){
      const web=this.scope.children.find(node=>node.name==='ValidationWebView'&&valid(node));
      if(web){web.setPosition(r.body.x,r.body.y);setSize(web,r.body.width,r.body.height);}
      const empty=this.scope.children.filter(node=>node.getComponent(Label)&&this.original(node).y===0);
      empty.forEach(node=>{node.setPosition(r.body.x,r.body.y);labelSize(node.getComponent(Label)!,r.body.width-32,180,28);});
    }
  }
  private placeWholeRow(row:Row,width:number,height:number):void {
    row.node.setPosition(0,-height/2);panelSize(row.node.children[0]!,width,height-8);
    row.control.node.setPosition(0,0);const scale=Math.min((width-24)/Math.max(1,row.control.width),(height-24)/Math.max(1,row.control.height));row.control.node.setScale(scale,scale,1);
  }
  private renderGallery(): void {
    const gallery=this.gallery!,r=this.regions!,viewport=this.viewport!;
    this.galleryNodes.forEach(node=>{node.active=false;node.destroy();});this.galleryNodes=[];
    const add=(node:Node)=>{this.galleryNodes.push(node);return node;};
    add(text(this.scope,'Component gallery',r.header.x,r.header.y+22,r.header.width,48,34).node);
    add(text(this.scope,`${gallery.entries.length} scenes · Select a page`,r.header.x,r.header.y-25,r.header.width,38,22,theme.muted).node);
    const filters: Array<[CoverageCategory|'all',string]>=[['all','All'],['ui','UI'],['3d','3D'],['diagnostics','Physics']];
    const tabsY=r.body.y+r.body.height/2-34;
    filters.forEach(([filter,title],i)=>{const width=(r.body.width-36)/4;add(button(this.scope,title,r.body.x-r.body.width/2+width/2+i*(width+12),tabsY,width,64,()=>gallery.selectFilter(filter),gallery.filter===filter));});
    const height=r.body.height-88;
    this.body.setPosition(r.body.x,r.body.y-44);setSize(this.body,r.body.width,height);
    const columns=viewport.portrait?2:Math.max(3,Math.floor(r.body.width/310));
    const gap=16,width=(r.body.width-gap*(columns-1))/columns,cardHeight=156;
    const entries=gallery.entries.filter(entry=>gallery.filter==='all'||entry.category===gallery.filter);
    const contentHeight=Math.max(height,Math.ceil(entries.length/columns)*(cardHeight+gap));
    setSize(this.content,r.body.width,contentHeight);this.content.setPosition(0,height/2);
    entries.forEach((entry,i)=>{
      const x=-r.body.width/2+width/2+(i%columns)*(width+gap),y=-cardHeight/2-Math.floor(i/columns)*(cardHeight+gap);
      const card=add(button(this.content,'',x,y,width,cardHeight,()=>gallery.open(entry)));card.name=entry.title;
      text(card,entry.title,0,37,width-28,58,28,theme.primary);text(card,entry.description,0,-35,width-28,76,22,theme.muted);
    });
    this.scroll.scrollToOffset(new Vec2(0,Math.min(gallery.offset,Math.max(0,contentHeight-height))),0);
  }
  destroy(): void {this.disposed=true;this.scroll.stopAutoScroll();}
}
