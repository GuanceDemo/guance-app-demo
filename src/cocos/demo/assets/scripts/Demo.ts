import {
  _decorator, Button, Camera, Canvas, Color, Component, EditBox, Label, Layers, Node,
  ResolutionPolicy, UITransform, WebView, director, sys, view,
} from 'cc';
import { Api, Product } from './Api';
import { DemoConfig, endpoint, importConfig, isHttpUrl, readConfig, saveConfig, validateConfig } from './Config';
import { platform, sdk, Telemetry } from './Telemetry';
import { box, button, Page, text, theme } from './UI';

const { ccclass } = _decorator;

@ccclass('GuanceCocosDemo')
export class Demo extends Component {
  private root!: Node;
  private camera!: Camera;
  private page?: Page;
  private status!: Label;
  private telemetry = new Telemetry();
  private config = readConfig(sys.localStorage);
  private api = new Api(this.config.demoApiAddress, this.telemetry);
  private route = 0;
  private username = '';
  private restartRequired = false;
  private favorites = new Set<string>();
  private cart = new Map<string, { product: Product; quantity: number }>();
  private replayProbe?: Node;
  private motionTime = 0;
  private web?: Node;

  start(): void {
    view.setDesignResolutionSize(720, 1280, ResolutionPolicy.SHOW_ALL);
    const scene = director.getScene()!;
    const cameraNode = box(scene, 'UICamera', 0, 0, 720, 1280);
    cameraNode.setPosition(0, 0, 1000);
    this.camera = cameraNode.addComponent(Camera);
    this.camera.projection = Camera.ProjectionType.ORTHO; this.camera.orthoHeight = 640;
    this.camera.visibility = Layers.Enum.UI_2D; this.camera.clearColor = theme.background;
    const canvasNode = box(scene, 'Canvas', 0, 0, 720, 1280);
    const canvas = canvasNode.addComponent(Canvas); canvas.cameraComponent = this.camera;
    this.root = box(canvasNode, 'DemoUI', 0, 0, 720, 1280);
    text(this.root, 'GUANCE  /  COCOS', -12, 558, 624, 52, 34);
    text(this.root, 'Creator 3.8.8   ·   Android & iOS', -12, 515, 624, 34, 21, theme.muted);
    this.status = text(this.root, '', 0, -497, 644, 58, 21, theme.muted);
    const entries: Array<[string, () => void]> = [
      ['Home', () => this.home()], ['Explore', () => this.username ? this.products() : this.login()],
      ['Lab', () => this.laboratory()], ['Profile', () => this.mine()],
    ];
    entries.forEach(([title, handler], i) => button(this.root, title, -252 + i * 168, -565, 154, 66, handler));
    try { this.telemetry.start(this.config, this.camera); }
    catch { /* Invalid initial settings are handled by the configuration screen. */ }
    this.home();
  }

  update(dt: number): void {
    if (this.replayProbe?.isValid) {
      this.motionTime += dt;
      this.replayProbe.setPosition(Math.sin(this.motionTime * 1.4) * 220, 0);
    }
  }

