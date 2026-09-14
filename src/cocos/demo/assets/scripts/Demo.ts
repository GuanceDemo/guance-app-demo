import {
  _decorator, Camera, Canvas, Color, Component, EditBox, Game, Label, Layers, Node,
  ResolutionPolicy, director, game, profiler, sys, view,
} from 'cc';
import { Api } from './Api';
import { DemoConfig, endpoint, importConfig, readConfig, saveConfig, validateConfig } from './Config';
import { platform, sdk, Telemetry } from './Telemetry';
import { box, button, Page, text, theme } from './UI';
import { GameView } from './GameView';
import { MultiTouchView } from './MultiTouchView';
import { RoundResult } from './GameModel';
import { NativePages, NativePayload } from './NativePages';

const { ccclass } = _decorator;
const BEST_KEY = 'gc_demo_crystal_dash_best_v1';

@ccclass('GuanceCocosDemo')
export class Demo extends Component {
  private root!: Node;
  private camera!: Camera;
  private navigation!: Node;
  private page?: Page;
  private status!: Label;
  private telemetry = new Telemetry();
  private config = readConfig(sys.localStorage);
  private api = new Api(this.config.demoApiAddress, this.telemetry);
  private route = 0;
  private restartRequired = false;
  private replayProbe?: Node;
  private motionTime = 0;
  private nativePages = new NativePages();
  private nativePollTime = 0;
  private lastNativePayload?: NativePayload;
  private activeGame?: GameView;
  private activeMultiTouch?: MultiTouchView;
  private best = 0;
  private backTarget = () => this.home();
  private readonly background = () => { this.activeGame?.pause(); this.activeMultiTouch?.cancelActive(); };

  private systemBack(): void {
    if (!this.root || this.nativePages.pending) return;
    if (this.activeGame) this.activeGame.back();
    else this.backTarget();
  }

  start(): void {
    profiler.hideStats();
    view.setDesignResolutionSize(720, 1280, ResolutionPolicy.SHOW_ALL);
    try { this.best = Math.max(0, Number(sys.localStorage.getItem(BEST_KEY)) || 0); } catch { /* First run. */ }
    const scene = director.getScene()!;
    const cameraNode = box(scene, 'UICamera', 0, 0, 720, 1280);
    cameraNode.setPosition(0, 0, 1000);
    this.camera = cameraNode.addComponent(Camera);
    this.camera.projection = Camera.ProjectionType.ORTHO; this.camera.orthoHeight = 640;
    this.camera.visibility = Layers.Enum.UI_2D; this.camera.clearColor = theme.background;
    const canvasNode = box(scene, 'Canvas', 0, 0, 720, 1280);
    const canvas = canvasNode.addComponent(Canvas); canvas.cameraComponent = this.camera;
    this.root = box(canvasNode, 'DemoUI', 0, 0, 720, 1280);
    text(this.root, 'GUANCE  /  ARCADE', -12, 558, 624, 52, 34);
    text(this.root, 'CRYSTAL DASH   ·   Cocos Creator 3.8.8', -12, 515, 624, 34, 20, theme.muted);
    this.status = text(this.root, '', 0, -497, 644, 58, 19, theme.muted);
    this.navigation = box(this.root, 'Navigation', 0, -565, 664, 66);
    const entries: Array<[string, () => void]> = [
      ['Lobby', () => this.home()], ['Play', () => this.play()],
      ['Lab', () => this.laboratory()], ['Settings', () => this.settings()],
    ];
    entries.forEach(([title, handler], i) => button(this.navigation, title, -252 + i * 168, 0, 154, 66, handler));
    game.on(Game.EVENT_HIDE, this.background);
    try { this.telemetry.start(this.config, this.camera); }
    catch { /* Invalid initial settings are handled by the configuration screen. */ }
    this.home();
  }

  update(dt: number): void {
    this.nativePollTime += dt;
    if (this.nativePollTime >= 0.12) {
      this.nativePollTime = 0;
      if (this.nativePages.consumeBack()) this.systemBack();
      const action = this.nativePages.poll();
      if (action) {
        this.telemetry.action('native_navigation', { destination: action, demo_scenario: 'hybrid_native' });
        if (action === 'play') this.play();
        else if (action === 'lab') this.laboratory();
        else if (action === 'settings') this.settings();
        else if (action === 'unavailable') this.fallback(this.lastNativePayload!);
        else this.home();
      }
    }
    this.activeGame?.update(dt);
    if (this.replayProbe?.isValid) {
      this.motionTime += dt;
      this.replayProbe.setPosition(Math.sin(this.motionTime * 1.4) * 220, 0);
    }
  }

