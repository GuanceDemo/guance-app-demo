import { router } from '@kit.ArkUI';
import { AccountManager } from '../manager/AccountManager';
import { HomePage } from './HomePage';
import { MinePage } from './MinePage';
import { FTRUMGlobalManager } from 'ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';

/**
 * Main page - Contains bottom navigation bar
 */
@Entry
@Component
struct MainPage {
  @State currentTabIndex: number = 0;

  aboutToAppear(): void {
    // Start View tracking when page appears
    FTRUMGlobalManager.getInstance().startView('MainPage');
    // Log page visit
    FTLogger.logBackground('MainPage appeared', Status.INFO);

    // Check login status
    AccountManager.checkLogin().then((isLogin) => {
      if (!isLogin) {
        router.replaceUrl({ url: 'pages/LoginPage' });
      }
    });
  }

  aboutToDisappear(): void {
    // Stop View tracking when page disappears
    FTRUMGlobalManager.getInstance().stopView();
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      // Home Tab
      TabContent() {
        HomePage()
      }
      .tabBar(this.TabBuilder('Home', 0, 'home'))

      // Mine Tab
      TabContent() {
        MinePage()
      }
      .tabBar(this.TabBuilder('Mine', 1, 'mine'))
    }
    .width('100%')
    .height('100%')
    .barHeight(56)
    .onChange((index: number) => {
      // Log tab switch action
      const tabName = index === 0 ? 'Home' : 'Mine';
      FTRUMGlobalManager.getInstance().addAction(`tab_switch_${tabName}`, 'click');
      this.currentTabIndex = index;
    })
  }

  @Builder
  TabBuilder(title: string, index: number, iconName: string) {
    Column() {
      // Choose different image based on active state
      Image(this.currentTabIndex === index
        ? $r(`app.media.${iconName}_activity`)
        : $r(`app.media.${iconName}`))
        .width(24)
        .height(24)
        .margin({ top: 4 })

      Text(title)
        .fontSize(12)
        .fontColor(this.currentTabIndex === index ? '#FF6600' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