  private show(name: string, scenario = 'navigation'): Page {
    ++this.route; this.api.cancel(); this.replayProbe = undefined;
    if (this.web) { this.web.active = false; this.web.destroy(); this.web = undefined; }
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
    const page = this.show('CocosHome');
    page.heading('Start exploring', 'Browse products, then test data collection in the lab.');
    const hero = page.row(174, 'Hero', theme.primary);
    text(hero, 'One demo. Two platforms.', 0, 38, 588, 64, 36, theme.paper);
    text(hero, 'RUM · Log · Trace · Session Replay\nShared backend and settings', 0, -36, 588, 82, 24, theme.paper);
    page.action('Explore  →  Sign in and browse', () => this.username ? this.products() : this.login(), true);
    page.action('Lab  →  Test SDK features', () => this.laboratory());
    page.action('Demo settings', () => this.settings());
    page.note(this.telemetry.message);
    page.note('First run: open /import_helper on your server. Copy the gc-demo:// string, then paste and save it in Demo settings.', 112);
    page.note('SDK 0.1.0-alpha.6 · npm integration\nAndroid: APK distribution · iOS: TestFlight', 100);
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

  private login(): void {
    const page = this.show('CocosLogin', 'real');
    page.heading('Welcome back', 'Sign in with the Demo API to link your RUM user.');
    if (!this.config.demoApiAddress) {
      page.note('Set the Demo API URL and SDK connection first.');
      page.action('Open settings', () => this.settings(), true); return;
    }
    const user = page.field('Username', 'guance');
    const password = page.field('Password', 'admin', true);
    this.telemetry.protect(password.node); this.telemetry.protect(user.node);
    let submitting = false;
    const submit = page.action('Sign in', () => {
      if (submitting) return;
      const username = user.string.trim();
      if (!username || !password.string) { this.setStatus('Enter your username and password.', true); return; }
      submitting = true; submit.getComponent(Button)!.interactable = false;
      const route = this.route;
      this.telemetry.action('login_submit', { demo_scenario: 'real' });
      this.setStatus('Signing in…');
      this.api.login(username, password.string).then(result => {
        if (route !== this.route) return;
        if (!result.success) throw new Error('Sign-in failed');
        this.username = username; this.telemetry.bind(username);
        this.telemetry.log('Demo login succeeded', 'info', { demo_scenario: 'real' });
        this.products();
      }).catch(error => { if (route === this.route) this.setStatus(error.message, true); })
        .finally(() => { if (route === this.route) { submitting = false; submit.getComponent(Button)!.interactable = true; } });
    }, true);
    page.note('Test account: guance / admin\nSign-in lasts for this session. Passwords are not saved.', 98);
    page.action('Demo settings', () => this.settings());
  }

  private products(): void {
    const page = this.show('CocosProductList', 'real');
    page.heading('Discover products', 'Browse images, refresh the feed and open product details.');
    page.pair('Refresh', 'Cart', () => { this.telemetry.action('product_feed_refresh'); this.products(); }, () => this.cartPage());
    const loading = page.note('Loading products…');
    const route = this.route;
    this.api.products().then(products => {
      if (route !== this.route) return;
      loading.string = products.length ? `${products.length} products · Tap to view details` : 'No products yet. Tap Refresh to try again.';
      for (const product of products) {
        const row = page.row(206, product.id, theme.paper);
        page.image(row, this.imageUrl(product.image_url), -222, 8, 154, 150);
        text(row, product.title, 84, 58, 390, 56, 28);
        text(row, product.price + '   ·   ' + product.rating, 84, 6, 390, 40, 24, theme.primary);
        button(row, 'View details  →', 84, -58, 388, 55, () => {
          this.telemetry.action('product_open', { product_id: product.id }); this.detail(product.id);
        });
      }
    }).catch(error => { if (route === this.route) { loading.string = 'Could not load: ' + error.message; this.setStatus('Tap Refresh to try again.', true); } });
  }

  private imageUrl(url: string): string {
    return isHttpUrl(url) ? url : endpoint(this.config.demoApiAddress, url);
  }

  private detail(id: string): void {
    const page = this.show('CocosProductDetail', 'real');
    page.action('← Back to products', () => this.products());
    const loading = page.note('Loading product details…');
    const route = this.route;
    this.api.product(id).then(product => {
      if (route !== this.route) return;
      loading.string = product.tag + '  ·  ' + (product.stock ?? '');
      const image = page.row(310, 'ProductHero', theme.paper);
      page.image(image, this.imageUrl(product.image_url), 0, 0, 500, 290);
      page.heading(product.title, product.price + '   ·   ' + product.rating);
      page.note(product.description ?? product.subtitle, 160);
      if (product.highlights?.length) page.note(product.highlights.join('\n'), 180);
      page.pair(this.favorites.has(id) ? 'Remove favorite' : 'Add favorite', 'Add to cart', () => {
        if (this.favorites.has(id)) this.favorites.delete(id); else this.favorites.add(id);
        this.telemetry.action('product_favorite', { product_id: id, favorited: this.favorites.has(id) });
        this.setStatus(this.favorites.has(id) ? 'Added to favorites. Tap to remove.' : 'Removed from favorites');
      }, () => {
        const previous = this.cart.get(id); const quantity = (previous?.quantity ?? 0) + 1;
        this.cart.set(id, { product, quantity });
        this.telemetry.action('cart_add', { product_id: id, quantity });
        this.setStatus('Added to demo cart. Quantity: ' + quantity);
      });
      page.action('Open product web page', () => this.webPage('/product/' + encodeURIComponent(id), () => this.detail(id)));
      page.action('View cart', () => this.cartPage(), true);
    }).catch(error => {
      if (route !== this.route) return;
      loading.string = 'Could not load: ' + error.message; page.action('Retry', () => this.detail(id));
    });
  }

  private cartPage(): void {
    const page = this.show('CocosCart', 'real');
    page.heading('Demo cart', 'Test cart actions locally. No orders or payments are created.');
    if (!this.cart.size) page.note('Your cart is empty. Browse products to add an item.');
    for (const [id, { product, quantity }] of this.cart) {
      page.note(product.title + '\n' + product.price + ' × ' + quantity, 98);
      page.pair('Quantity −1', 'Quantity +1', () => {
        if (quantity === 1) this.cart.delete(id); else this.cart.set(id, { product, quantity: quantity - 1 });
        this.telemetry.action('cart_quantity_change', { product_id: id, quantity: quantity - 1 }); this.cartPage();
      }, () => {
        this.cart.set(id, { product, quantity: quantity + 1 });
        this.telemetry.action('cart_quantity_change', { product_id: id, quantity: quantity + 1 }); this.cartPage();
      });
    }
    page.action('Continue browsing', () => this.products(), true);
  }

  private mine(): void {
    const page = this.show('CocosMine', 'real');
    page.heading('Profile', this.username ? 'Signed in as: ' + this.username : 'Sign in to view your profile.');
    this.telemetry.protect(page.node);
    if (this.username) {
      const profile = page.note('Loading profile…', 124);
      const route = this.route;
      this.api.user().then(user => {
        if (route === this.route) profile.string = `${user.username}\n${user.email}\nFavorites: ${this.favorites.size}`;
      }).catch(error => { if (route === this.route) profile.string = error.message; });
      page.action('Refresh profile', () => { this.telemetry.action('profile_refresh'); this.mine(); });
      page.action('Sign out', () => {
        this.telemetry.action('logout'); this.telemetry.unbind(); this.username = ''; this.cart.clear(); this.favorites.clear(); this.login();
      });
    } else page.action('Sign in', () => this.login(), true);
    page.action('Demo settings', () => this.settings());
    page.note('Cocos Creator 3.8.8\nGuance SDK / Replay 0.1.0-alpha.6\nDemo 1.0.0', 140);
  }

  private laboratory(): void {
    const page = this.show('CocosLaboratory', 'experimental');
    page.heading('SDK lab', 'Run an experiment to test each SDK feature.');
    page.note('Results show local calls or HTTP responses. Check Guance for collected data. Network tests use the same Demo API as Explore.', 110);
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
    page.action('WebView · Demo web page', () => this.webPage('/', () => this.laboratory()));
    page.note('Native Crash / ANR / UI Block collection is enabled. These Error and LongTask tests run in Cocos JS and do not crash the native process.', 110);
  }

  private customView(): void {
    const page = this.show('CocosCustomExperimentView', 'experimental');
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
    const page = this.show('CocosReplayExperiment', 'experimental');
    page.heading('Replay and privacy', 'Compare motion, text and masks with the recorded replay.');
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

  private webPage(path: string, back: () => void): void {
    const page = this.show('CocosWebView', 'real');
    page.heading('Web demo', 'Cocos tracks the View. The web page manages its own telemetry.');
    page.action('← Back', back);
    if (!this.config.demoApiAddress) { page.note('Set the Demo API URL first.'); return; }
    // Native WebView is an overlay: keep it below the back button and above the tab bar.
    this.web = box(this.root, 'NativeWebView', 0, -155, 640, 580);
    const web = this.web.addComponent(WebView); const route = this.route;
    this.web.on(WebView.EventType.LOADED, () => { if (route === this.route) this.setStatus('Web page loaded'); });
    this.web.on(WebView.EventType.ERROR, () => { if (route === this.route) this.setStatus('Web page failed to load. Go back and check the URL.', true); });
    web.url = endpoint(this.config.demoApiAddress, path);
    this.setStatus('Loading web page. The native WebView is outside Replay capture.');
  }

  onDestroy(): void { this.api.cancel(); this.page?.destroy(); this.telemetry.close(); }
}
