import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { SettingData } from '../model/SettingData';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { FTSDKManager } from '../manager/FTSDKManager';
import { AccessType } from '../constants/AccessType';
import { SessionReplayPrivacy } from '../constants/SessionReplayPrivacy';
import { Utils } from '../utils/Utils';
import { HttpEngine } from '../http/HttpEngine';
import {
  DEFAULT_DATAKIT_ADDRESS,
  DEFAULT_DATAWAY_ADDRESS,
  DEFAULT_DATAWAY_CLIENT_TOKEN,
  DEFAULT_API_ADDRESS,
  DEFAULT_OTEL_ADDRESS
} from '../constants/Constant';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';

// Clipboard configuration prefix
const CONFIG_PREFIX = 'gc-demo://';

/**
 * Settings page
 */
@Entry
@Component
struct SettingPage {
  @State datakitAddress: string = '';
  @State datawayAddress: string = '';
  @State datawayClientToken: string = '';
  @State otelAddress: string = '';
  @State demoAPIAddress: string = '';
  @State appId: string = '';
  @State accessType: AccessType = AccessType.DATAKIT;
  @State enableSessionReplay: boolean = false;
  @State sessionReplayPrivacy: SessionReplayPrivacy = SessionReplayPrivacy.ALLOW;
  @State isLoading: boolean = false;
  @State datakitAddressError: string = '';
  @State datawayAddressError: string = '';
  @State datawayClientTokenError: string = '';
  @State demoAPIAddressError: string = '';
  @State showConfigDialog: boolean = false;
  @State configInputText: string = '';

  aboutToAppear(): void {
    // Log page visit
    FTLogger.logBackground('SettingPage appeared', Status.INFO);
    this.loadSettings();
  }

