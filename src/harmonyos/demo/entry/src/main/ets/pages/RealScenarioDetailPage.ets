import { router, promptAction } from '@kit.ArkUI';
import { HttpEngine } from '../http/HttpEngine';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { AccountManager } from '../manager/AccountManager';
import { ProductDetail, ProductSpec } from '../model/ProductData';
import { AppColors, FontSizes, Spacing, Heights, ToastDuration } from '../constants/UIConstants';
import { PageTrackingHelper } from '../utils/PageTrackingHelper';
import { FTLogger } from '@guancecloud/ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from '@guancecloud/ft_sdk/src/main/ets/components/bean/Status';
import { AppNavBar } from '../components/AppNavBar';

@Entry
@Component
struct RealScenarioDetailPage {
  @State productId: string = '';
  @State detail: ProductDetail = new ProductDetail();
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State demoApiAddress: string = '';

  aboutToAppear(): void {
    PageTrackingHelper.trackPageAppear('RealScenarioDetailPage');
    let params: Record<string, string> = {};
    const routerParams = router.getParams();
    if (routerParams) {
      params = routerParams as Record<string, string>;
    }
    this.productId = params['productId'] ?? '';
    this.loadProductDetail();
  }

  aboutToDisappear(): void {
    PageTrackingHelper.trackPageDisappear();
  }

  build() {
    Column() {
      AppNavBar({
        title: this.detail.title.length > 0 ? this.detail.title : '商品详情',
        showBack: true,
        onBack: () => {
          router.back();
        }
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(AppColors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        this.StateView(this.errorMessage)
      } else {
        Scroll() {
          Column() {
            Image(this.detail.imageUrl)
              .width('100%')
              .height(240)
              .objectFit(ImageFit.Cover)
              .backgroundColor('#F4F7FB')

            Column() {
              Text(this.buildStatusText())
                .fontSize(FontSizes.SMALL)
                .fontColor('#1C5D99')
                .backgroundColor('#E8F1FF')
                .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM, bottom: Spacing.SM })
                .margin({ top: Spacing.LG })

              Text(this.detail.title)
                .fontSize(FontSizes.HUGE)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111111')
                .margin({ top: 14 })

              Text(this.detail.price)
                .fontSize(FontSizes.SUBTITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor('#CC4E00')
                .margin({ top: Spacing.SM })

              Text(this.detail.subtitle)
                .fontSize(FontSizes.MEDIUM)
                .fontColor('#555555')
                .margin({ top: 10 })

              Text(this.buildHighlightsText())
                .fontSize(FontSizes.NORMAL)
                .fontColor('#333333')
                .backgroundColor('#F4F7FB')
                .padding(Spacing.MD)
                .margin({ top: Spacing.LG })
                .width('100%')

              Text(this.buildSpecsText())
                .fontSize(FontSizes.NORMAL)
                .fontColor('#444444')
                .backgroundColor('#F8F8F8')
                .padding(Spacing.MD)
                .margin({ top: Spacing.MD })
                .width('100%')

              Text(this.detail.description)
                .fontSize(FontSizes.MEDIUM)
                .fontColor('#444444')
                .lineHeight(23)
                .margin({ top: Spacing.LG })

              Button('打开 H5 商品页')
                .width('100%')
                .height(Heights.BUTTON)
                .fontSize(FontSizes.MEDIUM)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.WHITE)
                .margin({ top: 20, bottom: Spacing.LG })
                .onClick(() => {
                  PageTrackingHelper.trackAction('open_product_webview', 'click');
                  router.pushUrl({
                    url: 'pages/WebViewPage',
                    params: {
                      title: '商品 H5 详情',
                      url: this.buildProductWebUrl()
                    }
                  });
                })
            }
            .width('100%')
            .padding(Spacing.LG)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  StateView(message: string) {
    Column() {
      Text(message)
        .fontSize(FontSizes.NORMAL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .padding({ left: Spacing.XL, right: Spacing.XL })

      Button('重试')
        .height(Heights.BUTTON)
        .fontSize(FontSizes.MEDIUM)
        .fontColor(AppColors.WHITE)
        .backgroundColor(AppColors.PRIMARY)
        .margin({ top: Spacing.LG })
        .onClick(() => {
          this.loadProductDetail();
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  async loadProductDetail(): Promise<void> {
    if (this.productId.length === 0) {
      this.errorMessage = '缺少商品 ID';
      this.isLoading = false;
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    try {
      const setting = await SettingConfigManager.readSetting();
      this.demoApiAddress = setting.demoApiAddress;
      this.detail = await HttpEngine.productDetail(setting.demoApiAddress, this.productId);
      FTLogger.logBackground(`Loaded product detail: ${this.productId}`, Status.INFO);
    } catch (err) {
      const message = err instanceof Error ? err.message : JSON.stringify(err);
      this.errorMessage = `加载失败：${message}`;
      FTLogger.logBackground(`Load product detail failed: ${message}`, Status.ERROR);
      promptAction.showToast({ message: '加载详情失败', duration: ToastDuration.MEDIUM });
    } finally {
      this.isLoading = false;
    }
  }

  buildProductWebUrl(): string {
    return `${this.demoApiAddress.replace(/\/$/, '')}/product/${this.productId}`;
  }

  buildStatusText(): string {
    return `当前用户：${AccountManager.getUserData()?.username ?? 'guance'}  ·  评分：${this.detail.rating}  ·  库存：${this.detail.stock}`;
  }

  buildHighlightsText(): string {
    return `Highlights: ${this.detail.highlights.join(' · ')}`;
  }

  buildSpecsText(): string {
    const specsText = this.detail.specs.map((spec: ProductSpec): string => `${spec.key}: ${spec.value}`).join('\n');
    return `商品参数\n${specsText}`;
  }
}
