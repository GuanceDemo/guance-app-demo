import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import * as ftcrash from 'libftcrash.so';
import { FTRUMGlobalManager } from '@guancecloud/ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';
import { FTSDK } from '@guancecloud/ft_sdk/src/main/ets/components/FTSDK';
import { FTLogger } from '@guancecloud/ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from '@guancecloud/ft_sdk/src/main/ets/components/bean/Status';
import { ErrorType, AppState } from '@guancecloud/ft_sdk/src/main/ets/components/rum/enum/RUMEnums';
import { rcp } from '@kit.RemoteCommunicationKit';
import { http } from '@kit.NetworkKit';
import axios, { AxiosInstance, AxiosResponse } from '@ohos/axios';
import {
  createFTRCPTrackConfig,
  applyFTAxiosTrack
} from '@guancecloud/ft_sdk/src/main/ets/components/network/FTHttpAutoTrack';
import {
  applyFTHttpTrack,
  createFTHttpInterceptorChain
} from '@guancecloud/ft_sdk_ext/src/main/ets/components/network/FTHttpAutoTrackExt';
import OpenTelemetry from 'otel_sdk';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { API_USER_INFO } from '../constants/Constant';
import { AppNavBar } from '../components/AppNavBar';
import { FeatureCard } from '../components/FeatureCard';
import { FormSection } from '../components/FormSection';
import { ListCell } from '../components/ListCell';
import { AppColors, Spacing, ToastDuration } from '../constants/UIConstants';

/**
 * Property wrapper class - For ArkTS compatibility
 */
class PropertyWrapper {
  value: string | number | boolean;
  constructor(v: string | number | boolean) {
    this.value = v;
  }
}

/**
 * Property builder
 */
class RumPropertyBuilder {
  private properties: Record<string, object> = {} as Record<string, object>;

  set(key: string, value: string | number | boolean): void {
    this.properties[key] = new PropertyWrapper(value) as object;
  }

  toObject(): Record<string, object> {
    return this.properties;
  }
}

interface AxiosStylePostData {
  source: string;
  message: string;
  timestamp: number;
}

/**
 * Native page - Various test features
 */
