import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AccountManager } from '../manager/AccountManager';
import { DEFAULT_USER_NAME, DEFAULT_PASSWORD } from '../constants/Constant';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';
import { AppColors, FontSizes, Spacing, BorderRadius, Heights, ToastDuration } from '../constants/UIConstants';
import { PageTrackingHelper } from '../utils/PageTrackingHelper';

/**
 * Login page
 */
@Entry
@Component
struct LoginPage {
  @State username: string = DEFAULT_USER_NAME;
  @State password: string = DEFAULT_PASSWORD;
  @State isLoading: boolean = false;

  aboutToAppear(): void {
    PageTrackingHelper.trackPageAppear('LoginPage');
  }

  aboutToDisappear(): void {
    PageTrackingHelper.trackPageDisappear();
  }

  build() {
    Column() {
      // Top Logo area
      Column() {
        Image($r('app.media.login_logo'))
          .width('80%')
          .height(80)
          .margin({ top: 52 })
      }
      .width('100%')

      // Login form area
      Column() {
        // Username input
        Column() {
          TextInput({ placeholder: 'Please enter username', text: this.username })
            .width('100%')
            .height(Heights.INPUT_TALL)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(BorderRadius.SMALL)
            .onChange((value: string) => {
              this.username = value;
            })
        }
        .width('100%')
        .margin({ bottom: Spacing.MD })

        // Password input
        Column() {
          TextInput({ placeholder: 'Please enter password', text: this.password })
            .width('100%')
            .height(Heights.INPUT_TALL)
            .type(InputType.Password)
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(BorderRadius.SMALL)
            .onChange((value: string) => {
              this.password = value;
            })
        }
        .width('100%')
        .margin({ bottom: Spacing.LG })

        // Login button
        Button(this.isLoading ? 'Logging in...' : 'Login')
          .width('100%')
          .height(Heights.BUTTON_TALL)
          .fontSize(FontSizes.MEDIUM)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(BorderRadius.SMALL)
          .enabled(!this.isLoading)
          .opacity(this.isLoading ? 0.6 : 1)
          .onClick(() => {
            this.handleLogin();
          })

        // Edit settings
        Text('Edit Settings')
          .fontSize(FontSizes.NORMAL)
          .fontColor(AppColors.PRIMARY)
          .margin({ top: Spacing.MD })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingPage' });
          })
      }
      .width('100%')
      .padding({ left: Spacing.XL, right: Spacing.XL })
      .margin({ top: 40 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * Handle login
   */
  async handleLogin() {
    const stopTracking = PageTrackingHelper.trackActionWithTiming('login', 'click');

    if (!this.username || !this.password) {
      promptAction.showToast({
        message: 'Please enter username and password',
        duration: ToastDuration.LONG
      });
      stopTracking();
      return;
    }

    this.isLoading = true;

    const result = await AccountManager.login(this.username, this.password);

    this.isLoading = false;

    if (result.success) {
      FTLogger.logBackground(`Login successful for user: ${this.username}`, Status.INFO);

      promptAction.showToast({
        message: 'Login successful',
        duration: ToastDuration.MEDIUM
      });

      setTimeout(() => {
        stopTracking();
        router.replaceUrl({ url: 'pages/MainPage' });
      }, 500);
    } else {
      FTLogger.logBackground(`Login failed for user: ${this.username}, error: ${result.errorMessage}`, Status.ERROR);

      promptAction.showToast({
        message: result.errorMessage || 'Login failed',
        duration: ToastDuration.LONG
      });
      stopTracking();
    }
  }
}
