import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AccountManager } from '../manager/AccountManager';
import { DEFAULT_USER_NAME, DEFAULT_PASSWORD } from '../constants/Constant';
import { FTRUMGlobalManager } from 'ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';

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
    // Start View tracking when page appears
    FTRUMGlobalManager.getInstance().startView('LoginPage');
    // Log page visit
    FTLogger.logBackground('LoginPage appeared', Status.INFO);
  }

  aboutToDisappear(): void {
    // Stop View tracking when page disappears
    FTRUMGlobalManager.getInstance().stopView();
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
            .height(50)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .onChange((value: string) => {
              this.username = value;
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        // Password input
        Column() {
          TextInput({ placeholder: 'Please enter password', text: this.password })
            .width('100%')
            .height(50)
            .type(InputType.Password)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .onChange((value: string) => {
              this.password = value;
            })
        }
        .width('100%')
        .margin({ bottom: 24 })

        // Login button
        Button(this.isLoading ? 'Logging in...' : 'Login')
          .width('100%')
          .height(50)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#FF6600')
          .borderRadius(8)
          .enabled(!this.isLoading)
          .opacity(this.isLoading ? 0.6 : 1)
          .onClick(() => {
            this.handleLogin();
          })

        // Edit settings
        Text('Edit Settings')
          .fontSize(14)
          .fontColor('#FF6600')
          .margin({ top: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingPage' });
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
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
    // Log login action
    FTRUMGlobalManager.getInstance().startAction('login', 'click');

    if (!this.username || !this.password) {
      promptAction.showToast({
        message: 'Please enter username and password',
        duration: 2000
      });
      FTRUMGlobalManager.getInstance().stopAction();
      return;
    }

    this.isLoading = true;

    const result = await AccountManager.login(this.username, this.password);

    this.isLoading = false;

    if (result.success) {
      // Log login success
      FTLogger.logBackground(`Login successful for user: ${this.username}`, Status.INFO);

      promptAction.showToast({
        message: 'Login successful',
        duration: 1500
      });

      setTimeout(() => {
        FTRUMGlobalManager.getInstance().stopAction();
        router.replaceUrl({ url: 'pages/MainPage' });
      }, 500);
    } else {
      // Log login failure
      FTLogger.logBackground(`Login failed for user: ${this.username}, error: ${result.errorMessage}`, Status.ERROR);

      promptAction.showToast({
        message: result.errorMessage || 'Login failed',
        duration: 2000
      });
      FTRUMGlobalManager.getInstance().stopAction();
    }
  }
}
