import { router } from '@kit.ArkUI';
import { MenuItem } from '../model/ListItem';
import { FTRUMGlobalManager } from 'ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';
import { AppColors, FontSizes, Spacing, BorderRadius, Heights, IconSizes } from '../constants/UIConstants';

/**
 * Home page - Feature list page
 */
@Component
export struct HomePage {
  private dataList: MenuItem[] = [
    new MenuItem('Native View', 'Native page monitoring', $r("app.media.ohos")),
    new MenuItem('WebView', 'WebView monitoring',$r("app.media.ic_web"))
  ];

  build() {
    Column() {
      // Title bar
      Row() {

        Text('Home')
          .fontSize(FontSizes.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Placeholder to keep title centered
        Row()
          .width(Spacing.XXL)
          .height(Spacing.XXL)
      }
      .width('100%')
      .height(Heights.TOOLBAR)
      .padding({ left: Spacing.LG, right: Spacing.LG })
      .backgroundColor(AppColors.WHITE)

      // Feature list
      List() {
        ForEach(this.dataList, (item: MenuItem, index: number) => {
          ListItem() {
            this.ListItemBuilder(item)
          }
        }, (item: MenuItem, index: number) => `${index}_${item.title}`)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(AppColors.BACKGROUND)
      .divider({ strokeWidth: 1, color: AppColors.DIVIDER })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  ListItemBuilder(item: MenuItem) {
    Row() {
      // Left icon
      Image(item.icon)
        .width(IconSizes.XLARGE)
        .aspectRatio(1)
        .margin({right: Spacing.SM})

      // Center title and description
      Column() {
        Text(item.title)
          .fontSize(FontSizes.MEDIUM)
          .fontColor(AppColors.TEXT_PRIMARY)
          .margin({ bottom: Spacing.XS })

        Text(item.description)
          .fontSize(FontSizes.NORMAL)
          .fontColor(AppColors.TEXT_HINT)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Right arrow
      Text('\uE63C')
        .fontSize(IconSizes.SMALL)
        .fontColor(AppColors.TEXT_DISABLED)
    }
    .width('100%')
    .height(Heights.LIST_ITEM)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(AppColors.WHITE)
    .onClick(() => {
      this.handleItemClick(item);
    })
  }

  /**
   * Handle list item click
   */
  handleItemClick(item: MenuItem): void {
    switch (item.title) {
      case 'Native View':
        router.pushUrl({ url: 'pages/NativePage' });
        break;
      case 'WebView':
        router.pushUrl({ url: 'pages/WebViewPage' });
        break;
    }
  }
}
