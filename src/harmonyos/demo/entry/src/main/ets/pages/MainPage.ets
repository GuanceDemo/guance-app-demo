import { router } from '@kit.ArkUI';
import { AccountManager } from '../manager/AccountManager';
import { HomePage } from './HomePage';
import { MinePage } from './MinePage';
import { PageTrackingHelper } from '../utils/PageTrackingHelper';
import { AppColors, FontSizes, Spacing, IconSizes, Heights } from '../constants/UIConstants';

/**
 * Main page - Contains bottom navigation bar
 */
@Entry
@Component
struct MainPage {
  @State currentTabIndex: number = 0;

  aboutToAppear(): void {
    PageTrackingHelper.trackPageAppear('MainPage');

    // Check login status
    AccountManager.checkLogin().then((isLogin) => {
      if (!isLogin) {
        router.replaceUrl({ url: 'pages/LoginPage' });
      }
    });
  }

  aboutToDisappear(): void {
    PageTrackingHelper.trackPageDisappear();
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
    .barHeight(Heights.TOOLBAR)
    .onChange((index: number) => {
      // Log tab switch action
      const tabName = index === 0 ? 'Home' : 'Mine';
      PageTrackingHelper.trackAction(`tab_switch_${tabName}`, 'click');
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
        .width(IconSizes.LARGE)
        .height(IconSizes.LARGE)
        .margin({ top: Spacing.XS })

      Text(title)
        .fontSize(FontSizes.SMALL)
        .fontColor(this.currentTabIndex === index ? AppColors.PRIMARY : AppColors.TEXT_HINT)
        .margin({ top: Spacing.XS })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