  build() {
    Column() {
      // Title bar
      Row() {
        // Back arrow
        Image($r('app.media.arrow_left'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('Edit Demo Config')
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

      Scroll() {
        Column() {
          // Access type selection
          Column() {
            Row() {
              Radio({ value: 'DataKit', group: 'accessType' })
                .checked(this.accessType === AccessType.DATAKIT)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.accessType = AccessType.DATAKIT;
                  }
                })

              Text('Local Deployment (DataKit)')
                .fontSize(16)
                .fontColor('#333333')
                .margin({ left: 8 })
                .onClick(() => {
                  this.accessType = AccessType.DATAKIT;
                })
            }
            .width('100%')

            Row() {
              Radio({ value: 'DataWay', group: 'accessType' })
                .checked(this.accessType === AccessType.DATAWAY)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.accessType = AccessType.DATAWAY;
                  }
                })

              Text('Use Public DataWay')
                .fontSize(16)
                .fontColor('#333333')
                .margin({ left: 8 })
                .onClick(() => {
                  this.accessType = AccessType.DATAWAY;
                })
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ top: 16, left: 16, right: 16 })

          // DataKit configuration
          if (this.accessType === AccessType.DATAKIT) {
            Column() {
              Text('Datakit Address')
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .margin({ bottom: 8 })

              TextInput({ placeholder: 'Datakit Address', text: this.datakitAddress })
                .width('100%')
                .height(44)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.datakitAddress = value;
                  this.datakitAddressError = '';
                })

              // Error message
              if (this.datakitAddressError) {
                Text(this.datakitAddressError)
                  .fontSize(12)
                  .fontColor('#FF0000')
                  .width('100%')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ top: 16, left: 16, right: 16 })
          }

          // DataWay configuration
          if (this.accessType === AccessType.DATAWAY) {
            Column() {
              Text('Dataway Address')
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .margin({ bottom: 8 })

              TextInput({ placeholder: 'Dataway Address', text: this.datawayAddress })
                .width('100%')
                .height(44)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.datawayAddress = value;
                  this.datawayAddressError = '';
                })

              // DataWay error message
              if (this.datawayAddressError) {
                Text(this.datawayAddressError)
                  .fontSize(12)
                  .fontColor('#FF0000')
                  .width('100%')
                  .margin({ top: 4 })
              }

              Text('Dataway Token')
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .margin({ top: 16, bottom: 8 })

              TextInput({ placeholder: 'Dataway Token', text: this.datawayClientToken })
                .width('100%')
                .height(44)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.datawayClientToken = value;
                  this.datawayClientTokenError = '';
                })

              // Client Token error message
              if (this.datawayClientTokenError) {
                Text(this.datawayClientTokenError)
                  .fontSize(12)
                  .fontColor('#FF0000')
                  .width('100%')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ top: 16, left: 16, right: 16 })
          }

          // Common configuration
          Column() {
            // App ID
            Text('AppId')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })

            TextInput({ placeholder: 'AppId', text: this.appId })
              .width('100%')
              .height(44)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .onChange((value: string) => {
                this.appId = value;
              })

            // Demo API address
            Text('Demo API Address')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .margin({ top: 16, bottom: 8 })

            TextInput({ placeholder: 'Demo API Address', text: this.demoAPIAddress })
              .width('100%')
              .height(44)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .onChange((value: string) => {
                this.demoAPIAddress = value;
                this.demoAPIAddressError = '';
              })

            // Demo API error message
            if (this.demoAPIAddressError) {
              Text(this.demoAPIAddressError)
                .fontSize(12)
                .fontColor('#FF0000')
                .width('100%')
                .margin({ top: 4 })
            }

            // OTEL address
            Text('Otel API Address (optional)')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .margin({ top: 16, bottom: 8 })

            TextInput({ placeholder: 'Otel API Address (optional)', text: this.otelAddress })
              .width('100%')
              .height(44)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .onChange((value: string) => {
                this.otelAddress = value;
              })

          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ top: 16, left: 16, right: 16 })

          // Action buttons
          Row() {
            // Import configuration button
            Button('Import Configuration')
              .width('100%')
              .height(44)
              .fontSize(16)
              .backgroundColor('#FFFFFF')
              .fontColor('#FF6B00')
              .border({ width: 1, color: '#FF6B00' })
              .borderRadius(8)
              .onClick(() => {
                this.importFromClipboard();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .margin({ top: 16 })

          Row() {
            Button('Test Connection')
              .width('100%')
              .height(44)
              .fontSize(16)
              .backgroundColor('#FFFFFF')
              .fontColor('#FF6600')
              .border({ width: 1, color: '#FF6600' })
              .borderRadius(8)
              .onClick(() => {
                this.testConnection();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .margin({ top: 16 })

          Button('Save')
            .width('calc(100% - 32vp)')
            .height(44)
            .fontSize(16)
            .backgroundColor('#FF6600')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ top: 12, left: 16, right: 16, bottom: 16 })
            .onClick(() => {
              this.saveConfig();
            })
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .bindContentCover(this.showConfigDialog, this.configDialogBuilder(), {
      modalTransition: ModalTransition.NONE
    })
  }

  /**
   * Configuration dialog builder
   */
  @Builder
  configDialogBuilder() {
    Column() {
      Column() {
        // Dialog title
        Text('Import Configuration')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .margin({ bottom: 16 })

        // Dialog content
        Text('Please paste the gc-demo:// configuration string:')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .margin({ bottom: 8 })

        TextArea({ placeholder: 'gc-demo://...', text: this.configInputText })
          .width('100%')
          .height(120)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.configInputText = value;
          })

        // Dialog buttons
        Row() {
          Button('Cancel')
            .width('48%')
            .height(40)
            .fontSize(16)
            .backgroundColor('#FFFFFF')
            .fontColor('#666666')
            .border({ width: 1, color: '#CCCCCC' })
            .borderRadius(8)
            .onClick(() => {
              this.showConfigDialog = false;
            })

          Button('Confirm')
            .width('48%')
            .height(40)
            .fontSize(16)
            .backgroundColor('#FF6600')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .onClick(() => {
              this.confirmImportConfig();
            })
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 32, right: 32 })
  }

  /**
   * Load settings
   */
  async loadSettings(): Promise<void> {
    console.info('SettingPage: Starting to load settings');
    const setting = await SettingConfigManager.readSetting();
    console.info('SettingPage: Settings loaded, updating UI');
    this.datakitAddress = setting.datakitAddress;
    this.datawayAddress = setting.datawayAddress;
    this.datawayClientToken = setting.datawayClientToken;
    this.otelAddress = setting.otelAddress;
    this.demoAPIAddress = setting.demoApiAddress;
    this.appId = setting.appId;
    this.accessType = setting.type;
    this.enableSessionReplay = setting.enableSessionReplay;
    this.sessionReplayPrivacy = setting.sessionReplayPrivacyType;
    console.info('SettingPage: UI updated with loaded settings');
  }

  /**
   * Test connection
   */
  async testConnection(): Promise<void> {
    // Clear error messages
    this.datakitAddressError = '';
    this.datawayAddressError = '';
    this.datawayClientTokenError = '';
    this.demoAPIAddressError = '';

    if (!this.validateInputs()) {
      return;
    }

    this.isLoading = true;
    promptAction.showToast({ message: 'Testing...', duration: 1000 });

    try {
      // Test DataKit/DataWay connection
      let connectResult: boolean = false;
      if (this.accessType === AccessType.DATAKIT) {
        const result = await HttpEngine.datakitPing(this.datakitAddress);
        if (result.code !== 200) {
          this.datakitAddressError = result.errorMessage || 'Connection failed';
          FTLogger.logBackground(`DataKit connection failed: ${this.datakitAddress}`, Status.ERROR);
        } else {
          this.datakitAddressError = '';
          connectResult = true;
          FTLogger.logBackground(`DataKit connection success: ${this.datakitAddress}`, Status.INFO);
        }
      } else {
        const result = await HttpEngine.datawayPing(this.datawayAddress, this.datawayClientToken);
        if (result.code !== 200) {
          this.datawayAddressError = result.errorMessage || 'Connection failed';
          this.datawayClientTokenError = result.errorMessage || 'Connection failed';
          FTLogger.logBackground(`DataWay connection failed: ${this.datawayAddress}`, Status.ERROR);
        } else {
          this.datawayAddressError = '';
          this.datawayClientTokenError = '';
          connectResult = true;
          FTLogger.logBackground(`DataWay connection success: ${this.datawayAddress}`, Status.INFO);
        }
      }

      // Test Demo API connection
      const apiResult = await HttpEngine.apiConnect(this.demoAPIAddress);
      console.info('apiResult',JSON.stringify(apiResult))
      if (apiResult.code !== 200) {
        this.demoAPIAddressError = apiResult.errorMessage || 'Connection failed';
        connectResult = false;
        FTLogger.logBackground(`Demo API connection failed: ${this.demoAPIAddress}`, Status.ERROR);
      } else {
        this.demoAPIAddressError = '';
        FTLogger.logBackground(`Demo API connection success: ${this.demoAPIAddress}`, Status.INFO);
      }

      this.isLoading = false;

      if (connectResult && this.demoAPIAddressError === '') {
        promptAction.showToast({ message: 'Connection successful', duration: 1500 });
      } else {
        promptAction.showToast({ message: 'Some connections failed, please check configuration', duration: 2000 });
      }
    } catch (err) {
      this.isLoading = false;
      console.error('Test connection failed:', JSON.stringify(err));
      FTLogger.logBackground(`Test connection error: ${JSON.stringify(err)}`, Status.ERROR);
      promptAction.showToast({ message: 'Connection failed: ' + JSON.stringify(err), duration: 2000 });
    }
  }

  /**
   * Save configuration
   */
  async saveConfig(): Promise<void> {
    if (!this.validateInputs()) {
      return;
    }

    const settingData = new SettingData(
      this.datakitAddress,
      this.demoAPIAddress,
      this.appId,
      this.datawayAddress,
      this.datawayClientToken,
      this.otelAddress,
      this.accessType,
      this.enableSessionReplay,
      this.sessionReplayPrivacy
    );

    await SettingConfigManager.saveSetting(settingData);

    // Log configuration save
    FTLogger.logBackground(`Settings saved: accessType=${this.accessType}, appId=${this.appId}`, Status.INFO);

    // Re-initialize FT SDK with new configuration
    await FTSDKManager.getInstance().reInitSDK();

    promptAction.showToast({
      message: 'Settings saved and SDK re-initialized',
      duration: 2000
    });

    setTimeout(() => {
      router.replaceUrl({ url: 'pages/MainPage' });
    }, 2000);
  }

  /**
   * Validate inputs
   */
  validateInputs(): boolean {
    if (!this.appId) {
      promptAction.showToast({ message: 'Please enter App ID', duration: 1500 });
      return false;
    }

    if (!Utils.isValidHttpUrl(this.demoAPIAddress)) {
      promptAction.showToast({ message: 'Invalid Demo API address', duration: 1500 });
      return false;
    }

    if (this.accessType === AccessType.DATAKIT) {
      if (!Utils.isValidHttpUrl(this.datakitAddress)) {
        promptAction.showToast({ message: 'Invalid DataKit address', duration: 1500 });
        return false;
      }
    } else {
      if (!Utils.isValidHttpUrl(this.datawayAddress)) {
        promptAction.showToast({ message: 'Invalid DataWay address', duration: 1500 });
        return false;
      }

      if (!this.datawayClientToken) {
        promptAction.showToast({ message: 'Please enter Client Token', duration: 1500 });
        return false;
      }
    }

    return true;
  }

  /**
   * Import configuration from dialog
   */
  importFromClipboard(): void {
    this.showConfigDialog = true;
    this.configInputText = '';
  }

  /**
   * Parse and apply configuration string
   */
  parseConfigString(configText: string): boolean {
    try {
      console.info('Starting to parse configuration');

      if (!configText || configText.length === 0) {
        promptAction.showToast({ message: 'Configuration is empty', duration: 1500 });
        return false;
      }

      // Check if it starts with configuration prefix
      if (!configText.startsWith(CONFIG_PREFIX)) {
        promptAction.showToast({ message: 'Invalid configuration format', duration: 2000 });
        return false;
      }

      // Remove prefix
      const base64Str: string = configText.substring(CONFIG_PREFIX.length);
      console.info('Base64 string length:', base64Str.length);

      // Base64 decode
      const decodedStr: string = Utils.base64Decode(base64Str);
      console.info('Decoded string:', decodedStr);

      if (!decodedStr) {
        promptAction.showToast({ message: 'Configuration parsing failed', duration: 1500 });
        return false;
      }

      // Parse JSON
      const jsonObj: Record<string, string> = JSON.parse(decodedStr);
      console.info('JSON parsed successfully:', JSON.stringify(jsonObj));



      // Fill configuration
      if (jsonObj.demoHarmonyOSAppId) {
        this.appId = jsonObj.demoHarmonyOSAppId;
      }
      if (jsonObj.demoApiAddress) {
        this.demoAPIAddress = jsonObj.demoApiAddress;
      }
      if (jsonObj.datakitAddress) {
        this.datakitAddress = jsonObj.datakitAddress;
        this.accessType = AccessType.DATAKIT;
      } else if (jsonObj.datawayAddress && jsonObj.datawayClientToken) {
        this.datawayAddress = jsonObj.datawayAddress;
        this.datawayClientToken = jsonObj.datawayClientToken;
        this.accessType = AccessType.DATAWAY;
      }
      if (jsonObj.otelAddress) {
        this.otelAddress = jsonObj.otelAddress;
      }

      console.info('Configuration imported successfully');
      FTLogger.logBackground('Configuration imported successfully', Status.INFO);
      promptAction.showToast({ message: 'Configuration imported successfully', duration: 1500 });
      return true;
    } catch (err) {
      console.error('Parse configuration failed:', JSON.stringify(err));
      FTLogger.logBackground(`Parse configuration failed: ${JSON.stringify(err)}`, Status.ERROR);
      promptAction.showToast({ message: 'Configuration parsing failed', duration: 1500 });
      return false;
    }
  }

  /**
   * Confirm and import configuration
   */
  confirmImportConfig(): void {
    if (this.parseConfigString(this.configInputText)) {
      this.showConfigDialog = false;
    }
  }
}