  private show(name: string, scenario = 'navigation', back = () => this.home()): Page {
    this.backTarget = back;
    ++this.route; this.api.cancel(); this.replayProbe = undefined;
    this.activeGame?.destroy(); this.activeGame = undefined;
    this.activeMultiTouch?.destroy(); this.activeMultiTouch = undefined;
    this.navigation.active = true;
    this.page?.destroy(); this.page = new Page(this.root);
    this.telemetry.view(name, scenario);
    this.setStatus(this.restartRequired ? 'Settings saved. Close and reopen the app to apply.' : this.telemetry.message);
    return this.page;
  }
  private setStatus(value: string, failed = false): void {
    this.status.string = value; this.status.color = failed ? theme.danger : theme.muted;
  }
  private guard(operation: () => void): void {
    try { operation(); } catch (error) { this.setStatus(error instanceof Error ? error.message : 'Operation failed', true); }
  }
  private experiment(name: string, operation: () => void): void {
    this.guard(() => {
      if (!this.telemetry.ready) throw new Error('Save your settings, then test the SDK on Android or iOS.');
      this.telemetry.action(name, { demo_scenario: 'experimental' });
      operation();
    });
  }

  private home(): void {
    this.openNative({ page: 'lobby', best: this.best, sdkStatus: this.telemetry.message });
  }
  private openNative(payload: NativePayload): void {
    const page = this.show(payload.page === 'lobby' ? 'NativeGameLobby' : 'NativeRoundResults', 'hybrid_native');
    page.heading('Crystal Dash', 'Opening native screen…');
    this.lastNativePayload = payload;
    if (!this.nativePages.open(payload)) this.fallback(payload);
  }
  private fallback(payload: NativePayload): void {
    const page = this.show('CocosPreviewLobby', 'preview');
    page.heading(payload.page === 'results' ? 'Round complete' : 'Crystal Dash', 'Cocos preview · Native screens require a native build.');
    if (payload.page === 'results') page.note(`Score: ${payload.score} · Gems: ${payload.gems} · Best: ${payload.best}`);
    else page.note('Drag to fly. Collect green gems and dodge red meteors. 45 seconds, 3 shields. Build a streak for bonus points.', 124);
    page.action(payload.page === 'results' ? 'Play again' : 'Play Crystal Dash', () => this.play(), true);
    page.action('SDK experiments', () => this.laboratory());
    page.action('Connection settings', () => this.settings());
    if (sys.isNative) page.note('Native screen unavailable. Rebuild using npm run build:android or build:ios.', 112);
  }
  private play(): void {
    const page = this.show('CocosCrystalDash', 'game'); page.destroy(); this.page = undefined;
    this.navigation.active = false;
    this.telemetry.action('game_start', { demo_scenario: 'game', round_seconds: 45 });
    this.activeGame = new GameView(this.root, result => this.finishRound(result),
      (name, attributes) => this.telemetry.action(name, { ...attributes, demo_scenario: 'game' }), () => this.home());
    this.setStatus('Cocos gameplay · Touch, animation, collision and Replay');
  }
  private finishRound(result: RoundResult): void {
    this.best = Math.max(this.best, result.score);
    try { sys.localStorage.setItem(BEST_KEY, String(this.best)); } catch { /* The round still completes if storage is full. */ }
    this.telemetry.action('game_finish', { ...result, demo_scenario: 'game' });
    this.telemetry.log('Crystal Dash round completed', 'info', { ...result, best: this.best });
    this.openNative({ page: 'results', ...result, best: this.best, sdkStatus: this.telemetry.message });
  }

