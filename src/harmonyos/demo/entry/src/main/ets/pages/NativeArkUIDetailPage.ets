import { router } from '@kit.ArkUI';
import { FTRUMGlobalManager } from '@guancecloud/ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';
import { AppColors, BorderRadius, FontSizes, Spacing } from '../constants/UIConstants';
import { AppNavBar } from '../components/AppNavBar';

@Entry
@Component
struct NativeArkUIDetailPage {
  @State itemId: string = '';
  @State titleText: string = 'ArkUI 详情';
  @State description: string = '';
  @State level: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.itemId = params?.id || '';
    this.titleText = params?.title || 'ArkUI 详情';
    this.description = params?.description || '';
    this.level = params?.level || '';
    FTRUMGlobalManager.getInstance().startView(`NativeArkUIDetailPage/${this.itemId}`);
  }

  aboutToDisappear(): void {
    FTRUMGlobalManager.getInstance().stopView();
  }

  build() {
    Column() {
      AppNavBar({
        title: 'ArkUI Detail',
        showBack: true,
        onBack: () => {
          router.back();
        }
      })

      Scroll() {
        Column() {
          Image($r('app.media.home_activity'))
            .width('100%')
            .height(180)
            .objectFit(ImageFit.Cover)
            .borderRadius(BorderRadius.SMALL)
            .backgroundColor(AppColors.LIGHT_GRAY)

          Column() {
            Text(this.titleText)
              .fontSize(FontSizes.TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)
              .width('100%')

            Text(this.level)
              .fontSize(FontSizes.SMALL)
              .fontColor(AppColors.PRIMARY)
              .width('100%')
              .margin({ top: Spacing.SM })

            Text(this.description)
              .fontSize(FontSizes.NORMAL)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
              .margin({ top: Spacing.MD })

            Text(`Item ID: ${this.itemId}`)
              .fontSize(FontSizes.SMALL)
              .fontColor(AppColors.TEXT_HINT)
              .width('100%')
              .margin({ top: Spacing.LG })
          }
          .width('100%')
          .padding(Spacing.MD)
          .margin({ top: Spacing.SM })
          .backgroundColor(AppColors.WHITE)
          .borderRadius(BorderRadius.SMALL)

          Button('记录详情页 Action')
            .width('100%')
            .height(44)
            .margin({ top: Spacing.LG })
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(BorderRadius.SMALL)
            .onClick(() => {
              FTRUMGlobalManager.getInstance().addActionWithProperty(
                `arkui_detail_${this.itemId}`,
                'click',
                {} as Record<string, object>
              );
            })
        }
        .width('100%')
        .padding(Spacing.MD)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
