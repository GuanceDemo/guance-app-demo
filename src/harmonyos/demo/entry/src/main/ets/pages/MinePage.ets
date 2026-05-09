import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AccountManager } from '../manager/AccountManager';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { UserData } from '../model/UserData';
import { AccessType } from '../constants/AccessType';
import { bundleManager } from '@kit.AbilityKit';
import { FTLogger } from '@guancecloud/ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from '@guancecloud/ft_sdk/src/main/ets/components/bean/Status';
import { AppNavBar } from '../components/AppNavBar';

/**
 * User profile page
 */
@Component
export struct MinePage {
  @State userData: UserData = new UserData();
  @State accessType: string = 'Datakit';
  @State isRefreshing: boolean = false;
  @State isLoading: boolean = false;
  @State appVersion: string = '';

  aboutToAppear(): void {
    this.loadUserData();
    this.loadAccessType();
    this.getAppVersion();
  }

  build() {
    Column() {
      AppNavBar({ title: '我的' })
      Refresh({ refreshing: this.isRefreshing, friction: 100 }) {
        Scroll() {
          Column() {
            Row() {
              if (this.userData.avatar) {
                Image(this.userData.avatar)
                  .width(100)
                  .height(100)
                  .borderRadius(50)
                  .objectFit(ImageFit.Cover)
              } else {
                Text('\uE43C')
                  .fontSize(100)
                  .fontColor('#CCCCCC')
                  .width(100)
                  .height(100)
              }

              Column() {
                Text(this.userData.username || 'SomeOne')
                  .fontSize(20)
                  .fontColor('#c0c0c0')

                Text(this.userData.email || 'someone@example.com')
                  .fontSize(16)
                  .fontColor('#c0c0c0')
                  .margin({ top: 8 })

                Text('[点击用户信息框或下拉进行刷新]')
                  .fontSize(12)
                  .fontColor('#FF6600')
                  .margin({ top: 8 })
              }
              .height(100)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 24 })
            }
            .width('100%')
            .padding({ left: 20, top: 32, bottom: 32, right: 20 })
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              this.refreshUserInfo();
            })

            Divider()
              .color('#CCCCCC')
              .strokeWidth(0.5)

            Divider()
              .color('#CCCCCC')
              .strokeWidth(0.5)
              .margin({ top: 20 })

            Row() {
              Text('编辑 Demo 配置')
                .fontSize(16)
                .fontColor('#000000')
                .layoutWeight(1)
                .margin({ left: 8 })

              Text(`Type: ${this.accessType}`)
                .fontSize(16)
                .fontColor('#c0c0c0')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              router.pushUrl({ url: 'pages/SettingPage' });
            })

            Divider()
              .color('#2d2d2d')
              .strokeWidth(0.5)

            Row() {
              Text('版本号')
                .fontSize(16)
                .fontColor('#000000')
                .layoutWeight(1)
                .margin({ left: 8 })

              Text(this.appVersion)
                .fontSize(16)
                .fontColor('#c0c0c0')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')

            Divider()
              .color('#CCCCCC')
              .strokeWidth(0.5)

            Divider()
              .color('#CCCCCC')
              .strokeWidth(0.5)
              .margin({ top: 20 })

            Row() {
              Text('退出登录')
                .fontSize(16)
                .fontColor('#FF6600')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding(16)
            .backgroundColor('#FFFFFF')
            .onClick(() => {
              this.handleLogout();
            })

            Divider()
              .color('#CCCCCC')
              .strokeWidth(0.5)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .backgroundColor('#FFFFFF')
      }
      .onStateChange((status: RefreshStatus) => {
        if (status === RefreshStatus.Refresh) {
          this.refreshUserInfo();
        }
      })
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * Load user data
   */
  loadUserData(): void {
    const data = AccountManager.getUserData();
    if (data) {
      this.userData = data;
      // Log user data loading success
      FTLogger.logBackground('User data loaded successfully', Status.INFO);
    }
  }

  /**
   * Load access type
   */
  async loadAccessType(): Promise<void> {
    try {
      const setting = await SettingConfigManager.readSetting();
      this.accessType = setting.type === AccessType.DATAKIT ? 'Datakit' : 'Dataway';
    } catch (err) {
      console.error('Failed to load access type:', JSON.stringify(err));
    }
  }


  /**
   * Refresh user info
   */
  async refreshUserInfo(): Promise<void> {
    this.isLoading = true;
    this.isRefreshing = true;

    const success = await AccountManager.getUserInfo();
    this.isLoading = false;
    this.isRefreshing = false;

    if (success) {
      const data = AccountManager.getUserData();
      if (data) {
        this.userData = data;
      }
      // Log refresh success
      FTLogger.logBackground('User info refreshed successfully', Status.INFO);
      promptAction.showToast({ message: 'Success', duration: 1500 });
    } else {
      // Log refresh failure
      FTLogger.logBackground('Failed to refresh user info', Status.ERROR);
      promptAction.showToast({ message: 'Fail', duration: 1500 });
    }
  }

  /**
   * Get app version
   */
  getAppVersion(): void {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      this.appVersion = `${bundleInfo.versionName} (${bundleInfo.versionCode})`;
    } catch (error) {
      console.error('Failed to get app version:', JSON.stringify(error));
      this.appVersion = ''; // Fallback to default version
    }
  }

  /**
   * Handle logout
   */
  async handleLogout(): Promise<void> {
    // Log logout
    FTLogger.logBackground('User logged out', Status.INFO);

    await AccountManager.logout();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }
}