  private settings(draft = readConfig(sys.localStorage)): void {
    const page = this.show('CocosSettings', 'configuration');
    // Includes endpoint/token/App ID and imported payload, including while scrolling.
    this.telemetry.protect(page.node);
    page.heading('Demo settings', 'Import shared settings and save them on this device.');
    const imported = page.field('gc-demo:// string or JSON', '', false, true);
    page.action('Import settings', () => this.guard(() => {
      this.settings(importConfig(imported.string, draft)); this.setStatus('Settings imported. Review them, then save.');
    }));
    page.pair(draft.accessType === 'datakit' ? '● DataKit' : 'DataKit', draft.accessType === 'dataway' ? '● DataWay' : 'DataWay',
      () => this.settings({ ...collect(), accessType: 'datakit' }), () => this.settings({ ...collect(), accessType: 'dataway' }));
    const fields: Partial<Record<keyof DemoConfig, EditBox>> = {};
    fields.demoAndroidAppId = page.field('Android App ID', draft.demoAndroidAppId);
    fields.demoIOSAppId = page.field('iOS App ID', draft.demoIOSAppId);
    if (draft.accessType === 'datakit') fields.datakitAddress = page.field('DataKit URL', draft.datakitAddress);
    else {
      fields.datawayAddress = page.field('DataWay URL', draft.datawayAddress);
      fields.datawayClientToken = page.field('DataWay Client Token', draft.datawayClientToken, true);
    }
    fields.demoApiAddress = page.field('Demo API URL', draft.demoApiAddress);
    const collect = (): DemoConfig => {
      const next = { ...draft };
      for (const key of Object.keys(fields) as Array<keyof typeof fields>) {
        if (key !== 'accessType' && key !== 'enableSessionReplay') next[key] = fields[key]!.string.trim();
      }
      return next;
    };
    page.action(`Session Replay: ${draft.enableSessionReplay ? 'On' : 'Off'} (tap to toggle)`,
      () => this.settings({ ...collect(), enableSessionReplay: !draft.enableSessionReplay }));
    page.action('Check connection', () => void this.checkConnections(collect()));
    page.action('Save settings', () => this.guard(() => {
      const next = collect(); saveConfig(sys.localStorage, next, platform());
      if (this.telemetry.ready) { this.restartRequired = true; this.home(); }
      else {
        this.config = next; this.api.base = next.demoApiAddress;
        this.telemetry.start(next, this.camera); this.home();
      }
    }), true);
    page.note('Only this platform needs an App ID. Restart the app after changing active SDK settings. Use the system Paste command to paste text.', 138);
  }

  private async checkConnections(config: DemoConfig): Promise<void> {
    const route = this.route;
    try {
      validateConfig(config, platform()); this.setStatus('Checking Demo API and collector…');
      // Raw XHR bypass prevents the DataWay token from entering Resource/Trace records.
      const collector = config.accessType === 'datakit'
        ? endpoint(config.datakitAddress, '/v1/ping')
        : endpoint(config.datawayAddress, '/v1/write/logging?token=' + encodeURIComponent(config.datawayClientToken) + '&to_headless=true');
      const demo = await this.api.request(endpoint(config.demoApiAddress, '/connect'), { untracked: true });
      if (route !== this.route) return;
      const report = await this.api.request(collector, {
        untracked: true, method: config.accessType === 'datakit' ? 'GET' : 'POST',
        ...(config.accessType === 'dataway' ? { rawBody: `df_rum_cocos_log message="connect test" ${Date.now()}000000` } : {}),
      });
      if (route !== this.route) return;
      const ok = demo.status >= 200 && demo.status < 300 && report.status >= 200 && report.status < 300;
      this.setStatus(`Demo API: HTTP ${demo.status} · ${config.accessType}: HTTP ${report.status}${ok ? ' · Connected' : ' · Check the URL or token'}`, !ok);
    } catch (error) { if (route === this.route) this.setStatus((error as Error).message, true); }
  }

  private laboratory(): void {
    const page = this.show('CocosLaboratory', 'experimental');
    page.heading('SDK lab', 'Inspect gameplay, performance and telemetry.');
    page.action('Play · Game events and Replay', () => this.play(), true);
    page.action('Session Replay · Multi-touch playground', () => this.multiTouchPage());
    page.note('Native lobby → Cocos game → native results. Each screen has its own RUM View. Cocos Replay captures the game; native screens are outside its camera.', 128);
    page.note('Results show local calls or HTTP responses. Check Guance for collected data. Play a round to inspect game events and replay.', 110);
    page.action('RUM · Custom View and Action', () => this.customView());
    page.action('Log · Send all five levels', () => this.experiment('lab_logs', () => {
      for (const level of ['info', 'warning', 'error', 'critical', 'ok']) this.telemetry.log('Cocos demo log: ' + level, level, { demo_scenario: 'experimental' });
      this.setStatus('Called all five log levels, linked to the current RUM View.');
    }));
    page.action('Error · Report a caught exception', () => this.experiment('lab_caught_error', () => {
      const error = new Error('Cocos laboratory caught error');
      sdk.rum.addError(error.message, error.stack ?? '', 'cocos_demo_error', 'run', { demo_scenario: 'experimental' });
      this.setStatus('Error API called. You can continue using the demo.');
    }));
    page.action('Error · Uncaught async JS exception', () => this.experiment('lab_uncaught_error', () => {
      this.setStatus('An async error will be thrown. Check automatic collection.');
      setTimeout(() => { throw new Error('Cocos laboratory uncaught async error'); }, 100);
    }));
    page.action('LongTask · Block JS for ~250ms', () => this.experiment('lab_long_task', () => {
      const stack = new Error('Cocos demo bounded busy task').stack ?? '';
      const start = Date.now(); while (Date.now() - start < 250) { /* Deliberately bounded experiment. */ }
      const durationMs = Date.now() - start;
      sdk.rum.addLongTask(stack, durationMs * 1e6, { demo_scenario: 'experimental' });
      this.setStatus(`Blocked for ${durationMs}ms. LongTask API called.`);
    }));
    page.action('Network · Auto XHR + Trace (success)', () => void this.networkProbe(false, false));
    page.action('Network · Auto XHR (HTTP 404)', () => void this.networkProbe(false, true));
    page.action('Network · Manual Resource + Trace', () => void this.networkProbe(true, false));
    page.action('Session Replay · Motion and privacy', () => this.replayPage());
    page.action('Hybrid · Open native game lobby', () => this.home());
    page.note('Native Crash / ANR / UI Block collection is enabled. These Error and LongTask tests run in Cocos JS and do not crash the native process.', 110);
  }

