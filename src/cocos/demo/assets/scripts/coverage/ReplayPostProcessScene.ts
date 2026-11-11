import { _decorator, Button, Camera, Canvas, Color, Component, DirectionalLight, Graphics, ImageAsset, Label, Layers, Material, Mesh, MeshRenderer, Node, RenderTexture, Texture2D, UITransform, Vec3, director, js, macro, postProcess, primitives, rendering, resources, utils, view } from 'cc';
import 'db://internal/default_renderpipeline/builtin-dof-pass';
import ReplayPrivacy, { ReplayPrivacyMode } from '../../guance-cocos-sdk/ReplayPrivacy';
import { loadReplayPostEffects } from './ReplayPostEffects';
const { ccclass } = _decorator;

/** Real depth geometry and the installed engine's post-processing components. */
@ccclass('ReplayPostProcessScene')
export class ReplayPostProcessScene extends Component {
  camera!:Camera;
  private previousPipeline='';
  private world!:Node;
  private materials:Material[]=[];
  private mesh?:Mesh;
  private textures:Texture2D[]=[];
  private images:ImageAsset[]=[];
  private settings:Component[]=[];
  private disposed=false;
  private taaMask?:Component & {maskCamera?:Camera;mask?:RenderTexture;_mask?:RenderTexture};

