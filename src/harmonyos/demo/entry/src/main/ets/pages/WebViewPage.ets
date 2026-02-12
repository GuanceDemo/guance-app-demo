import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { FTWebViewHandler } from 'ft_sdk/src/main/ets/components/web/FTWebViewHandler';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';
import { FTSDK } from 'ft_sdk/src/main/ets/components/FTSDK';

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
      // Title bar
      Row() {
        // Back arrow
        Image($r('app.media.arrow_left'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text(this.webTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Refresh button
        Text('\uE645')
          .fontSize(24)
          .fontColor('#FF6600')
          .onClick(() => {
            this.refresh();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Progress bar
      if (this.isLoading) {
        Progress({ value: 50, total: 100 })
          .width('100%')
          .height(2)
          .color('#FF6600')
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
