import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AccountManager } from '../manager/AccountManager';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { UserData } from '../model/UserData';
import { AccessType } from '../constants/AccessType';
import { bundleManager } from '@kit.AbilityKit';
import { FTLogger } from '@guancecloud/ft_sdk';
import { Status } from '@guancecloud/ft_sdk';
import { AppNavBar } from '../components/AppNavBar';
import { ListCell } from '../components/ListCell';
import {
  AppColors,
  BorderRadius,
  FontSizes,
  Heights,
  IconSizes,
  Spacing,
  StrokeWidths,
  ToastDuration
} from '../constants/UIConstants';

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
            this.ProfileCard()
            this.SettingCard()
            this.LogoutButton()
          }
          .width('100%')
          .padding({
            left: Spacing.SCREEN_HORIZONTAL,
            right: Spacing.SCREEN_HORIZONTAL,
            top: Spacing.SECTION_GAP,
            bottom: Spacing.LG
          })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .backgroundColor(AppColors.PAGE_BACKGROUND)
      }
      .onStateChange((status: RefreshStatus) => {
        if (status === RefreshStatus.Refresh) {
          this.refreshUserInfo();
        }
      })
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(AppColors.PAGE_BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BACKGROUND)
  }

  @Builder
  ProfileCard() {
    Column() {
      Row() {
        if (this.userData.avatar) {
          Image(this.userData.avatar)
            .width(IconSizes.AVATAR)
            .height(IconSizes.AVATAR)
            .borderRadius(IconSizes.AVATAR / 2)
            .objectFit(ImageFit.Cover)
        } else {
          Text(this.getUserInitial())
            .fontSize(FontSizes.HUGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
            .textAlign(TextAlign.Center)
            .width(IconSizes.AVATAR)
            .height(IconSizes.AVATAR)
            .backgroundColor(AppColors.PRIMARY_SOFT)
            .borderRadius(IconSizes.AVATAR / 2)
        }

        Column() {
          Text(this.getDisplayName())
            .fontSize(FontSizes.TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.userData.email || 'someone@example.com')
            .fontSize(FontSizes.NORMAL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ top: Spacing.XS })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .height(IconSizes.AVATAR)
        .margin({ left: Spacing.LG })
      }
      .width('100%')

      Row() {
        Text(this.isLoading ? '正在刷新用户信息...' : '点击卡片或下拉刷新用户信息')
          .fontSize(FontSizes.CAPTION)
          .fontColor(AppColors.PRIMARY)
          .layoutWeight(1)

        Text('刷新')
          .fontSize(FontSizes.CAPTION)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(Heights.TOUCH_TARGET)
      .padding({ left: Spacing.MD, right: Spacing.MD })
      .margin({ top: Spacing.LG })
      .backgroundColor(AppColors.PRIMARY_SOFT)
      .borderRadius(BorderRadius.SMALL)
    }
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(BorderRadius.CARD)
    .border({ width: StrokeWidths.HAIRLINE, color: AppColors.BORDER })
    .margin({ bottom: Spacing.SECTION_GAP })
    .onClick(() => {
      this.refreshUserInfo();
    })
  }

  @Builder
  SettingCard() {
    Column() {
      Text('应用信息')
        .fontSize(FontSizes.MEDIUM)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')
        .margin({ bottom: Spacing.MD })

      ListCell({
        title: '编辑 Demo 配置',
        description: '当前接入方式',
        iconText: 'S',
        iconColor: AppColors.PRIMARY,
        iconBgColor: AppColors.PRIMARY_SOFT,
        valueText: this.accessType,
        onTap: () => {
          router.pushUrl({ url: 'pages/SettingPage' });
        }
      })

      ListCell({
        title: '版本号',
        description: this.appVersion || 'Unknown',
        iconText: 'V',
        iconColor: AppColors.INFO,
        iconBgColor: AppColors.INFO_SOFT,
        showChevron: false
      })
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(BorderRadius.CARD)
    .border({ width: StrokeWidths.HAIRLINE, color: AppColors.BORDER })
    .margin({ bottom: Spacing.SECTION_GAP })
  }

  @Builder
  LogoutButton() {
    Button('退出登录')
      .width('100%')
      .height(Heights.BUTTON)
      .fontSize(FontSizes.MEDIUM)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.PRIMARY)
      .backgroundColor(AppColors.SURFACE)
      .border({ width: StrokeWidths.HAIRLINE, color: AppColors.PRIMARY })
      .borderRadius(BorderRadius.SMALL)
      .onClick(() => {
        this.handleLogout();
      })
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
      promptAction.showToast({ message: 'Success', duration: ToastDuration.MEDIUM });
    } else {
      // Log refresh failure
      FTLogger.logBackground('Failed to refresh user info', Status.ERROR);
      promptAction.showToast({ message: 'Fail', duration: ToastDuration.MEDIUM });
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

  private getDisplayName(): string {
    return this.userData.username || 'SomeOne';
  }

  private getUserInitial(): string {
    const displayName = this.getDisplayName();
    return displayName.substring(0, 1).toUpperCase();
  }
}
