import { native, sys } from 'cc';
export type NativeAction = 'play' | 'lab' | 'settings' | 'lobby' | 'unavailable';
export type NativePage = 'lobby' | 'results';
export interface NativePayload { page: NativePage; best: number; sdkStatus: string; score?: number; gems?: number; duration?: number; reason?: string; }

/** Reflection opens real platform screens; a one-shot mailbox returns navigation to Cocos. */
export class NativePages {
  private request = 0;
  pending = false;
  consumeBack(): boolean {
    if (this.pending || !sys.isNative || sys.os !== sys.OS.ANDROID) return false;
    try {
      return native.reflection.callStaticMethod('com/guance/cocos/demo/NativeGameBridge', 'consumeBack', '()Z') === true;
    } catch { return false; }
  }
  private call(method: 'show' | 'consumeAction', value?: string): unknown {
    if (sys.os === sys.OS.ANDROID) return method === 'show'
      ? native.reflection.callStaticMethod('com/guance/cocos/demo/NativeGameBridge', 'show', '(Ljava/lang/String;)V', value!)
      : native.reflection.callStaticMethod('com/guance/cocos/demo/NativeGameBridge', 'consumeAction', '()Ljava/lang/String;');
    return method === 'show'
      ? native.reflection.callStaticMethod('GCNativeGameBridge', 'show:', value!)
      : native.reflection.callStaticMethod('GCNativeGameBridge', 'consumeAction:', '');
  }
  open(payload: NativePayload): boolean {
    if (!sys.isNative || (sys.os !== sys.OS.ANDROID && sys.os !== sys.OS.IOS)) return false;
    try {
      this.call('show', JSON.stringify({ ...payload, requestId: ++this.request }));
      this.pending = true;
      return true;
    } catch { this.pending = false; return false; }
  }
  poll(): NativeAction | undefined {
    if (!this.pending) return;
    try {
      const raw = this.call('consumeAction');
      if (typeof raw !== 'string' || !raw) return;
      const event = JSON.parse(raw);
      if (event.requestId !== this.request) return;
      if (!['play', 'lab', 'settings', 'lobby', 'unavailable'].includes(event.action)) return;
      this.pending = false;
      return event.action as NativeAction;
    } catch { this.pending = false; return 'unavailable'; }
  }
}
