import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AccountManager } from '../manager/AccountManager';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { UserData } from '../model/UserData';
import { AccessType } from '../constants/AccessType';
import { bundleManager } from '@kit.AbilityKit';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';

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
    Refresh({ refreshing: this.isRefreshing, friction: 100 }) {
      Scroll() {
        Column() {
          // Title bar
          Text('Mine')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            .textAlign(TextAlign.Center)
          // User info card
          Row() {
            // Avatar
            if (this.userData.avatar) {
              Image(this.userData.avatar)
                .width(64)
                .height(64)
                .borderRadius(32)
                .objectFit(ImageFit.Cover)
                .border({ width: 2, color: '#FFFFFF' })
                .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
            } else {
              Text('\uE43C')
                .fontSize(64)
                .fontColor('#CCCCCC')
                .width(64)
                .height(64)
            }

            // User info
            Column() {
              Text(this.userData.username || 'SomeOne')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')

              Text(this.userData.email || 'someone@example.com')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 4 })

              Text('[Click user info box or pull down to refresh]')
                .fontSize(12)
                .fontColor('#FF6600')
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 16 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 12, color: '#0D000000', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.loadUserData();
          })

          // Settings card
          Column() {
            // Edit configuration item
            Row() {
              Text('\uE640')
                .fontSize(22)
                .fontColor('#FF6600')
                .margin({ right: 12 })

              Text('Edit Demo Config')
                .fontSize(16)
                .fontColor('#FF6600')
                .layoutWeight(1)

              Text(`Type: ${this.accessType}`)
                .fontSize(14)
                .fontColor('#999999')

              Text('\uE63C')
                .fontSize(16)
                .fontColor('#CCCCCC')
                .margin({ left: 8 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/SettingPage' });
            })

            // Divider
            Divider()
              .color('#F0F0F0')
              .strokeWidth(1)
              .margin({ left: 16, right: 16 })

            // Version number item
            Row() {
              Text('\uE641')
                .fontSize(22)
                .fontColor('#FF6600')
                .margin({ right: 12 })

              Text('Version')
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              Text(this.appVersion)
                .fontSize(14)
                .fontColor('#999999')

              Text('\uE63C')
                .fontSize(16)
                .fontColor('#CCCCCC')
                .margin({ left: 8 })
            }
            .width('100%')
            .padding(16)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 12 })
          .shadow({ radius: 8, color: '#08000000', offsetX: 0, offsetY: 1 })

          // Logout button
          Button('Logout')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#FF6600')
            .fontColor('#FFFFFF')
            .borderRadius(12)
            .margin({ top: 24, bottom: 24 })
            .shadow({ radius: 8, color: '#33FF6600', offsetX: 0, offsetY: 2 })
            .onClick(() => {
              this.handleLogout();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .backgroundColor('#F5F5F5')
    }
    .onStateChange((status: RefreshStatus) => {
      if (status === RefreshStatus.Refresh) {
        this.refreshUserInfo();
      }
    })
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * Load user data
   */
  loadUserData(): void {
    const data = AccountManager.getUserData();
    if (data) {
      this.userData = data;
      promptAction.showToast({ message: 'Refresh successful', duration: 1000 });
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
        console.info("datadatadata",JSON.stringify(data))
        this.userData = data;
      }
      // Log refresh success
      FTLogger.logBackground('User info refreshed successfully', Status.INFO);
      promptAction.showToast({ message: 'Refresh successful', duration: 1500 });
    } else {
      // Log refresh failure
      FTLogger.logBackground('Failed to refresh user info', Status.ERROR);
      promptAction.showToast({ message: 'Refresh failed', duration: 1500 });
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
