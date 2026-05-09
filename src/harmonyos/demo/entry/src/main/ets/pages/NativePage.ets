import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import * as ftcrash from 'libftcrash.so';
import { rcp } from '@kit.RemoteCommunicationKit';
import { FTRUMGlobalManager } from '@guancecloud/ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';
import { createFTRCPTrackConfig } from '@guancecloud/ft_sdk/src/main/ets/components/network/FTHttpAutoTrack';
import OpenTelemetry from 'otel_sdk';
import { AppColors, BorderRadius, FontSizes, Spacing } from '../constants/UIConstants';
import { AppNavBar } from '../components/AppNavBar';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { FTSDKManager } from '../manager/FTSDKManager';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { API_USER_INFO, KEY_DYNAMIC_TAG } from '../constants/Constant';

interface NativeDemoItem {
  title: string;
  description: string;
  action: string;
}

@Entry
@Component
struct NativePage {
  private businessItems: NativeDemoItem[] = [
    {
      title: 'ArkUI 原生控件演示',
      description: '进入原生组件页，验证 View、Action 与 Session Replay 对控件状态的采集。',
      action: 'arkui'
    },
    {
      title: 'Session Replay 示例',
      description: '打开表单、列表、弹窗等典型原生控件页面，检查回放可视化效果。',
      action: 'sessionReplay'
    },
    {
      title: '切换动态用户标签',
      description: '对齐 Android Demo，设置 dynamic_tag 为 set from dynamic，并验证后续 RUM 数据携带动态标签。',
      action: 'dynamicTag'
    },
    {
      title: '发起链路关联请求',
      description: '对齐 Android Demo，请求 Demo API 后创建关联 OTEL Span，验证 RUM 与 Trace 串联。',
      action: 'otel'
    },
    {
      title: '打开手动埋点示例',
      description: '对齐 Android ManualActivity，验证手动 Action、Resource、Trace、Error、LongTask。',
      action: 'manual'
    },
    {
      title: '业务体验',
      description: '打开完整 Native 验证功能列表，覆盖 RUM、Session Replay、Trace、Resource、Error、LongTask 等能力。',
      action: 'businessExperience'
    }
  ];

  private labItems: NativeDemoItem[] = [
    {
      title: '触发 ArkTS Crash',
      description: '该操作会让应用退出，用于验证 ArkTS Crash 采集。',
      action: 'arktsCrash'
    },
    {
      title: '触发 Native C/C++ Crash',
      description: '该操作会触发 C/C++ 层崩溃，用于验证 Native Crash 采集。',
      action: 'cppCrash'
    },
    {
      title: '触发 UIBlock LongTask',
      description: '阻塞主线程 2 秒，并手动上报 LongTask。',
      action: 'longTask'
    }
  ];

