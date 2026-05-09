import { router } from '@kit.ArkUI';
import { MenuItem } from '../model/ListItem';
import { AppColors, FontSizes, Spacing } from '../constants/UIConstants';
import { PageTrackingHelper } from '../utils/PageTrackingHelper';
import { AppNavBar } from '../components/AppNavBar';

@Entry
@Component
struct TechnicalVerificationPage {
  private dataList: MenuItem[] = [
    new MenuItem('Native Demo', '查看 HarmonyOS 原生页面、异常触发与高级能力演示', $r('app.media.ohos')),
    new MenuItem('WebView Demo', '直接进入 WebView 测试页，验证 JS SDK 与页面交互采集', $r('app.media.ic_web'))
  ];

  aboutToAppear(): void {
    PageTrackingHelper.trackPageAppear('TechnicalVerificationPage');
  }

  aboutToDisappear(): void {
    PageTrackingHelper.trackPageDisappear();
  }

  build() {
    Column() {
      AppNavBar({
        title: '技术验证',
        showBack: true,
        onBack: () => {
          router.back();
        }
      })

      Text('这里保留面向开发排查的验证入口，适合单独检查 Native 与 WebView 的采集效果。')
        .width('100%')
        .fontSize(FontSizes.NORMAL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.SM })
        .backgroundColor(AppColors.WHITE)

      List() {
        ForEach(this.dataList, (item: MenuItem, index: number) => {
          ListItem() {
            this.ListItemBuilder(item)
          }
        }, (item: MenuItem, index: number) => `${index}_${item.title}`)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(AppColors.WHITE)
      .divider({ strokeWidth: 1, color: AppColors.DIVIDER })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  ListItemBuilder(item: MenuItem) {
    Row() {
      Image(item.icon)
        .width(64)
        .height(64)
        .margin({ right: Spacing.SM })

      Column() {
        Text(item.title)
          .fontSize(FontSizes.LARGE)
          .fontColor('#000000')

        Text(item.description)
          .fontSize(FontSizes.SMALL)
          .fontColor('#AAAAAA')
          .margin({ top: Spacing.SM })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(Spacing.SM)
    .backgroundColor(AppColors.WHITE)
    .onClick(() => {
      this.handleItemClick(item);
    })
  }

  handleItemClick(item: MenuItem): void {
    PageTrackingHelper.trackAction(`technical_${item.title.replace(' ', '_').toLowerCase()}`, 'click');
    switch (item.title) {
      case 'Native Demo':
        router.pushUrl({ url: 'pages/NativePage' });
        break;
      case 'WebView Demo':
        router.pushUrl({ url: 'pages/WebViewPage' });
        break;
    }
  }
}
