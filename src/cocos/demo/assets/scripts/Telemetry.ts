import { Camera, Node, sys } from 'cc';
import { guanceSdk as baseSdk, FTAttributes } from '@cloudcare/cocos-sdk/creator3';
import { withSessionReplay } from '@cloudcare/cocos-session-replay/creator3';
import { DemoConfig, sdkReplay, validateConfig } from './Config';
import { nativeHost } from './NativeHost';

export const sdk = withSessionReplay(baseSdk);
export const platform = () => sys.os === sys.OS.IOS ? 'ios' as const : 'android' as const;

export class Telemetry {
  ready = false;
  message = 'SDK not configured';
  private currentView = '';
  private entered = false;

  start(config: DemoConfig, camera: Camera): void {
    if (this.ready) return;
    if (!config.enableSdk) { this.message = 'SDK disabled'; return; }
    if (!sys.isNative) { this.message = 'Browser preview · Use Android or iOS for SDK reporting.'; return; }
    validateConfig(config, platform());
    try {
      // Usually initialized at native app launch. This also handles first setup / migration.
      nativeHost.initialize(config);
      sdk.setReplayCamera(camera);
      sdk.attach({
        autoTrack: { scenes: false, actions: false, network: config.enableAutoResource,
          errors: config.enableAutoError, console: false },
        ...(config.enableSessionReplay ? { replay: sdkReplay(config) } : {}),
      });
      this.ready = true;
      this.message = `${config.accessType === 'datakit' ? 'DataKit' : 'DataWay'} · Native SDK / Cocos attached`;
    } catch {
      this.message = 'Hybrid attachment failed. Check native SDK initialization and rebuild the app.';
      // Never shut down a host-owned SDK, including after a failed attach.
      throw new Error(this.message);
    }
  }

  view(name: string, scenario: string): void {
    if (!this.ready) return;
    if (!this.entered) {
      sdk.enterCocos({ viewName: name });
      this.entered = true;
    } else if (this.currentView !== name) {
      sdk.rum.stopView();
      sdk.rum.startView(name, { demo_scenario: scenario });
    }
    this.currentView = name;
  }
  leave(): void {
    if (!this.ready || !this.entered) return;
    sdk.leaveCocos();
    this.entered = false; this.currentView = '';
  }

  action(name: string, attributes: FTAttributes = {}): void {
    if (this.ready) sdk.rum.addAction(name, 'click', attributes);
  }
  log(message: string, level = 'info', attributes: FTAttributes = {}): void {
    if (this.ready) sdk.logger.log(message, level, attributes);
  }
  bind(username: string): void {
    if (this.ready) sdk.mobile.bindUser({ userId: username, userName: username });
  }
  unbind(): void { if (this.ready) sdk.mobile.unbindUser(); }
  protect(node: Node): void { sdk.replay.setPrivacy(node, 'mask'); }
  /** Disposing Cocos releases capture and hooks; the native SDK keeps running. */
  close(): void { this.leave(); }
  disable(): boolean {
    this.leave();
    const restartRequired = sys.isNative ? nativeHost.disable() : false;
    this.ready = false; this.message = 'SDK disabled';
    return restartRequired;
  }
}
