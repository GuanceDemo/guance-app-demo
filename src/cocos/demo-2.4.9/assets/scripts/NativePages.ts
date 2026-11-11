import { DemoConfig, SettingField } from './Config';
import { native, sys } from './Engine';
export type NativeAction = 'play' | 'controls' | 'lab' | 'settings' | 'lobby' | 'unavailable' | 'settings-save' | 'settings-import' | 'settings-check';
export type NativePage = 'lobby' | 'results' | 'settings';
export interface NativePayload { page: NativePage; best: number; sdkStatus: string; score?: number; gems?: number; duration?: number; reason?: string; config?: DemoConfig; fields?: SettingField[]; settingsMessage?: string; }

/** Reflection opens real platform screens; a one-shot mailbox returns navigation to Cocos. */
export class NativePages {
  private request = 0;
  private controlsRotation = false;
  setControlsRotation(enabled: boolean): void {
    if (!sys.isNative || this.controlsRotation === enabled) return;
    try {
      if (sys.os === sys.OS_ANDROID) native.reflection.callStaticMethod('com/guance/cocos/demo/NativeGameBridge','setControlsRotation','(Z)V',enabled);
      else if (sys.os === sys.OS_IOS) native.reflection.callStaticMethod('GCSceneDelegate','setControlsRotation:',enabled?'true':'false');
      else return;
      this.controlsRotation = enabled;
    } catch { /* Browser and projects without the app bridge keep their existing orientation. */ }
  }

  pending = false;
  settingsResult?: { config: unknown; importText?: string };
  consumeBack(): boolean {
    if (this.pending || !sys.isNative || sys.os !== sys.OS_ANDROID) return false;
    try {
      return native.reflection.callStaticMethod('com/guance/cocos/demo/NativeGameBridge', 'consumeBack', '()Z') === true;
    } catch { return false; }
  }
  private call(method: 'show' | 'consumeAction', value?: string): unknown {
    if (sys.os === sys.OS_ANDROID) return method === 'show'
      ? native.reflection.callStaticMethod('com/guance/cocos/demo/NativeGameBridge', 'show', '(Ljava/lang/String;)V', value!)
      : native.reflection.callStaticMethod('com/guance/cocos/demo/NativeGameBridge', 'consumeAction', '()Ljava/lang/String;');
    return method === 'show'
      ? native.reflection.callStaticMethod('GCNativeGameBridge', 'show:', value!)
      : native.reflection.callStaticMethod('GCNativeGameBridge', 'consumeAction:', '');
  }
  open(payload: NativePayload): boolean {
    if (!sys.isNative || (sys.os !== sys.OS_ANDROID && sys.os !== sys.OS_IOS)) return false;
    this.settingsResult = undefined;
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
      if (!['play', 'controls', 'lab', 'settings', 'lobby', 'unavailable', 'settings-save', 'settings-import', 'settings-check'].includes(event.action)) return;
      if (event.action.startsWith('settings-')) this.settingsResult = { config: event.config, importText: event.importText };
      this.pending = false;
      return event.action as NativeAction;
    } catch { this.pending = false; return 'unavailable'; }
  }
}
