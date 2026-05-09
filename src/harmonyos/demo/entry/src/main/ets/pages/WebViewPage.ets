import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { FTWebViewHandler } from '@guancecloud/ft_sdk/src/main/ets/components/web/FTWebViewHandler';
import { FTLogger } from '@guancecloud/ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from '@guancecloud/ft_sdk/src/main/ets/components/bean/Status';
import { FTSDK } from '@guancecloud/ft_sdk/src/main/ets/components/FTSDK';
import { AppColors } from '../constants/UIConstants';
import { AppNavBar } from '../components/AppNavBar';

/**
 * WebView page - Supports WebView RUM monitoring
 */
@Entry
@Component
struct WebViewPage {
  @State webTitle: string = 'WebView';
  @State isLoading: boolean = true;
  @State url: string = '';
  private webViewController: webview.WebviewController = new webview.WebviewController();
  private webViewHandler: FTWebViewHandler = new FTWebViewHandler();

  aboutToAppear(): void {
    // Set up WebView Handler for RUM data collection within WebView
    // Get current RUM configuration
    const rumConfig = FTSDK.getRumConfig();
    if (rumConfig && this.webViewController) {
      this.webViewHandler.setWebView(this.webViewController, rumConfig);
    }

    this.loadUrl();
  }

  aboutToDisappear(): void {
    // Clean up WebViewController
    this.webViewHandler.clearWebController();
  }

  build() {
    Column() {
      AppNavBar({
        title: this.webTitle,
        showBack: true,
        rightText: '\uE645',
        onBack: () => {
          router.back();
        },
        onRightClick: () => {
          this.refresh();
        }
      })

      // Progress bar
      if (this.isLoading) {
        Progress({ value: 50, total: 100 })
          .width('100%')
          .height(2)
          .color(AppColors.PRIMARY)
      }

      // WebView
      Web({ src: this.url, controller: this.webViewController })
        .width('100%')
        .layoutWeight(1)
        .domStorageAccess(true)
        .javaScriptAccess(true)
        .javaScriptProxy(this.webViewHandler.getJavaScriptProxy(this.webViewController))
        .onPageBegin(() => {
          this.isLoading = true;
          // Log page start loading (using static method)
          FTLogger.logBackground('WebView page begin loading: ' + this.url, Status.INFO);
        })
        .onPageEnd(() => {
          this.isLoading = false;
          // Log page load complete (using static method)
          FTLogger.logBackground('WebView page loaded: ' + this.webTitle, Status.INFO);
        })
        .onErrorReceive((event) => {
          this.isLoading = false;
          console.error('WebView error:', JSON.stringify(event));
          // Log error (using static method)
          FTLogger.logBackground('WebView error: ' + JSON.stringify(event), Status.ERROR);
        })
        .onTitleReceive((event) => {
          if (event.title) {
            this.webTitle = event.title;
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * Load URL
   */
  async loadUrl(): Promise<void> {
    try {
      let params: Record<string, string> = {};
      const routerParams = router.getParams();
      if (routerParams) {
        params = routerParams as Record<string, string>;
      }
      if (params['url']) {
        this.url = params['url'];
        this.webTitle = params['title'] ?? this.webTitle;
        console.info('Loading WebView URL from params:', this.url);
        return;
      }

      const setting = await SettingConfigManager.readSetting();
      // Build URL with user information
      this.url = `${setting.demoApiAddress}?requestUrl=${setting.getUserInfoUrl()}`;
      console.info('Loading WebView URL:', this.url);
    } catch (err) {
      console.error('Failed to load URL:', JSON.stringify(err));
      this.url = 'about:blank';
      FTLogger.logBackground('Failed to load WebView URL: ' + JSON.stringify(err), Status.ERROR);
    }
  }

  /**
   * Refresh page
   */
  refresh(): void {
    this.webViewController.refresh();
  }
}
