import { _decorator, Button, Color, Component, ImageAsset, Label, Layers, Node, Sorting2D, Sprite, SpriteFrame, Texture2D, UITransform } from 'cc';
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { coverageTexturePixels } from './acceptance-components/ReplayBasicCoverage';

const { ccclass } = _decorator;

/** Optional module coverage uses the official enabled engine, with real Sprite ordering. */
@ccclass('ReplayOptionalScene')
export class ReplayOptionalScene extends Component {
  private image?: ImageAsset;
  private texture?: Texture2D;
  private frame?: SpriteFrame;
  private disposed = false;

  async initialize(exit: () => void, track: (id:string,stage:string) => void): Promise<void> {
    this.image=new ImageAsset({_data:coverageTexturePixels(false),width:32,height:32,format:Texture2D.PixelFormat.RGBA8888,_compressed:false});
    this.texture=new Texture2D();this.texture.image=this.image;this.frame=new SpriteFrame();this.frame.texture=this.texture;this.frame.packable=false;
    this.label(this.node,'Sorting2D · official enabled module · batch 17',0,275,930,42,24);
    this.label(this.node,'Actual overlapping Sprite renderers; order changes must change the overlap color.',0,230,920,40,16);
    const group=this.child(this.node,'TransformGroup',0,0,960,360);
    const body=this.panel(group,'Sorting2DPrivateParent',0,20,348,100,new Color(27,39,64));
    for(const [name,x,y,w,h]of [['Top',0,76,358,3],['Bottom',0,-36,358,3],['Left',-179,20,3,112],['Right',179,20,3,112]]as const)this.panel(group,name,x,y,w,h,new Color(44,202,178));
    const a=this.panel(body,'ActualOrangeSprite',-30,0,130,70,new Color(248,164,44));
    const b=this.panel(body,'ActualCyanSprite',30,0,130,70,new Color(40,210,220));
    const sa=a.addComponent(Sorting2D),sb=b.addComponent(Sorting2D);
    const privacy=body.addComponent(ReplayPrivacy);privacy.enabled=false;
    const note=this.label(this.node,'',0,135,910,50,17);
    const status=this.label(this.node,'',0,-150,920,40,16);
    let changed=false,moved=false,visible=true,enabled=true;
    let mode:'default'|'mask'|'hide'='default';
    const apply=(stage:string)=>{
      sa.enabled=enabled;sb.enabled=enabled;sa.sortingOrder=changed?20:0;sb.sortingOrder=changed?0:20;
      group.setPosition(moved?28:0,moved?-8:0);group.setScale(moved?.85:1,moved?.85:1,1);
      body.active=visible;
      privacy.mode=mode==='hide'?ReplayPrivacyMode.Hide:ReplayPrivacyMode.Mask;privacy.enabled=mode!=='default';
      note.string=`Sorting2D enabled:${enabled} · orders ${sa.sortingOrder}/${sb.sortingOrder} · renderer priorities ${a.getComponent(Sprite)!.priority}/${b.getComponent(Sprite)!.priority}`;
      status.string=`${stage} | changed:${+changed} moved:${+moved} visible:${visible} privacy:${mode}`;
      console.log('[ReplayOptionalScene]',JSON.stringify({stage,orders:[sa.sortingOrder,sb.sortingOrder],priorities:[a.getComponent(Sprite)!.priority,b.getComponent(Sprite)!.priority],enabled,visible,moved,privacy:mode}));
      track('Sorting2D',stage);
    };
    const commands:Array<[string,()=>void]>=[
      ['Swap sorting order',()=>{changed=!changed;apply('changed');}],
      ['Move + scale',()=>{moved=!moved;apply('transformed');}],
      ['Hide / show',()=>{visible=!visible;apply(visible?'shown':'hidden');}],
      ['Enable / disable Sorting2D',()=>{enabled=!enabled;apply(enabled?'sorting-on':'sorting-off');}],
      ['Privacy default / mask / hide',()=>{mode=mode==='default'?'mask':mode==='mask'?'hide':'default';apply('privacy-'+mode);}],
      ['Reset',()=>{changed=false;moved=false;visible=true;enabled=true;mode='default';apply('reset');}],
      ['Back',()=>{this.disposed=true;exit();}],
    ];
    commands.forEach(([text,run],i)=>{const n=this.panel(this.node,'Command'+i,-345+i%4*230,i<4?-225:-285,218,42,new Color(27,39,64));n.addComponent(Button);n.on('click',()=>{if(!this.disposed)run();});this.label(n,text,0,0,212,38,13);});
    apply('entered');
  }
  private child(parent:Node,name:string,x:number,y:number,w:number,h:number):Node {const n=new Node(name);n.layer=Layers.Enum.UI_2D;n.addComponent(UITransform).setContentSize(w,h);n.setPosition(x,y);parent.addChild(n);return n;}
  private panel(parent:Node,name:string,x:number,y:number,w:number,h:number,color:Color):Node {const n=this.child(parent,name,x,y,w,h);const s=n.addComponent(Sprite);s.sizeMode=Sprite.SizeMode.CUSTOM;s.spriteFrame=this.frame!;s.color=color;return n;}
  private label(parent:Node,text:string,x:number,y:number,w:number,h:number,size:number):Label {const n=this.child(parent,'Label',x,y,w,h);const l=n.addComponent(Label);l.overflow=Label.Overflow.CLAMP;n.getComponent(UITransform)!.setContentSize(w,h);l.string=text;l.fontSize=size;l.lineHeight=24;l.color=new Color(239,244,255);l.horizontalAlign=Label.HorizontalAlign.CENTER;l.verticalAlign=Label.VerticalAlign.CENTER;return l;}
  onDestroy():void {this.disposed=true;this.frame?.destroy();this.texture?.destroy();this.image?.destroy();}
}