@Entry
@Component
struct NativeManualPage {
  private initialAction: string = '';
  private initialActionConsumed: boolean = false;
  private pageMode: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.initialAction = params?.action || '';
    this.pageMode = params?.mode || '';
    if (!this.initialActionConsumed && this.initialAction === 'otel') {
      this.initialActionConsumed = true;
      setTimeout(() => {
        this.handleCreateOtelSpan();
      }, 300);
    }
  }

  build() {
    Column() {
      AppNavBar({
        title: this.pageMode === 'business' ? '业务体验' : '手动埋点示例',
        showBack: true,
        onBack: () => {
          router.back();
        }
      })

      Scroll() {
        Column() {
          if (this.pageMode === 'business') {
            this.BusinessExperienceContent()
          } else {
            this.ManualTrackingContent()
          }
        }
        .width('100%')
        .padding({
          left: Spacing.SCREEN_HORIZONTAL,
          right: Spacing.SCREEN_HORIZONTAL,
          top: Spacing.SECTION_GAP,
          bottom: Spacing.LG
        })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.PAGE_BACKGROUND)
  }

  @Builder
  BusinessExperienceContent() {
    this.BusinessIntro()

    FormSection({
      title: 'RUM View Test'
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Custom View Tracking',
      description: '开启自定义 View 并在 3 秒后结束。',
      iconText: 'V',
      iconColor: AppColors.SUCCESS,
      iconBgColor: AppColors.SUCCESS_SOFT,
      onTap: () => {
        this.handleCustomView();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FormSection({
      title: 'RUM Action Test'
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Add Custom Action',
      description: '立即上报一次自定义点击 Action。',
      iconText: 'A',
      iconColor: AppColors.INFO,
      iconBgColor: AppColors.INFO_SOFT,
      onTap: () => {
        this.handleCustomAction();
      }
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Action Start/Stop',
      description: '模拟一个持续 2 秒的自定义 Action。',
      iconText: 'A',
      iconColor: AppColors.INFO,
      iconBgColor: AppColors.INFO_SOFT,
      onTap: () => {
        this.handleActionStartStop();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FormSection({
      title: 'RUM Error Test'
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Add Custom Error',
      description: '手动上报一条自定义 RUM Error。',
      iconText: 'E',
      iconColor: AppColors.WARNING,
      iconBgColor: AppColors.ERROR_SOFT,
      onTap: () => {
        this.handleCustomError();
      }
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Crash Cpp',
      description: '触发 Native C++ 崩溃，用于崩溃采集验证。',
      iconText: 'C',
      iconColor: AppColors.WARNING,
      iconBgColor: AppColors.ERROR_SOFT,
      onTap: () => {
        this.handleCppCrash();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FormSection({
      title: 'RUM LongTask Test'
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'UIBlock(LongTask)',
      description: '阻塞主线程并手动上报 LongTask。',
      iconText: 'L',
      iconColor: AppColors.ORANGE,
      iconBgColor: AppColors.WARNING_SOFT,
      onTap: () => {
        this.handleLongTask();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FormSection({
      title: 'Log Test'
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Add Custom Log',
      description: '上报 INFO、WARN、ERROR、DEBUG 和自定义属性日志。',
      iconText: 'G',
      iconColor: AppColors.PURPLE,
      iconBgColor: AppColors.PURPLE_SOFT,
      onTap: () => {
        this.handleCustomLog();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FormSection({
      title: 'Global Tag Test'
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Add Global Tag',
      description: '追加全局 Context 与 RUM Context 标签。',
      iconText: 'T',
      iconColor: AppColors.CYAN,
      iconBgColor: AppColors.CYAN_SOFT,
      onTap: () => {
        this.handleGlobalTag();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FormSection({
      title: 'Network Request Test',
      description: '验证 RCP、NetworkKit HTTP 与 Axios 的自动 Resource/Trace 采集。'
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Send RCP Network Request',
      description: '使用 RCP Session 发起自动追踪请求。',
      iconText: 'R',
      iconColor: AppColors.INDIGO,
      iconBgColor: AppColors.INDIGO_SOFT,
      onTap: () => {
        this.handleNetworkRequest();
      }
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Send HTTP Interceptor Request',
      description: '使用 NetworkKit interceptor chain 验证 Resource。',
      iconText: 'H',
      iconColor: AppColors.INDIGO,
      iconBgColor: AppColors.INDIGO_SOFT,
      onTap: () => {
        this.handleHttpInterceptorRequest();
      }
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: 'Send Axios Request',
      description: '使用 Axios 自动追踪配置发起请求。',
      iconText: 'X',
      iconColor: AppColors.INDIGO,
      iconBgColor: AppColors.INDIGO_SOFT,
      onTap: () => {
        this.handleAxiosRequest();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FormSection({
      title: '链路关联请求'
    })
    .margin({ bottom: Spacing.SM })
    ListCell({
      title: '发起链路关联请求',
      description: '读取 Demo API 与 OTEL 配置，发起一次链路关联验证。',
      iconText: 'O',
      iconColor: AppColors.DEEP_PURPLE,
      iconBgColor: AppColors.DEEP_PURPLE_SOFT,
      onTap: () => {
        this.handleCreateOtelSpan();
      }
    })
  }

  @Builder
  ManualTrackingContent() {
    this.PageIntro()

    FeatureCard({
      title: '手动 Action',
      description: '对应 Android manual_action_btn，手动添加一次 RUM Action。',
      actionText: '手动 Action',
      accentColor: AppColors.INFO,
      accentBgColor: AppColors.INFO_SOFT,
      onTap: () => {
        this.handleManualAction();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FeatureCard({
      title: '手动网络设置',
      description: '对应 Android 手动 OKHttp 设置，使用 RCP 发起带 FT 自动追踪配置的请求。',
      actionText: '手动网络设置',
      accentColor: AppColors.INDIGO,
      accentBgColor: AppColors.INDIGO_SOFT,
      onTap: () => {
        this.handleNetworkRequest();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FeatureCard({
      title: '自定义 EventListener Interceptor',
      description: '对应 Android OKHttp 自定义 EventListener Interceptor，使用 NetworkKit interceptor chain 验证 Resource 采集。',
      actionText: '自定义 EventListener Interceptor',
      accentColor: AppColors.INDIGO,
      accentBgColor: AppColors.INDIGO_SOFT,
      onTap: () => {
        this.handleHttpInterceptorRequest();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FeatureCard({
      title: '手动 Trace Resource 自定义',
      description: '对应 Android 手动 Trace Resource OkHttp 自定义，使用 Axios interceptor chain 验证 Trace/Resource 关联。',
      actionText: '手动 Trace Resource 自定义',
      accentColor: AppColors.INDIGO,
      accentBgColor: AppColors.INDIGO_SOFT,
      onTap: () => {
        this.handleAxiosRequest();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FeatureCard({
      title: '手动 Trace Resource HTTP 自定义',
      description: '对应 Android HttpUrlConnection 自定义，使用 NetworkKit HTTP 请求验证 Resource 数据。',
      actionText: '手动 Trace Resource HTTP 自定义',
      accentColor: AppColors.INDIGO,
      accentBgColor: AppColors.INDIGO_SOFT,
      onTap: () => {
        this.handleHttpInterceptorRequest();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FeatureCard({
      title: '手动 Error',
      description: '对应 Android manual_error_btn，手动上报一条 RUM Error。',
      actionText: '手动 Error',
      accentColor: AppColors.WARNING,
      accentBgColor: AppColors.ERROR_SOFT,
      onTap: () => {
        this.handleCustomError();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })

    FeatureCard({
      title: '手动 LongTask',
      description: '对应 Android manual_longtask_btn，手动上报 LongTask。',
      actionText: '手动 LongTask',
      accentColor: AppColors.ORANGE,
      accentBgColor: AppColors.WARNING_SOFT,
      onTap: () => {
        this.handleLongTask();
      }
    })
    .margin({ bottom: Spacing.SECTION_GAP })
  }

  @Builder
  BusinessIntro() {
    FeatureCard({
      title: '业务体验',
      description: '保留完整 Native 验证功能列表，用于集中验证 RUM、Trace、Resource、Error、Crash、LongTask、Log 与全局 Tag。',
      accentColor: AppColors.PRIMARY,
      accentBgColor: AppColors.PRIMARY_SOFT
    })
    .margin({ bottom: Spacing.SECTION_GAP })
  }

  @Builder
  PageIntro() {
    FeatureCard({
      title: '打开手动埋点示例',
      description: '参考 Android ManualActivity，集中验证手动 Action、Resource、Trace、Error 与 LongTask。',
      accentColor: AppColors.PRIMARY,
      accentBgColor: AppColors.PRIMARY_SOFT
    })
    .margin({ bottom: Spacing.SECTION_GAP })
  }

  /**
   * Handle custom View tracking
   */
  async handleCustomView(): Promise<void> {
    const property = new RumPropertyBuilder();
    property.set('page_category', 'test');
    property.set('page_id', 'native_page_001');

    FTRUMGlobalManager.getInstance().startView('CustomView', property.toObject());
    promptAction.showToast({ message: 'Custom View tracking started', duration: ToastDuration.MEDIUM });

    // Stop after 3 seconds
    setTimeout(() => {
      FTRUMGlobalManager.getInstance().stopView();
      promptAction.showToast({ message: 'View tracking stopped', duration: ToastDuration.SHORT });
    }, 3000);
  }

  /**
   * Handle custom Action
   */
  handleManualAction(): void {
    const property = new RumPropertyBuilder();
    property.set('manual_source', 'NativeManualPage');
    property.set('android_reference', 'manual_action_btn');

    FTRUMGlobalManager.getInstance().addActionWithProperty('[action button]', 'click', property.toObject());
    promptAction.showToast({ message: '手动 Action 已添加', duration: ToastDuration.MEDIUM });
  }

  /**
   * Handle custom Action
   */
  handleCustomAction(): void {
    const property = new RumPropertyBuilder();
    property.set('button_name', 'custom_action');
    property.set('action_category', 'test');

    FTRUMGlobalManager.getInstance().addActionWithProperty('test_button_click', 'click', property.toObject());
    promptAction.showToast({ message: 'Custom Action added', duration: ToastDuration.MEDIUM });
  }

  /**
   * Handle Action start/stop
   */
  handleActionStartStop(): void {
    FTRUMGlobalManager.getInstance().startAction('long_operation', 'custom');
    promptAction.showToast({ message: 'Action started', duration: ToastDuration.SHORT });

    // Simulate time-consuming operation
    setTimeout(() => {
      FTRUMGlobalManager.getInstance().stopAction();
      promptAction.showToast({ message: 'Action stopped', duration: ToastDuration.MEDIUM });
    }, 2000);
  }

  /**
   * Handle custom Error
   */
  handleCustomError(): void {
    const property = new RumPropertyBuilder();
    property.set('error_code', 'TEST_001');
    property.set('error_category', 'custom');

    const stackTrace = `Error: Custom test error
    at NativeManualPage.handleCustomError (NativeManualPage.ets)
    at Button.onClick (NativeManualPage.ets)`;

    FTRUMGlobalManager.getInstance().addError(
      stackTrace,
      'This is a custom error for testing',
      ErrorType.CUSTOM,
      AppState.RUN,
      property.toObject()
    );
    promptAction.showToast({ message: 'Custom Error added', duration: ToastDuration.MEDIUM });
  }

  /**
   * Handle C++ crash test
   */
  handleCppCrash(): void {
    promptAction.showToast({ message: 'Triggering C++ crash...', duration: ToastDuration.SHORT });

    // Trigger C++ crash after a short delay
    setTimeout(() => {
      try {
        // Trigger null pointer dereference crash
        ftcrash.triggerNullPointerCrash();
      } catch (e) {
        console.error('C++ crash error:', e);
      }
    }, 500);
  }

  /**
   * Handle long task test
   */
  handleLongTask(): void {
    promptAction.showToast({ message: 'Starting long task execution...', duration: ToastDuration.SHORT });

    const startTime = Date.now();

    // Simulate 2-second long task, blocking main thread
    const start = Date.now();
    while (Date.now() - start < 2000) {
      // Block waiting for 2 seconds
    }

    const duration = (Date.now() - startTime) * 1000000; // Convert to nanoseconds

    // Manually add LongTask
    const longTaskProperty: Record<string, string | number | boolean> = {
      'task_type': 'ui_block',
      'task_duration': duration.toString()
    };

    FTRUMGlobalManager.getInstance().addLongTask('UI Block Task', duration, longTaskProperty);

    promptAction.showToast({ message: 'Long task completed', duration: ToastDuration.MEDIUM });
  }

  /**
   * Handle custom log
   */
  handleCustomLog(): void {
    // Test different log levels
    FTLogger.logBackground('This is an INFO level log', Status.INFO);
    FTLogger.logBackground('This is a WARNING level log', Status.WARN);
    FTLogger.logBackground('This is an ERROR level log', Status.ERROR);
    FTLogger.logBackground('This is a DEBUG level log', Status.DEBUG);

    // Log with properties - using Map<string, object>
    const property = new Map<string, object>();
    property.set('log_category', new PropertyWrapper('test') as object);
    property.set('log_source', new PropertyWrapper('native_page') as object);
    FTLogger.logBackground('Log with properties', Status.INFO, property);

    promptAction.showToast({ message: 'Custom log added', duration: ToastDuration.MEDIUM });
  }

  /**
   * Handle global tag
   */
  handleGlobalTag(): void {
    // Add global context tags
    const globalContext = new Map<string, string>();
    globalContext.set('platform', 'harmonyos');
    globalContext.set('version', '1.0.0');
    globalContext.set('build_type', 'debug');
    FTSDK.appendGlobalContext(globalContext);

    // Add RUM global tags
    const rumContext = new Map<string, string>();
    rumContext.set('user_type', 'vip');
    rumContext.set('channel', 'official');
    FTSDK.appendRUMGlobalContext(rumContext);

    promptAction.showToast({ message: 'Global tags added', duration: ToastDuration.MEDIUM });
  }

  /**
   * Handle network request test (using RCP auto tracking)
   */
  async handleNetworkRequest(): Promise<void> {
    promptAction.showToast({ message: 'Sending network request...', duration: ToastDuration.SHORT });

    try {
      const session = this.createRCPSession();

      const request = new rcp.Request('https://httpbin.org/get', 'GET');
      const response = await session.fetch(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        promptAction.showToast({ message: `Request successful: ${response.statusCode}`, duration: ToastDuration.MEDIUM });
      } else {
        promptAction.showToast({ message: `Request failed: ${response.statusCode}`, duration: ToastDuration.MEDIUM });
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('Network request failed:', err.message || String(error));
      promptAction.showToast({ message: 'Network request failed', duration: ToastDuration.MEDIUM });
    }
  }

  /**
   * Handle NetworkKit http request test (using interceptor chain auto tracking)
   */
  async handleHttpInterceptorRequest(): Promise<void> {
    promptAction.showToast({ message: 'Sending http interceptor request...', duration: ToastDuration.SHORT });

    try {
      const response = await this.executeHttpRequest('https://httpbin.org/post', {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify({
          source: 'network_kit_http',
          message: 'Testing FT http interceptor chain',
          timestamp: Date.now()
        })
      });

      if (response.responseCode >= 200 && response.responseCode < 300) {
        promptAction.showToast({ message: `HTTP request successful: ${response.responseCode}`, duration: ToastDuration.MEDIUM });
      } else {
        promptAction.showToast({ message: `HTTP request failed: ${response.responseCode}`, duration: ToastDuration.MEDIUM });
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('HTTP interceptor request failed:', err.message || String(error));
      promptAction.showToast({ message: 'HTTP interceptor request failed', duration: ToastDuration.MEDIUM });
    }
  }

  /**
   * Handle axios request test (using interceptorChain adapter auto tracking)
   */
  async handleAxiosRequest(): Promise<void> {
    promptAction.showToast({ message: 'Sending axios request...', duration: ToastDuration.SHORT });

    try {
      const payload: AxiosStylePostData = {
        source: 'axios',
        message: 'Testing FT axios auto track',
        timestamp: Date.now()
      };
      const responseText = await this.executeAxiosRequest('https://httpbin.org/post', payload);
      promptAction.showToast({ message: `Axios request successful: ${responseText.length} chars`, duration: ToastDuration.MEDIUM });
    } catch (error) {
      const err = error as BusinessError;
      console.error('Axios request failed:', err.message || String(error));
      promptAction.showToast({ message: 'Axios request failed', duration: ToastDuration.MEDIUM });
    }
  }

  /**
   * Handle create OTEL span test
   * Similar to Android's createSpanWithOtel functionality
   */
  async handleCreateOtelSpan(): Promise<void> {
    promptAction.showToast({ message: '正在发起链路关联请求...', duration: ToastDuration.MEDIUM });

    try {
      const session = this.createRCPSession();
      await this.sendRequestAndCreateSpan(session);
    } catch (error) {
      const errorObj: Error = error as Error;
      console.error('OTEL span creation failed:', errorObj.message);
      promptAction.showToast({ message: '链路关联请求失败', duration: ToastDuration.MEDIUM });
    }
  }

  private createRCPSession(): rcp.Session {
    return rcp.createSession(createFTRCPTrackConfig());
  }

  private async executeHttpRequest(
    url: string,
    options: http.HttpRequestOptions = {}
  ): Promise<http.HttpResponse> {
    const request = http.createHttp();
    applyFTHttpTrack(request);
    try {
      return await request.request(url, options);
    } finally {
      request.destroy();
    }
  }

  private createAxiosInstance(): AxiosInstance {
    const client =  axios.create({
      timeout: 10000,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
    applyFTAxiosTrack(client);
    return client
  }

  private async executeAxiosRequest(
    url: string,
    data: AxiosStylePostData
  ): Promise<string> {
    const client = this.createAxiosInstance();
    const response: AxiosResponse<string | Object, AxiosStylePostData> = await client.request<
      string | Object,
      AxiosResponse<string | Object, AxiosStylePostData>,
      AxiosStylePostData
    >({
      url: url,
      method: 'post',
      data: data,
      responseType: 'string',
      interceptorChain: createFTHttpInterceptorChain()
    });

    return typeof response.data === 'string'
      ? response.data
      : JSON.stringify(response.data);
  }

  /**
   * Send request and create span with trace context
   */
  private async sendRequestAndCreateSpan(session: rcp.Session): Promise<void> {
    try {
      // Read configuration from settings
      const setting = await SettingConfigManager.readSetting();

      // Get OTEL address from settings
      const otelEndpoint = setting.otelAddress || 'http://localhost:4318/v1/traces';

      // Build user info URL from Demo API address
      const userInfoUrl = setting.demoApiAddress + API_USER_INFO;

      console.info('OTEL Endpoint:', otelEndpoint);
      console.info('User Info URL:', userInfoUrl);

      // Initialize OTEL SDK with configured endpoint
      OpenTelemetry.initialize(otelEndpoint, 'ft-sdk-demo');

      // Send request to user info endpoint (similar to Android's userinfoWithOtel)
      const request = new rcp.Request(userInfoUrl, 'GET');
      const response = await session.fetch(request);

      console.info('Response status:', response.statusCode);
      console.info('Response headers:', JSON.stringify(response.headers));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Get trace_id and span_id from response headers
        const headers = response.headers as Record<string, string>;
        let traceId = headers['trace_id'];
        let parentId = headers['span_id'];

        // Store original decimal values for logging and attributes
        let originalTraceId = traceId;
        let originalParentId = parentId;

        // If using ddtrace, convert IDs to proper format (hex format for OpenTelemetry)
        if (traceId && parentId) {
          traceId = this.convert64To128Bit(traceId);
          parentId = this.convertHex(parentId);
        }

        // If no trace headers, generate mock IDs for testing
        if (!originalTraceId || !originalParentId) {
          console.warn('No trace headers in response, using mock IDs');
          originalTraceId = this.generateMockTraceIdDecimal();
          originalParentId = this.generateMockParentSpanIdDecimal();
          // Convert mock IDs to hex format for OpenTelemetry
          traceId = this.convert64To128Bit(originalTraceId);
          parentId = this.convertHex(originalParentId);
        }

        // Log trace info in decimal format (like Android)
        console.info('FT_SDK_< originalTraceId:', originalTraceId);
        console.info('< span_id:', originalParentId);


        console.info('FT_SDK_< traceId:', traceId);
        console.info('< span_id:', originalParentId);



        // Create span with backend's trace_id and parent_span_id
        // Matches Android's createSpanWithOtel: simple child span creation
        let spanId: string = '';
        try {
          spanId = OpenTelemetry.startSpanWithParent('add.action.after_request', traceId, parentId);
          console.info('Created span with backend trace_id:', traceId, 'parent_span_id:', parentId);
        } catch (e) {
          // Fallback: use startSpan (independent span)
          const errorObj = e as Error;
          console.warn('startSpanWithParent failed, error:', errorObj.message);
          console.warn('Fallback: using startSpan (independent span)');
          spanId = OpenTelemetry.startSpan('add.action.after_request');
        }

        if (spanId && spanId.length > 0) {
          // Add additional attributes
          OpenTelemetry.setSpanAttribute(spanId, 'custom.has_parent', 'true');
          OpenTelemetry.setSpanAttribute(spanId, 'action.type', 'after_request');
          OpenTelemetry.setSpanAttribute(spanId, 'platform', 'harmonyos');

          // End the span
          OpenTelemetry.endSpan(spanId);

          promptAction.showToast({ message: '链路关联请求已完成', duration: ToastDuration.MEDIUM });
        } else {
          promptAction.showToast({ message: '链路关联请求失败', duration: ToastDuration.MEDIUM });
        }
      } else {
        promptAction.showToast({ message: `Request failed: ${response.statusCode}`, duration: ToastDuration.MEDIUM });
      }
    } catch (error) {
      const errorObj: Error = error as Error;
      console.error('Send request failed:', errorObj.message);
      throw new Error(`OTEL request failed: ${errorObj.message}`);
    }
  }

  /**
   * Convert 64-bit trace ID to 128-bit hex format
   * Similar to Android's convert64To128Bit method
   */
  private convert64To128Bit(traceId64: string): string {
    try {
      // Convert to big integer and pad to 16 hex chars
      const bigIntVal = BigInt(traceId64);
      const hexPart = bigIntVal.toString(16).padStart(16, '0');
      // Prefix with 16 zeros to make 32 chars (128-bit)
      return '0000000000000000' + hexPart;
    } catch (e) {
      console.error('Failed to convert trace ID:', e);
      return this.generateMockTraceId();
    }
  }

  /**
   * Convert span ID to hex format
   * Similar to Android's convertHex method
   */
  private convertHex(spanId: string): string {
    try {
      const bigIntVal = BigInt(spanId);
      return bigIntVal.toString(16).padStart(16, '0');
    } catch (e) {
      console.error('Failed to convert span ID:', e);
      return this.generateMockParentSpanId();
    }
  }

  /**
   * Generate mock 128-bit trace ID (32 hex characters)
   * For fallback when conversion fails
   */
  private generateMockTraceId(): string {
    // Generate a random 128-bit trace ID
    // Format: 0000000000000000 + 16 hex chars
    const randomPart = Math.floor(Math.random() * 0xFFFFFFFFFFFFFFFF).toString(16).padStart(16, '0');
    return '0000000000000000' + randomPart;
  }

  /**
   * Generate mock 64-bit parent span ID (16 hex characters)
   * For fallback when conversion fails
   */
  private generateMockParentSpanId(): string {
    // Generate a random 64-bit span ID
    return Math.floor(Math.random() * 0xFFFFFFFFFFFFFFFF).toString(16).padStart(16, '0');
  }

  /**
   * Generate mock trace ID in decimal format (for logging)
   */
  private generateMockTraceIdDecimal(): string {
    // Generate a random 64-bit trace ID in decimal format
    return Math.floor(Math.random() * Number.MAX_SAFE_INTEGER).toString();
  }

  /**
   * Generate mock parent span ID in decimal format (for logging)
   */
  private generateMockParentSpanIdDecimal(): string {
    // Generate a random 64-bit span ID in decimal format
    return Math.floor(Math.random() * Number.MAX_SAFE_INTEGER).toString();
  }
}