  async initialize(exit:()=>void,track:(component:string,stage:string)=>void,selectCapture:(enabled:boolean)=>void):Promise<void> {
    const base=await new Promise<Material>((resolve,reject)=>resources.load('Replay3D',Material,(e,m)=>e?reject(e):resolve(m)));
    if(!this.isValid)return;
    const effects=postProcess?.PostProcess?loadReplayPostEffects():[];
    const cameraNode=this.child(this.node,'PostPerspectiveCamera');cameraNode.setPosition(4,3,7);cameraNode.lookAt(new Vec3(0,0,0));
    this.camera=cameraNode.addComponent(Camera);this.camera.projection=Camera.ProjectionType.PERSPECTIVE;this.camera.fov=45;this.camera.near=.1;this.camera.far=100;this.camera.visibility=Layers.Enum.DEFAULT;this.camera.clearFlags=Camera.ClearFlag.SOLID_COLOR;this.camera.clearColor=new Color(12,18,34);
    this.world=this.child(this.node,'PrivateWorld');this.world.addComponent(UITransform).setContentSize(10,10);const privacy=this.world.addComponent(ReplayPrivacy);privacy.enabled=false;
    const light=this.child(this.node,'KeyLight');light.setRotationFromEuler(-45,-30,0);light.addComponent(DirectionalLight).illuminance=65000;
    this.mesh=utils.createMesh(primitives.box());
    const box=(name:string,p:Vec3,s:Vec3,color:Color,emissive=false)=>{
      const n=this.child(this.world,name);n.setPosition(p);n.setScale(s);const m=n.addComponent(MeshRenderer);m.mesh=this.mesh!;
      const mat=new Material();mat.copy(base);mat.setProperty('mainColor',color);mat.setProperty('roughness',.65);mat.setProperty('metallic',0);
      if(emissive){mat.setProperty('emissive',Color.WHITE);mat.setProperty('emissiveScale',new Vec3(4,4,4));}
      this.materials.push(mat);m.setSharedMaterial(mat,0);return n;
    };
    box('ContactFloor',new Vec3(0,-1.1,0),new Vec3(7,.15,6),new Color(145,153,165));
    box('OrangeNearCube',new Vec3(-1.1,0,1.0),new Vec3(1.1,1.9,1.1),new Color(245,130,30)).setRotationFromEuler(0,25,0);
    box('CyanMiddleCube',new Vec3(1.0,-.2,0),new Vec3(1.0,1.5,1.0),new Color(25,210,215));
    box('BlueFarTower',new Vec3(.5,.4,-2.2),new Vec3(.8,2.8,.8),new Color(50,90,245));
    box('BrightBloomReceiver',new Vec3(-1.7,1.0,-1.7),new Vec3(.45,.45,.45),Color.WHITE,true);
    for(let i=0;i<10;i++)box('DiagonalEdge'+i,new Vec3(-2.0+i*.38,-.7,-1.2),new Vec3(.11,1.0,.06),i%2?Color.WHITE:Color.BLACK).setRotationFromEuler(0,0,18);
    if (!postProcess?.PostProcess) { await this.initializeBuiltin(exit,track,selectCapture); return; }
    const ppNode=this.child(this.node,'ActualPostProcessSettings');const pp=ppNode.addComponent(postProcess.PostProcess);pp.global=false;this.camera.postProcess=pp;this.camera.usePostProcess=true;
    // 3.8.8 registers cc.FXAA through FxaaPass but omits its namespace export.
    const FXAA=js.getClassByName('cc.FXAA') as new()=>Component;if(!FXAA)throw new Error('Official registered cc.FXAA missing');
    const blit=ppNode.addComponent(postProcess.BlitScreen),bloom=ppNode.addComponent(postProcess.Bloom),grading=ppNode.addComponent(postProcess.ColorGrading),dof=ppNode.addComponent(postProcess.DOF),fsr=ppNode.addComponent(postProcess.FSR),fxaa=ppNode.addComponent(FXAA),hbao=ppNode.addComponent(postProcess.HBAO),taa=ppNode.addComponent(postProcess.TAA);
    this.settings=[blit,bloom,grading,dof,fsr,fxaa,hbao,taa];this.settings.forEach(s=>s.enabled=false);
    const tint=new Material();tint.initialize({effectName:'coverage/ReplayPostTint'});this.materials.push(tint);blit.activeMaterials=[tint];
    const lut=(color:Color)=>{const data=new Uint8Array(256*16*4);for(let i=0;i<data.length;i+=4){data[i]=color.r;data[i+1]=color.g;data[i+2]=color.b;data[i+3]=255;}const image=new ImageAsset({_data:data,width:256,height:16,format:Texture2D.PixelFormat.RGBA8888,_compressed:false});const texture=new Texture2D();texture.image=image;this.images.push(image);this.textures.push(texture);return texture;};
    const luts=[lut(new Color(210,45,190)),lut(new Color(35,205,80))];
    const TAAMask=js.getClassByName('TAAMask') as new()=>Component & {maskCamera?:Camera;mask?:RenderTexture;_mask?:RenderTexture};if(!TAAMask)throw new Error('Official registered TAAMask missing');
    const maskNode=this.child(this.node,'ActualTAAMaskCamera');const maskCamera=maskNode.addComponent(Camera);maskCamera.projection=Camera.ProjectionType.ORTHO;maskCamera.visibility=0;maskCamera.priority=-10;maskCamera.clearFlags=Camera.ClearFlag.SOLID_COLOR;maskCamera.clearColor=Color.WHITE;maskCamera.enabled=false;
    const taaMask=cameraNode.addComponent(TAAMask);taaMask.maskCamera=maskCamera;taaMask.enabled=false;this.taaMask=taaMask;
    const names=['BlitScreen','Bloom','ColorGrading','DOF','FSR','FXAA','HBAO','TAA','TAAMask'];let index=0,on=false,variant=false,moved=false,visible=true,captureOn=false;let mode:'default'|'mask'|'hide'='default';
    const hud=this.child(this.node,'IndependentHUD');hud.layer=Layers.Enum.UI_2D;const hudCameraNode=this.child(hud,'HUDCamera');hudCameraNode.layer=Layers.Enum.UI_2D;hudCameraNode.setPosition(0,0,1000);const hc=hudCameraNode.addComponent(Camera);hc.projection=Camera.ProjectionType.ORTHO;hc.orthoHeight=view.getVisibleSize().height/2;hc.visibility=Layers.Enum.UI_2D;hc.priority=10;hc.clearFlags=Camera.ClearFlag.DEPTH_ONLY;
    const canvas=this.child(hud,'HUDCanvas');canvas.layer=Layers.Enum.UI_2D;const size=view.getVisibleSize();canvas.addComponent(UITransform).setContentSize(size.width,size.height);canvas.addComponent(Canvas).cameraComponent=hc;
    const title=this.label(canvas,'',0,size.height/2-38,size.width-20,66,19);
    const apply=(stage:string)=>{
      this.settings.forEach((s,i)=>s.enabled=on&&i===index);
      if(index===8)taa.enabled=true;taaMask.enabled=index===8&&on;maskCamera.enabled=index===8&&on;maskCamera.clearColor=variant?Color.BLACK:Color.WHITE;
      blit.activeMaterials=variant?[]:[tint];bloom.threshold=variant?.8:.1;bloom.iterations=3;bloom.intensity=variant?1:4;
      grading.colorGradingMap=luts[variant?1:0]!;grading.contribute=1;
      dof.focusDistance=variant?10:3;dof.focusRange=.15;dof.bokehRadius=variant?3:8;fsr.sharpness=variant?0:1;
      hbao.radiusScale=variant?.5:4;hbao.aoSaturation=1.5;hbao.blurSharpness=3;taa.sampleScale=index===8?4:(variant?3:1);taa.feedback=index===8?.98:(variant?.3:.95);
      pp.shadingScale=index===4?.5:1;this.world.setPosition(moved?.5:0,0,0);this.world.setRotationFromEuler(0,moved?20:0,0);this.world.active=visible;
      privacy.mode=mode==='hide'?ReplayPrivacyMode.Hide:ReplayPrivacyMode.Mask;privacy.enabled=mode!=='default';
      title.string=`POST PROCESS / ${names[index]} · enabled:${on} variant:${+variant}\n${stage} · capture:${captureOn} geometry:${visible} privacy:${mode}`;
      console.log('[ReplayPostProcessScene]',JSON.stringify({component:names[index],stage,on,variant,moved,visible,captureOn,privacy:mode,pipeline:macro.CUSTOM_PIPELINE_NAME,effects:effects.length,shadingScale:pp.shadingScale,activeSettings:[...pp.settings.keys()].map(k=>k.name),postProcessPass:rendering.getPassID('post-process')}));
      track(names[index]!,stage);
      if(index===8)this.scheduleOnce(()=>{if(this.disposed)return;const mask=taaMask.mask;console.log('[TAAMaskRuntime]',JSON.stringify({stage,enabled:taaMask.enabled,maskCameraEnabled:maskCamera.enabled,maskSize:mask?[mask.width,mask.height]:null,maskFormat:mask?.getGFXTexture()?.format??null,variant,sourceNodeHasMask:!!this.camera.node.getComponent('TAAMask')}));},.1);
    };
    const commands:Array<[string,()=>void]>=[['Next component',()=>{index=(index+1)%names.length;on=false;variant=false;moved=false;visible=true;mode='default';apply('selected');}],['Effect on / off',()=>{on=!on;apply(on?'enabled':'disabled');}],['Change parameter',()=>{variant=!variant;apply('parameter');}],['SDK capture on / off',()=>{captureOn=!captureOn;apply(captureOn?'capture-on':'capture-off');selectCapture(captureOn);}],['Hide / show geometry',()=>{visible=!visible;apply(visible?'shown':'hidden');}],['Privacy default / mask / hide',()=>{mode=mode==='default'?'mask':mode==='mask'?'hide':'default';apply('privacy-'+mode);}],['Reset component',()=>{on=false;variant=false;moved=false;visible=true;mode='default';apply('reset');}],['Back',()=>{this.disposed=true;exit();}]];
    commands.forEach(([text,run],i)=>{const n=this.child(canvas,'PostCommand'+i);n.layer=Layers.Enum.UI_2D;const w=size.width/4-12;n.setPosition((i%4-1.5)*size.width/4,-size.height/2+(i<4?86:28));n.addComponent(UITransform).setContentSize(w,44);const g=n.addComponent(Graphics);g.fillColor=new Color(27,39,64);g.rect(-w/2,-22,w,44);g.fill();n.addComponent(Button).transition=Button.Transition.NONE;n.on('click',()=>{if(!this.disposed)run();});this.label(n,text,0,0,w-8,40,14);});
    // Keep the independent controls on the established Builtin UI path. The
    // source camera and its Replay child use the unchanged PostProcess builder.
    const builtin=rendering.getCustomPipeline('Builtin'),processor=rendering.getCustomPipeline('Custom');
    const observedCameras=new Set<unknown>();
    const routed:rendering.PipelineBuilder={
      setup:(cameras,pipeline)=>{for(const camera of cameras){const key=camera.node?.uuid??camera;if(!observedCameras.has(key)){observedCameras.add(key);console.log('[PostNativeCamera]',JSON.stringify({name:camera.node?.name,id:(camera as unknown as {cameraId?:number}).cameraId??null,nativeId:(camera as unknown as {getCameraId?:()=>number}).getCameraId?.call(camera)??null,idAccessors:Object.getOwnPropertyNames(Object.getPrototypeOf(camera)).filter(n=>n.toLowerCase().includes('id')),hasTAAMask:!!camera.node?.getComponent('TAAMask'),usePostProcess:camera.usePostProcess,hasSettings:!!camera.postProcess,windowId:camera.window.renderWindowId,colorName:camera.window.colorName,colorFormats:camera.window.framebuffer.colorTextures.map(t=>t?.format??null),isHDR:pipeline.pipelineSceneData.isHDR,floatOutput:pipeline.getMacroBool('CC_USE_FLOAT_OUTPUT')}));}(camera.usePostProcess?processor:builtin).setup([camera],pipeline);
        // The native CameraQuad path updates descriptor sets, but does not call
        // Pass.update() to submit material UBO changes made by these JS passes.
        // Submit through the public Pass API after the official builder setup.
        if(camera.usePostProcess){const passes=(processor as rendering.PipelineBuilder & {pipelines:Map<string,Array<{_material?:Material;taaMaskMaterial?:Material}>>}).pipelines;const materials=new Set<Material>();for(const group of passes.values())for(const pass of group){if(pass._material)materials.add(pass._material);if(pass.taaMaskMaterial)materials.add(pass.taaMaskMaterial);}for(const material of materials)for(const pass of material.passes)pass.update();}
      }},
      windowResize:(pipeline,window,camera,width,height)=>(camera.usePostProcess?processor:builtin).windowResize?.(pipeline,window,camera,width,height),
      onGlobalPipelineStateChanged:()=>{builtin.onGlobalPipelineStateChanged?.();processor.onGlobalPipelineStateChanged?.();},
    };
    rendering.setCustomPipeline('ReplayCoveragePost',routed);
    this.previousPipeline=macro.CUSTOM_PIPELINE_NAME;macro.CUSTOM_PIPELINE_NAME='ReplayCoveragePost';rendering.forceResizeAllWindows();apply('entered');
  }
  private async initializeBuiltin(exit:()=>void,track:(component:string,stage:string)=>void,selectCapture:(enabled:boolean)=>void):Promise<void> {
    const Settings=js.getClassByName('BuiltinPipelineSettings') as any;
    if(!Settings)throw new Error('BuiltinPipelineSettings is missing from the engine build');
    const names=['kawase-bloom','color-grading','fxaa','fsr','depth-of-field'];
    const mats=await Promise.all(names.map(name=>new Promise<Material>((resolve,reject)=>resources.load('ReplayBuiltin-'+name,Material,(error,material)=>error?reject(error):resolve(material)))));
    if(!this.isValid||this.disposed||!this.node.activeInHierarchy)return;
    const settings=this.camera.node.addComponent(Settings) as any;
    settings.kawaseBloomMaterial=mats[0];settings.colorGradingMaterial=mats[1];settings.fxaaMaterial=mats[2];settings.fsrMaterial=mats[3];
    const Dof=js.getClassByName('BuiltinDepthOfFieldPass') as any;
    const dof=Dof?this.camera.node.addComponent(Dof) as any:undefined;
    if(dof){dof.dofMaterial=mats[4];dof.dofEnable=false;}
    const pixels=new Uint8Array(256*16*4);
    for(let g=0;g<16;g++)for(let b=0;b<16;b++)for(let r=0;r<16;r++){const i=(g*256+b*16+r)*4;pixels[i]=70+r*12;pixels[i+1]=g*12;pixels[i+2]=70+b*12;pixels[i+3]=255;}
    const image=new ImageAsset({_data:pixels,width:256,height:16,format:Texture2D.PixelFormat.RGBA8888,_compressed:false});const lut=new Texture2D();lut.image=image;this.images.push(image);this.textures.push(lut);settings.colorGradingMap=lut;
    const cases=['BlitScreen','Bloom','ColorGrading','DOF','FSR','FXAA','HBAO','TAA','TAAMask'];
    const supported=(i:number)=>[1,2,4,5].indexOf(i)>=0||(i===3&&!!dof);
    let index=1,on=false,variant=false,visible=true,capture=false;let privacyMode=0;
    const privacy=this.world.getComponent(ReplayPrivacy)!;
    const hud=this.child(this.node,'IndependentHUD');hud.layer=Layers.Enum.UI_2D;
    const cameraNode=this.child(hud,'HUDCamera');cameraNode.setPosition(0,0,1000);const camera=cameraNode.addComponent(Camera);camera.projection=Camera.ProjectionType.ORTHO;camera.orthoHeight=view.getVisibleSize().height/2;camera.visibility=Layers.Enum.UI_2D;camera.priority=10;camera.clearFlags=Camera.ClearFlag.DEPTH_ONLY;
    const canvas=this.child(hud,'HUDCanvas');canvas.layer=Layers.Enum.UI_2D;const size=view.getVisibleSize();canvas.addComponent(UITransform).setContentSize(size.width,size.height);canvas.addComponent(Canvas).cameraComponent=camera;
    const title=this.label(canvas,'',0,size.height/2-48,size.width-20,86,18);
    const apply=(stage:string)=>{
      if(!supported(index))on=false;
      settings.bloomEnable=on&&index===1;settings.colorGradingEnable=on&&index===2;settings.fsrEnable=on&&index===4;settings.fxaaEnable=on&&index===5;
      settings.bloomThreshold=variant?.8:.1;settings.bloomIntensity=variant?1:4;settings.bloomIterations=3;settings.colorGradingContribute=variant?.2:1;settings.fsrSharpness=variant?0:1;settings.shadingScaleEnable=index===4;settings.shadingScale=index===4?.5:1;
      if(dof){dof.dofEnable=on&&index===3;dof.dofIntensity=variant?1:4;dof.dofBlurRadius=variant?2:6;dof.dofFocusPos=new Vec3(0,0,variant?-2:1);}
      this.world.active=visible;privacy.enabled=privacyMode!==0;privacy.mode=privacyMode===2?ReplayPrivacyMode.Hide:ReplayPrivacyMode.Mask;
      title.string=`BUILTIN POST / ${cases[index]} · enabled:${on} variant:${+variant}\n${supported(index)?stage:'UNSUPPORTED by 3.8.8 Builtin; requires the legacy PostProcess module'} · capture:${capture}`;
      rendering.forceResizeAllWindows();
      console.log('[ReplayPostProcessScene]',JSON.stringify({component:cases[index],stage,supported:supported(index),on,variant,pipeline:'Builtin'}));track(cases[index]!,supported(index)?stage:'unsupported');
    };
    const commands:Array<[string,()=>void]>=[['Next component',()=>{index=(index+1)%cases.length;on=false;variant=false;apply('selected');}],['Effect on / off',()=>{on=!on;apply(on?'enabled':'disabled');}],['Change parameter',()=>{variant=!variant;apply('parameter');}],['SDK capture on / off',()=>{capture=!capture;selectCapture(capture);apply('capture');}],['Hide / show geometry',()=>{visible=!visible;apply('visibility');}],['Privacy default / mask / hide',()=>{privacyMode=(privacyMode+1)%3;apply('privacy');}],['Reset component',()=>{on=false;variant=false;visible=true;privacyMode=0;apply('reset');}],['Back',()=>{this.disposed=true;exit();}]];
    commands.forEach(([text,run],i)=>{const n=this.child(canvas,'PostCommand'+i);n.layer=Layers.Enum.UI_2D;const w=size.width/4-12;n.setPosition((i%4-1.5)*size.width/4,-size.height/2+(i<4?86:28));n.addComponent(UITransform).setContentSize(w,44);const g=n.addComponent(Graphics);g.fillColor=new Color(27,39,64);g.rect(-w/2,-22,w,44);g.fill();n.addComponent(Button).transition=Button.Transition.NONE;n.on('click',()=>{if(!this.disposed)run();});this.label(n,text,0,0,w-8,40,14);});
    apply('entered');
  }
  private child(parent:Node,name:string):Node {const n=new Node(name);n.layer=Layers.Enum.DEFAULT;parent.addChild(n);return n;}
  private label(parent:Node,text:string,x:number,y:number,w:number,h:number,font:number):Label {const n=this.child(parent,'Label');n.layer=Layers.Enum.UI_2D;n.setPosition(x,y);n.addComponent(UITransform).setContentSize(w,h);const l=n.addComponent(Label);l.string=text;l.fontSize=font;l.lineHeight=24;l.color=Color.WHITE;l.horizontalAlign=Label.HorizontalAlign.CENTER;l.verticalAlign=Label.VerticalAlign.CENTER;l.overflow=Label.Overflow.SHRINK;return l;}
  onDestroy():void {this.disposed=true;if(this.previousPipeline){macro.CUSTOM_PIPELINE_NAME=this.previousPipeline;rendering.forceResizeAllWindows();}if(this.taaMask?._mask){this.taaMask.maskCamera!.targetTexture=null;this.taaMask._mask.destroy();}this.settings=[];this.materials.forEach(m=>m.destroy());this.mesh?.destroy();this.textures.forEach(t=>t.destroy());this.images.forEach(i=>i.destroy());}
}
