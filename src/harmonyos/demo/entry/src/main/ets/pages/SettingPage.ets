import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { SettingData } from '../model/SettingData';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { FTSDKManager } from '../manager/FTSDKManager';
import { AccessType } from '../constants/AccessType';
import { SessionReplayPrivacy } from '../constants/SessionReplayPrivacy';
import { Utils } from '../utils/Utils';
import { HttpEngine } from '../http/HttpEngine';
import { FTLogger } from '@guancecloud/ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from '@guancecloud/ft_sdk/src/main/ets/components/bean/Status';
import { AppNavBar } from '../components/AppNavBar';
import { FormSection } from '../components/FormSection';
import { FormTextInput } from '../components/FormTextInput';
import {
  AppColors,
  BorderRadius,
  FontSizes,
  Heights,
  Spacing,
  StrokeWidths,
  ToastDuration
} from '../constants/UIConstants';

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
      AppNavBar({
        title: '编辑 Demo 配置',
        showBack: true,
        onBack: () => {
          router.back();
        }
      })

      Scroll() {
        Column() {
          this.AccessTypeSection()
          this.AccessEndpointSection()
          this.CommonConfigSection()
          this.SessionReplaySection()
        }
        .width('100%')
        .padding({
          left: Spacing.SCREEN_HORIZONTAL,
          right: Spacing.SCREEN_HORIZONTAL,
          top: Spacing.SECTION_GAP,
          bottom: Spacing.SECTION_GAP
        })
      }
      .layoutWeight(1)
      .width('100%')

      this.BottomActionBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BACKGROUND)
    .bindContentCover(this.showConfigDialog, this.configDialogBuilder(), {
      modalTransition: ModalTransition.NONE
    })
  }

  @Builder
  AccessTypeSection() {
    FormSection({
      title: '接入方式',
      description: '选择 SDK 数据上报目标，表单会只展示当前方式需要的字段。',
      content: () => {
        this.AccessTypeContent()
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })
  }

  @Builder
  AccessTypeContent() {
    Row() {
      this.AccessTypeOption('Local Deployment', 'DataKit', AccessType.DATAKIT)

      Blank()
        .width(Spacing.SM)

      this.AccessTypeOption('Public DataWay', 'DataWay', AccessType.DATAWAY)
    }
    .width('100%')
  }

  @Builder
  AccessTypeOption(title: string, subtitle: string, type: number) {
    Column() {
      Text(title)
        .fontSize(FontSizes.BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.accessType === type ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY)
        .width('100%')

      Text(subtitle)
        .fontSize(FontSizes.SMALL)
        .fontColor(this.accessType === type ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ top: Spacing.XS })
    }
    .layoutWeight(1)
    .padding(Spacing.MD)
    .backgroundColor(this.accessType === type ? AppColors.PRIMARY_SOFT : AppColors.SURFACE_MUTED)
    .border({ width: StrokeWidths.HAIRLINE, color: this.accessType === type ? AppColors.PRIMARY : AppColors.BORDER })
    .borderRadius(BorderRadius.CARD)
    .onClick(() => {
      this.accessType = type as AccessType;
    })
  }

  @Builder
  AccessEndpointSection() {
    if (this.accessType === AccessType.DATAKIT) {
      FormSection({
        title: 'DataKit 配置',
        description: '本地部署模式需要保证真机可以访问 DataKit 地址。',
        content: () => {
          this.DataKitConfigContent()
        }
      })
      .margin({ bottom: Spacing.SECTION_GAP })
    } else {
      FormSection({
        title: 'DataWay 配置',
        description: '公网 DataWay 模式需要填写服务地址和 Client Token。',
        content: () => {
          this.DataWayConfigContent()
        }
      })
      .margin({ bottom: Spacing.SECTION_GAP })
    }
  }

  @Builder
  DataKitConfigContent() {
    FormTextInput({
      label: 'DataKit Address',
      placeholder: 'http://host:9529',
      text: this.datakitAddress,
      error: this.datakitAddressError,
      onValueChange: (value: string) => {
        this.datakitAddress = value;
        this.datakitAddressError = '';
      }
    })
  }

  @Builder
  DataWayConfigContent() {
    FormTextInput({
      label: 'DataWay Address',
      placeholder: 'https://rum-openway.guance.com',
      text: this.datawayAddress,
      error: this.datawayAddressError,
      onValueChange: (value: string) => {
        this.datawayAddress = value;
        this.datawayAddressError = '';
      }
    })
    FormTextInput({
      label: 'DataWay Token',
      placeholder: 'Client Token',
      text: this.datawayClientToken,
      error: this.datawayClientTokenError,
      onValueChange: (value: string) => {
        this.datawayClientToken = value;
        this.datawayClientTokenError = '';
      }
    })
  }

  @Builder
  CommonConfigSection() {
    FormSection({
      title: '公共配置',
      description: 'AppId 用于 RUM 应用标识，Demo API 用于登录和真实场景数据。',
      content: () => {
        this.CommonConfigContent()
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })
  }

  @Builder
  CommonConfigContent() {
    FormTextInput({
      label: 'AppId',
      placeholder: 'HarmonyOS App ID',
      text: this.appId,
      onValueChange: (value: string) => {
        this.appId = value;
      }
    })
    FormTextInput({
      label: 'Demo API Address',
      placeholder: 'http://host:8000',
      text: this.demoAPIAddress,
      error: this.demoAPIAddressError,
      onValueChange: (value: string) => {
        this.demoAPIAddress = value;
        this.demoAPIAddressError = '';
      }
    })
    FormTextInput({
      label: 'Otel API Address (optional)',
      placeholder: 'http://host:4318/v1/traces',
      text: this.otelAddress,
      onValueChange: (value: string) => {
        this.otelAddress = value;
      }
    })
  }

  @Builder
  SessionReplaySection() {
    FormSection({
      title: 'Session Replay',
      description: '保存后重新初始化 SDK，配置才会生效。',
      content: () => {
        this.SessionReplayContent()
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })
  }

  @Builder
  SessionReplayContent() {
    Row() {
      Text('Enable Session Replay')
        .fontSize(FontSizes.BODY)
        .fontColor(AppColors.TEXT_PRIMARY)
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.enableSessionReplay })
        .selectedColor(AppColors.PRIMARY)
        .onChange((isOn: boolean) => {
          this.enableSessionReplay = isOn;
        })
    }
    .width('100%')
    .height(Heights.INPUT)

    if (this.enableSessionReplay) {
      Row() {
        this.PrivacyOption('Allow', SessionReplayPrivacy.ALLOW)
        Blank()
          .width(Spacing.SM)
        this.PrivacyOption('Mask', SessionReplayPrivacy.MASK)
        Blank()
          .width(Spacing.SM)
        this.PrivacyOption('Mask Input', SessionReplayPrivacy.MASK_USER_INPUT)
      }
      .width('100%')
      .margin({ top: Spacing.SM })
    }
  }

  @Builder
  PrivacyOption(title: string, value: number) {
    Text(title)
      .fontSize(FontSizes.SMALL)
      .fontColor(this.sessionReplayPrivacy === value ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(Heights.INPUT)
      .backgroundColor(this.sessionReplayPrivacy === value ? AppColors.PRIMARY_SOFT : AppColors.SURFACE_MUTED)
      .border({
        width: StrokeWidths.HAIRLINE,
        color: this.sessionReplayPrivacy === value ? AppColors.PRIMARY : AppColors.BORDER
      })
      .borderRadius(BorderRadius.SMALL)
      .onClick(() => {
        this.sessionReplayPrivacy = value as SessionReplayPrivacy;
      })
  }

  @Builder
  BottomActionBar() {
    Column() {
      Row() {
        Button('Import')
          .layoutWeight(1)
          .height(Heights.BUTTON)
          .fontSize(FontSizes.NORMAL)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.SURFACE)
          .border({ width: StrokeWidths.HAIRLINE, color: AppColors.PRIMARY })
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            this.importFromClipboard();
          })

        Blank()
          .width(Spacing.SM)

        Button(this.isLoading ? 'Testing...' : 'Test')
          .layoutWeight(1)
          .height(Heights.BUTTON)
          .fontSize(FontSizes.NORMAL)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.SURFACE)
          .border({ width: StrokeWidths.HAIRLINE, color: AppColors.PRIMARY })
          .borderRadius(BorderRadius.SMALL)
          .enabled(!this.isLoading)
          .opacity(this.isLoading ? 0.6 : 1)
          .onClick(() => {
            this.testConnection();
          })
      }
      .width('100%')

      Button('Save')
        .width('100%')
        .height(Heights.BUTTON)
        .fontSize(FontSizes.MEDIUM)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_INVERSE)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(BorderRadius.SMALL)
        .margin({ top: Spacing.SM })
        .onClick(() => {
          this.saveConfig();
        })
    }
    .width('100%')
    .padding({
      left: Spacing.SCREEN_HORIZONTAL,
      right: Spacing.SCREEN_HORIZONTAL,
      top: Spacing.SM,
      bottom: Spacing.MD
    })
    .backgroundColor(AppColors.SURFACE)
    .border({ width: StrokeWidths.HAIRLINE, color: AppColors.BORDER })
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
          .fontSize(FontSizes.LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
          .margin({ bottom: Spacing.LG })

        // Dialog content
        Text('Please paste the gc-demo:// configuration string:')
          .fontSize(FontSizes.NORMAL)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: Spacing.SM })

        TextArea({ placeholder: 'gc-demo://...', text: this.configInputText })
          .width('100%')
          .height(Heights.TEXT_AREA)
          .backgroundColor(AppColors.INPUT_BG)
          .borderRadius(BorderRadius.SMALL)
          .onChange((value: string) => {
            this.configInputText = value;
          })

        // Dialog buttons
        Row() {
          Button('Cancel')
            .layoutWeight(1)
            .height(Heights.BUTTON)
            .fontSize(FontSizes.MEDIUM)
            .backgroundColor(AppColors.SURFACE)
            .fontColor(AppColors.TEXT_SECONDARY)
            .border({ width: StrokeWidths.HAIRLINE, color: AppColors.TEXT_DISABLED })
            .borderRadius(BorderRadius.SMALL)
            .onClick(() => {
              this.showConfigDialog = false;
            })

          Blank()
            .width(Spacing.SM)

          Button('Confirm')
            .layoutWeight(1)
            .height(Heights.BUTTON)
            .fontSize(FontSizes.MEDIUM)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.TEXT_INVERSE)
            .borderRadius(BorderRadius.SMALL)
            .onClick(() => {
              this.confirmImportConfig();
            })
        }
        .width('100%')
        .margin({ top: Spacing.LG })
      }
      .width('100%')
      .padding(Spacing.XL)
      .backgroundColor(AppColors.SURFACE)
      .borderRadius(BorderRadius.MEDIUM)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.OVERLAY)
    .justifyContent(FlexAlign.Center)
    .padding({ left: Spacing.XXL, right: Spacing.XXL })
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
    promptAction.showToast({ message: 'Testing...', duration: ToastDuration.SHORT });

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
        promptAction.showToast({ message: 'Connection successful', duration: ToastDuration.MEDIUM });
      } else {
        promptAction.showToast({ message: 'Some connections failed, please check configuration', duration: ToastDuration.LONG });
      }
    } catch (err) {
      this.isLoading = false;
      console.error('Test connection failed:', JSON.stringify(err));
      FTLogger.logBackground(`Test connection error: ${JSON.stringify(err)}`, Status.ERROR);
      promptAction.showToast({ message: 'Connection failed: ' + JSON.stringify(err), duration: ToastDuration.LONG });
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
      duration: ToastDuration.LONG
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
      promptAction.showToast({ message: 'Please enter App ID', duration: ToastDuration.MEDIUM });
      return false;
    }

    if (!Utils.isValidHttpUrl(this.demoAPIAddress)) {
      promptAction.showToast({ message: 'Invalid Demo API address', duration: ToastDuration.MEDIUM });
      return false;
    }

    if (this.accessType === AccessType.DATAKIT) {
      if (!Utils.isValidHttpUrl(this.datakitAddress)) {
        promptAction.showToast({ message: 'Invalid DataKit address', duration: ToastDuration.MEDIUM });
        return false;
      }
    } else {
      if (!Utils.isValidHttpUrl(this.datawayAddress)) {
        promptAction.showToast({ message: 'Invalid DataWay address', duration: ToastDuration.MEDIUM });
        return false;
      }

      if (!this.datawayClientToken) {
        promptAction.showToast({ message: 'Please enter Client Token', duration: ToastDuration.MEDIUM });
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
        promptAction.showToast({ message: 'Configuration is empty', duration: ToastDuration.MEDIUM });
        return false;
      }

      // Check if it starts with configuration prefix
      if (!configText.startsWith(CONFIG_PREFIX)) {
        promptAction.showToast({ message: 'Invalid configuration format', duration: ToastDuration.LONG });
        return false;
      }

      // Remove prefix
      const base64Str: string = configText.substring(CONFIG_PREFIX.length);
      console.info('Base64 string length:', base64Str.length);

      // Base64 decode
      const decodedStr: string = Utils.base64Decode(base64Str);
      console.info('Decoded string:', decodedStr);

      if (!decodedStr) {
        promptAction.showToast({ message: 'Configuration parsing failed', duration: ToastDuration.MEDIUM });
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
      promptAction.showToast({ message: 'Configuration imported successfully', duration: ToastDuration.MEDIUM });
      return true;
    } catch (err) {
      console.error('Parse configuration failed:', JSON.stringify(err));
      FTLogger.logBackground(`Parse configuration failed: ${JSON.stringify(err)}`, Status.ERROR);
      promptAction.showToast({ message: 'Configuration parsing failed', duration: ToastDuration.MEDIUM });
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