  private customView(): void {
    const page = this.show('CocosCustomExperimentView', 'experimental', () => this.laboratory());
    page.heading('Custom RUM View', 'Calls startView on entry and stopView on exit.');
    page.action('Send custom Action', () => this.experiment('custom_business_action', () => this.setStatus('addAction called')));
    page.action('Back to lab', () => this.laboratory());
  }

  private async networkProbe(manual: boolean, failure: boolean): Promise<void> {
    if (!this.config.demoApiAddress) { this.setStatus('Set the Demo API URL first.', true); return; }
    const route = this.route;
    this.telemetry.action(manual ? 'lab_manual_resource' : 'lab_auto_resource', { expected_failure: failure });
    this.setStatus('Running network test…');
    const path = failure ? '/api/products/cocos-demo-missing-product' : '/api/version';
    try {
      const response = await this.api.request(endpoint(this.config.demoApiAddress, path), { manual });
      if (route === this.route) this.setStatus(`${manual ? 'Manual' : 'Auto'}: HTTP ${response.status}. Check one Resource and its Trace link.`);
    } catch (error) { if (route === this.route) this.setStatus((error as Error).message, true); }
  }

  private replayPage(): void {
    const page = this.show('CocosReplayExperiment', 'experimental', () => this.laboratory());
    page.heading('Replay and privacy', 'Compare motion, text and masks with the recorded replay.');
    page.action('Open multi-touch playground', () => this.multiTouchPage(() => this.replayPage()));
    page.note('With Replay enabled, the blue block and public text stay visible. The red test data and input field should be masked.', 110);
    const row = page.row(128, 'ReplayMotion', theme.paper);
    this.replayProbe = box(row, 'MovingBlock', 0, 0, 80, 80, theme.primary);
    text(page.row(64), 'Public text: visible in replay', 0, 0, 620, 64, 26);
    const privateNode = page.row(96, 'PrivateProbe', new Color(252, 224, 228));
    text(privateNode, 'Test only: PRIVATE-314159', 0, 0, 588, 72, 26, theme.danger);
    this.telemetry.protect(privateNode);
    const input = page.field('Private test input', 'demo-private-value'); this.telemetry.protect(input.node);
    page.pair('Pause replay', 'Resume replay', () => this.experiment('replay_stop', () => {
      this.telemetry.replay(false); this.setStatus('Replay paused');
    }), () => this.experiment('replay_start', () => {
      this.telemetry.replay(true); this.setStatus('Replay resumed');
    }));
    page.action('Back to lab', () => this.laboratory());
  }

  private multiTouchPage(back = () => this.laboratory()): void {
    const page = this.show('CocosMultiTouchReplay', 'multitouch_replay', back); page.destroy(); this.page = undefined;
    this.activeMultiTouch = new MultiTouchView(this.root,
      (name, attributes) => this.telemetry.action(name, { ...attributes, demo_scenario: 'multitouch_replay' }),
      back);
  }

  onDestroy(): void {
    game.off(Game.EVENT_HIDE, this.background);
    this.activeMultiTouch?.destroy();
    this.activeGame?.destroy(); this.api.cancel(); this.page?.destroy(); this.telemetry.close();
  }
}
