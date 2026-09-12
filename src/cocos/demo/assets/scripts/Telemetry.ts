import { Camera, Node, sys } from 'cc';
import { guanceSdk as baseSdk, FTAttributes } from '@cloudcare/cocos-sdk/creator3';
import { withSessionReplay } from '@cloudcare/cocos-session-replay/creator3';
import { DemoConfig, sdkConnection, validateConfig } from './Config';

export const sdk = withSessionReplay(baseSdk);
export const platform = () => sys.os === sys.OS.IOS ? 'ios' as const : 'android' as const;

export class Telemetry {
  ready = false;
  message = 'SDK not configured';
  private currentView = '';
  private replayEnabled = false;

  start(config: DemoConfig, camera: Camera): void {
    if (this.ready) return;
    validateConfig(config, platform());
    if (!sys.isNative) { this.message = 'Browser preview · Use Android or iOS for SDK reporting.'; return; }
    try {
      sdk.setReplayCamera(camera);
      sdk.start({
        sdk: { ...sdkConnection(config), serviceName: 'guance_cocos_demo', env: 'common', debug: false,
          globalContext: { demo_platform: platform(), demo_framework: 'cocos', demo_version: '1.0.0', creator_version: '3.8.8' } },
        rum: {
          androidAppId: config.demoAndroidAppId, iosAppId: config.demoIOSAppId, sampleRate: 1,
          enableNativeUserView: false, enableNativeUserAction: false, enableNativeUserResource: false,
          enableNativeCrash: true, enableNativeAnr: true, enableNativeUiBlock: true,
        },
        logger: { sampleRate: 1, enableCustomLog: true, enableLinkRumData: true, printCustomLogToConsole: false },
        trace: { sampleRate: 1, traceType: 'ddTrace', enableLinkRumData: true, enableNativeAutoTrace: false },
        // One Cocos scene hosts multiple pages: give each page a meaningful manual View/Action.
        // XHR collection belongs to Cocos only, to avoid duplicate native Resources.
        autoTrack: { scenes: false, actions: false, network: true, errors: true, console: false },
        ...(config.enableSessionReplay ? { replay: { sampleRate: 1, captureFps: 1, maxImageDimension: 720, touchPrivacy: 'hide' as const } } : {}),
      });
      this.ready = true;
      this.replayEnabled = config.enableSessionReplay;
      this.message = `${config.accessType === 'datakit' ? 'DataKit' : 'DataWay'} · SDK started`;
    } catch {
      try { sdk.shutdown(); } catch { /* Preserve actionable, credential-free startup status. */ }
      this.message = 'SDK startup failed. Check the npm extension and native build logs.';
      throw new Error(this.message);
    }
  }

  view(name: string, scenario: string): void {
    if (!this.ready) return;
    if (this.currentView) sdk.rum.stopView();
    this.currentView = name;
    sdk.rum.startView(name, { demo_scenario: scenario });
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
  replay(start: boolean): void {
    if (!this.ready || !this.replayEnabled) throw new Error('Enable Replay in settings, then restart the app.');
    if (start) sdk.replay.start(); else sdk.replay.stop();
  }
  close(): void {
    if (!this.ready) return;
    if (this.currentView) sdk.rum.stopView();
    sdk.shutdown(); this.ready = false;
  }
}
