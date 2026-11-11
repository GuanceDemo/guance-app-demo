import { native, sys, view } from './Engine';
interface Area { x: number; y: number; width: number; height: number }

/** Include Android system bars, which Creator's cutout-only safe area omits. */
export function safeAreaRect(): Area {
  const engine = sys.getSafeAreaRect();
  if (!sys.isNative || sys.os !== sys.OS_ANDROID) return engine;
  try {
    const raw = native.reflection.callStaticMethod('com/guance/cocos/demo/NativeGameBridge','safeArea','()Ljava/lang/String;');
    if (typeof raw !== 'string' || !raw) return engine;
    const edge = JSON.parse(raw) as { left: number; top: number; right: number; bottom: number };
    if (![edge.left,edge.top,edge.right,edge.bottom].every(value=>Number.isFinite(value)&&value>=0&&value<1) || edge.left+edge.right>=1 || edge.top+edge.bottom>=1) return engine;
    const frame=view.getFrameSize(),design=view.getDesignResolutionSize(),ratio=view.getDevicePixelRatio();
    const width=frame.width*ratio/view.getScaleX(),height=frame.height*ratio/view.getScaleY();
    if (!(width>0 && height>0 && Number.isFinite(width) && Number.isFinite(height))) return engine;
    const left=design.width/2-width/2+edge.left*width,bottom=design.height/2-height/2+edge.bottom*height;
    const right=design.width/2+width/2-edge.right*width,top=design.height/2+height/2-edge.top*height;
    const x=Math.max(engine.x,left),y=Math.max(engine.y,bottom);
    return {x,y,width:Math.max(0,Math.min(engine.x+engine.width,right)-x),height:Math.max(0,Math.min(engine.y+engine.height,top)-y)};
  } catch { return engine; }
}