  build() {
    Column() {
      AppNavBar({
        title: 'Native Demo',
        showBack: true,
        onBack: () => {
          router.back();
        }
      })

      Scroll() {
        Column() {
          this.SectionHeader('业务场景', '贴近真实使用路径的原生页面与链路演示。')
          ForEach(this.businessItems, (item: NativeDemoItem) => {
            this.ActionItem(item)
          }, (item: NativeDemoItem) => item.action)

          Divider()
            .strokeWidth(1)
            .color(AppColors.DIVIDER)
            .margin({ top: Spacing.LG, bottom: Spacing.MD })

          this.SectionHeader('Crash Lab', '以下操作可能阻塞或退出应用，适合单独验证异常采集。')
          ForEach(this.labItems, (item: NativeDemoItem) => {
            this.ActionItem(item)
          }, (item: NativeDemoItem) => item.action)
        }
        .width('100%')
        .padding(Spacing.MD)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  SectionHeader(title: string, description: string) {
    Column() {
      Text(title)
        .fontSize(FontSizes.MEDIUM)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      Text(description)
        .fontSize(FontSizes.SMALL)
        .fontColor(AppColors.TEXT_HINT)
        .width('100%')
        .margin({ top: Spacing.XS, bottom: Spacing.SM })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  ActionItem(item: NativeDemoItem) {
    Column() {
      Text(item.title)
        .fontSize(FontSizes.MEDIUM)
        .fontColor(AppColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Text(item.description)
        .fontSize(FontSizes.SMALL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ top: Spacing.XS })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
    .onClick(() => {
      this.handleItemAction(item.action);
    })
  }

  private handleItemAction(action: string): void {
    switch (action) {
      case 'businessExperience':
        router.pushUrl({ url: 'pages/NativeManualPage', params: { mode: 'business' } });
        break;
      case 'arkui':
        router.pushUrl({ url: 'pages/NativeArkUIDemoPage' });
        break;
      case 'sessionReplay':
        router.pushUrl({ url: 'pages/NativeSessionReplayPage' });
        break;
      case 'dynamicTag':
        this.handleDynamicTag();
        break;
      case 'otel':
        this.handleCreateLinkedTraceRequest();
        break;
      case 'manual':
        router.pushUrl({ url: 'pages/NativeManualPage' });
        break;
      case 'arktsCrash':
        this.showRiskDialog('确认 ArkTS Crash', '该操作会让应用退出，用于验证 ArkTS Crash 采集。', () => {
          setTimeout(() => {
            throw new Error('Native Demo ArkTS crash');
          }, 300);
        });
        break;
      case 'cppCrash':
        this.showRiskDialog('确认 Native Crash', '该操作会触发 C/C++ 层崩溃，用于验证 Native Crash 采集。', () => {
          setTimeout(() => {
            ftcrash.triggerNullPointerCrash();
          }, 300);
        });
        break;
      case 'longTask':
        this.showRiskDialog('确认 LongTask', '该操作会阻塞主线程 2 秒，用于验证 UIBlock/LongTask 采集。', () => {
          this.handleLongTask();
        });
        break;
    }
  }

  private async handleDynamicTag(): Promise<void> {
    await PreferencesUtil.putString(KEY_DYNAMIC_TAG, 'set from dynamic');
    await FTSDKManager.getInstance().reInitSDK();

    promptAction.showToast({ message: '动态用户标签已切换，正在返回首页', duration: 1500 });

    setTimeout(() => {
      router.replaceUrl({ url: 'pages/MainPage' });
    }, 1500);
  }

  private async handleCreateLinkedTraceRequest(): Promise<void> {
    promptAction.showToast({ message: '正在发起链路关联请求...', duration: 1500 });

    try {
      const setting = await SettingConfigManager.readSetting();
      const otelEndpoint = setting.otelAddress || 'http://localhost:4318/v1/traces';
      const userInfoUrl = setting.demoApiAddress + API_USER_INFO;

      OpenTelemetry.initialize(otelEndpoint, 'ft-sdk-demo');

      const session = rcp.createSession(createFTRCPTrackConfig());
      const request = new rcp.Request(userInfoUrl, 'GET');
      const response = await session.fetch(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        const headers = response.headers as Record<string, string>;
        let traceId = headers['trace_id'];
        let parentId = headers['span_id'];

        if (traceId && parentId) {
          traceId = this.convert64To128Bit(traceId);
          parentId = this.convertHex(parentId);
        }

        if (!traceId || !parentId) {
          traceId = this.generateMockTraceId();
          parentId = this.generateMockParentSpanId();
        }

        let spanId = '';
        try {
          spanId = OpenTelemetry.startSpanWithParent('add.action.after_request', traceId, parentId);
        } catch (error) {
          const errorObj = error as Error;
          console.warn('startSpanWithParent failed:', errorObj.message);
          spanId = OpenTelemetry.startSpan('add.action.after_request');
        }

        if (spanId.length > 0) {
          OpenTelemetry.setSpanAttribute(spanId, 'custom.has_parent', 'true');
          OpenTelemetry.setSpanAttribute(spanId, 'action.type', 'after_request');
          OpenTelemetry.setSpanAttribute(spanId, 'platform', 'harmonyos');
          OpenTelemetry.endSpan(spanId);
          promptAction.showToast({ message: '链路关联请求已完成', duration: 1500 });
        } else {
          promptAction.showToast({ message: '链路关联请求失败', duration: 1500 });
        }
      } else {
        promptAction.showToast({ message: `链路关联请求失败: ${response.statusCode}`, duration: 1500 });
      }
    } catch (error) {
      const errorObj = error as Error;
      console.error('Linked trace request failed:', errorObj.message);
      promptAction.showToast({ message: '链路关联请求失败', duration: 1500 });
    }
  }

  private convert64To128Bit(traceId64: string): string {
    try {
      const bigIntVal = BigInt(traceId64);
      const hexPart = bigIntVal.toString(16).padStart(16, '0');
      return '0000000000000000' + hexPart;
    } catch (error) {
      console.error('Failed to convert trace ID:', error);
      return this.generateMockTraceId();
    }
  }

  private convertHex(spanId: string): string {
    try {
      const bigIntVal = BigInt(spanId);
      return bigIntVal.toString(16).padStart(16, '0');
    } catch (error) {
      console.error('Failed to convert span ID:', error);
      return this.generateMockParentSpanId();
    }
  }

  private generateMockTraceId(): string {
    const randomPart = Math.floor(Math.random() * 0xFFFFFFFFFFFFFFFF).toString(16).padStart(16, '0');
    return '0000000000000000' + randomPart;
  }

  private generateMockParentSpanId(): string {
    return Math.floor(Math.random() * 0xFFFFFFFFFFFFFFFF).toString(16).padStart(16, '0');
  }

  private handleLongTask(): void {
    promptAction.showToast({ message: '开始阻塞主线程...', duration: 1000 });
    const startTime = Date.now();
    while (Date.now() - startTime < 2000) {
    }

    const duration = (Date.now() - startTime) * 1000000;
    FTRUMGlobalManager.getInstance().addLongTask('Native Demo UIBlock', duration, {
      task_type: 'entry_uiblock',
      task_duration: duration.toString()
    });
    promptAction.showToast({ message: 'LongTask 已触发', duration: 1500 });
  }

  private showRiskDialog(title: string, message: string, onConfirm: () => void): void {
    AlertDialog.show({
      title: title,
      message: message,
      primaryButton: {
        value: '确认',
        action: () => {
          onConfirm();
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
  }
}
