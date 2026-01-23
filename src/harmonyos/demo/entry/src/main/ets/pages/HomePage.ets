import { router } from '@kit.ArkUI';
import { MenuItem } from '../model/ListItem';
import { FTRUMGlobalManager } from 'ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';

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
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // Placeholder to keep title centered
        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

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
      .backgroundColor('#F5F5F5')
      .divider({ strokeWidth: 1, color: '#E0E0E0' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  ListItemBuilder(item: MenuItem) {
    Row() {
      // Left icon
      Image(item.icon)
        .width(48)
        .aspectRatio(1)
        .margin({right:8})

      // Center title and description
      Column() {
        Text(item.title)
          .fontSize(16)
          .fontColor('#333333')
          .margin({ bottom: 4 })

        Text(item.description)
          .fontSize(14)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // Right arrow
      Text('\uE63C')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.handleItemClick(item);
    })
  }

  /**
   * Handle list item click
   */
  handleItemClick(item: MenuItem): void {
    // Log menu item click action
    FTRUMGlobalManager.getInstance().addAction(`menu_${item.title.replace(/\s+/g, '_').toLowerCase()}`, 'click');

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
