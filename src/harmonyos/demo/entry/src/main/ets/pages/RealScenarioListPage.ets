import { router, promptAction } from '@kit.ArkUI';
import { HttpEngine } from '../http/HttpEngine';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { ProductItem } from '../model/ProductData';
import { AppColors, FontSizes, Spacing, BorderRadius, Heights, ToastDuration } from '../constants/UIConstants';
import { PageTrackingHelper } from '../utils/PageTrackingHelper';
import { FTLogger } from '@guancecloud/ft_sdk';
import { Status } from '@guancecloud/ft_sdk';
import { AppNavBar } from '../components/AppNavBar';

@Entry
@Component
struct RealScenarioListPage {
  @State products: ProductItem[] = [];
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State errorMessage: string = '';

  aboutToAppear(): void {
    PageTrackingHelper.trackPageAppear('RealScenarioListPage');
    this.loadProducts();
  }

  aboutToDisappear(): void {
    PageTrackingHelper.trackPageDisappear();
  }

  build() {
    Column() {
      AppNavBar({
        title: '真实场景',
        showBack: true,
        rightText: '\uE645',
        onBack: () => {
          router.back();
        },
        onRightClick: () => {
          PageTrackingHelper.trackAction('product_feed_refresh', 'click');
          this.refreshProducts();
        }
      })

      Text('商品流由 Flask 提供真实列表数据。点击商品进入 Native 详情，再打开 H5 商品页，完整验证列表、详情、按钮、请求和 WebView 能力。')
        .width('100%')
        .fontSize(FontSizes.NORMAL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG })
        .backgroundColor(AppColors.WHITE)

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(AppColors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: Spacing.LG })
        .alignItems(HorizontalAlign.Center)
      } else {
        Refresh({ refreshing: this.isRefreshing, friction: 100 }) {
          if (this.errorMessage.length > 0) {
            this.StateView(this.errorMessage, '重试')
          } else if (this.products.length === 0) {
            this.StateView('暂无商品数据', '刷新')
          } else {
            List() {
              ForEach(this.products, (item: ProductItem) => {
                ListItem() {
                  this.ProductRow(item)
                }
              }, (item: ProductItem) => item.id)
            }
            .width('100%')
            .height('100%')
            .backgroundColor(AppColors.WHITE)
            .scrollBar(BarState.Off)
          }
        }
        .onStateChange((status: RefreshStatus) => {
          if (status === RefreshStatus.Refresh) {
            PageTrackingHelper.trackAction('product_feed_refresh', 'pull_to_refresh');
            this.refreshProducts();
          }
        })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(AppColors.WHITE)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  ProductRow(item: ProductItem) {
    Row() {
      Image(item.imageUrl)
        .width(120)
        .height(80)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#F4F7FB')

      Column() {
        Text(item.tag)
          .fontSize(FontSizes.SMALL)
          .fontColor('#1C5D99')
          .backgroundColor('#E6F2FF')
          .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })

        Text(item.title)
          .fontSize(FontSizes.LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
          .margin({ top: 10 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(item.subtitle)
          .fontSize(13)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })

        Row() {
          Text(item.price)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#CC4E00')
            .layoutWeight(1)

          Text(item.rating)
            .fontSize(13)
            .fontColor('#0F4C81')
        }
        .width('100%')
        .margin({ top: 10 })
      }
      .layoutWeight(1)
      .margin({ left: Spacing.MD })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(Spacing.XXL)
    .backgroundColor(AppColors.WHITE)
    .onClick(() => {
      PageTrackingHelper.trackAction('open_product_detail', 'click');
      router.pushUrl({
        url: 'pages/RealScenarioDetailPage',
        params: { productId: item.id }
      });
    })
  }

  @Builder
  StateView(message: string, buttonText: string) {
    Column() {
      Text(message)
        .fontSize(FontSizes.NORMAL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .padding({ left: Spacing.XL, right: Spacing.XL })

      Button(buttonText)
        .height(Heights.BUTTON)
        .fontSize(FontSizes.MEDIUM)
        .fontColor(AppColors.WHITE)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(BorderRadius.SMALL)
        .margin({ top: Spacing.LG })
        .onClick(() => {
          this.refreshProducts();
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  async loadProducts(showLoading: boolean = true): Promise<void> {
    if (showLoading) {
      this.isLoading = true;
    }
    this.errorMessage = '';
    try {
      const setting = await SettingConfigManager.readSetting();
      const items = await HttpEngine.products(setting.demoApiAddress);
      this.products = items;
      FTLogger.logBackground(`Loaded ${items.length} products`, Status.INFO);
    } catch (err) {
      const message = err instanceof Error ? err.message : JSON.stringify(err);
      this.products = [];
      this.errorMessage = `加载失败：${message}`;
      FTLogger.logBackground(`Load products failed: ${message}`, Status.ERROR);
      promptAction.showToast({ message: '加载商品失败', duration: ToastDuration.MEDIUM });
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  async refreshProducts(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    await this.loadProducts(false);
  }
}
