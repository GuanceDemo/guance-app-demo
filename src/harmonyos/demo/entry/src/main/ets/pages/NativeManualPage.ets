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
        .padding({ top: 12, bottom: 16 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  BusinessExperienceContent() {
    this.BusinessIntro()

    this.SectionLabel('RUM View Test')
    this.ActionButton('Custom View Tracking', '#4CAF50', () => {
      this.handleCustomView();
    })

    this.SectionLabel('RUM Action Test')
    this.ActionButton('Add Custom Action', '#2196F3', () => {
      this.handleCustomAction();
    })
    this.ActionButton('Action Start/Stop', '#2196F3', () => {
      this.handleActionStartStop();
    })

    this.SectionLabel('RUM Error Test')
    this.ActionButton('Add Custom Error', '#F44336', () => {
      this.handleCustomError();
    })
    this.ActionButton('Crash Cpp', '#F44336', () => {
      this.handleCppCrash();
    })

    this.SectionLabel('RUM LongTask Test')
    this.ActionButton('UIBlock(Longtask)', '#FF9800', () => {
      this.handleLongTask();
    })

    this.SectionLabel('Log Test')
    this.ActionButton('Add Custom Log', '#9C27B0', () => {
      this.handleCustomLog();
    })

    this.SectionLabel('Global Tag Test')
    this.ActionButton('Add Global Tag', '#00BCD4', () => {
      this.handleGlobalTag();
    })

    this.SectionLabel('Network Request Test (Auto Track)')
    this.ActionButton('Send RCP Network Request', '#3F51B5', () => {
      this.handleNetworkRequest();
    })
    this.ActionButton('Send HTTP Interceptor Request', '#3F51B5', () => {
      this.handleHttpInterceptorRequest();
    })
    this.ActionButton('Send Axios Request', '#3F51B5', () => {
      this.handleAxiosRequest();
    })

    this.SectionLabel('链路关联请求')
    this.ActionButton('发起链路关联请求', '#673AB7', () => {
      this.handleCreateOtelSpan();
    })
  }

  @Builder
  ManualTrackingContent() {
    this.PageIntro()

    this.ManualButton('手动 Action', '对应 Android manual_action_btn，手动添加一次 RUM Action。', '#2196F3', () => {
      this.handleManualAction();
    })

    this.ManualButton('手动网络设置', '对应 Android 手动 OKHttp 设置，使用 RCP 发起带 FT 自动追踪配置的请求。', '#3F51B5', () => {
      this.handleNetworkRequest();
    })

    this.ManualButton('自定义 EventListener Interceptor', '对应 Android OKHttp 自定义 EventListener Interceptor，使用 NetworkKit interceptor chain 验证 Resource 采集。', '#3F51B5', () => {
      this.handleHttpInterceptorRequest();
    })

    this.ManualButton('手动 Trace Resource 自定义', '对应 Android 手动 Trace Resource OkHttp 自定义，使用 Axios interceptor chain 验证 Trace/Resource 关联。', '#3F51B5', () => {
      this.handleAxiosRequest();
    })

    this.ManualButton('手动 Trace Resource HTTP 自定义', '对应 Android HttpUrlConnection 自定义，使用 NetworkKit HTTP 请求验证 Resource 数据。', '#3F51B5', () => {
      this.handleHttpInterceptorRequest();
    })

    this.ManualButton('手动 Error', '对应 Android manual_error_btn，手动上报一条 RUM Error。', '#F44336', () => {
      this.handleCustomError();
    })

    this.ManualButton('手动 LongTask', '对应 Android manual_longtask_btn，手动上报 LongTask。', '#FF9800', () => {
      this.handleLongTask();
    })
  }

  @Builder
  BusinessIntro() {
    Column() {
      Text('业务体验')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')

      Text('保留完整 Native 验证功能列表，用于集中验证 RUM、Trace、Resource、Error、Crash、LongTask、Log 与全局 Tag。')
        .fontSize(13)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('calc(100% - 32vp)')
    .padding(12)
    .margin({ left: 16, right: 16, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  @Builder
  SectionLabel(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor('#666666')
      .width('100%')
      .margin({ top: 16, left: 16, bottom: 8 })
  }

  @Builder
  ActionButton(title: string, color: string, onClick: () => void) {
    Button(title)
      .width('calc(100% - 32vp)')
      .fontSize(16)
      .backgroundColor(color)
      .fontColor('#FFFFFF')
      .borderRadius(8)
      .margin({ top: 0, left: 16, right: 16, bottom: 12 })
      .onClick(() => {
        onClick();
      })
  }

  @Builder
  PageIntro() {
    Column() {
      Text('打开手动埋点示例')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')

      Text('参考 Android ManualActivity，集中验证手动 Action、Resource、Trace、Error 与 LongTask。')
        .fontSize(13)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('calc(100% - 32vp)')
    .padding(12)
    .margin({ left: 16, right: 16, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  @Builder
  ManualButton(title: string, description: string, color: string, onClick: () => void) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')

      Text(description)
        .fontSize(12)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 4, bottom: 10 })

      Button(title)
        .width('100%')
        .height(42)
        .fontSize(15)
        .backgroundColor(color)
        .fontColor('#FFFFFF')
        .borderRadius(8)
        .onClick(() => {
          onClick();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('calc(100% - 32vp)')
    .padding(12)
    .margin({ left: 16, right: 16, top: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  /**
   * Handle custom View tracking
   */
  async handleCustomView(): Promise<void> {
    const property = new RumPropertyBuilder();
    property.set('page_category', 'test');
    property.set('page_id', 'native_page_001');

    FTRUMGlobalManager.getInstance().startView('CustomView', property.toObject());
    promptAction.showToast({ message: 'Custom View tracking started', duration: 1500 });

    // Stop after 3 seconds
    setTimeout(() => {
      FTRUMGlobalManager.getInstance().stopView();
      promptAction.showToast({ message: 'View tracking stopped', duration: 1000 });
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
    promptAction.showToast({ message: '手动 Action 已添加', duration: 1500 });
  }

  /**
   * Handle custom Action
   */
  handleCustomAction(): void {
    const property = new RumPropertyBuilder();
    property.set('button_name', 'custom_action');
    property.set('action_category', 'test');

    FTRUMGlobalManager.getInstance().addActionWithProperty('test_button_click', 'click', property.toObject());
    promptAction.showToast({ message: 'Custom Action added', duration: 1500 });
  }

  /**
   * Handle Action start/stop
   */
  handleActionStartStop(): void {
    FTRUMGlobalManager.getInstance().startAction('long_operation', 'custom');
    promptAction.showToast({ message: 'Action started', duration: 1000 });

    // Simulate time-consuming operation
    setTimeout(() => {
      FTRUMGlobalManager.getInstance().stopAction();
      promptAction.showToast({ message: 'Action stopped', duration: 1500 });
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
    promptAction.showToast({ message: 'Custom Error added', duration: 1500 });
  }

  /**
   * Handle C++ crash test
   */
  handleCppCrash(): void {
    promptAction.showToast({ message: 'Triggering C++ crash...', duration: 1000 });

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
    promptAction.showToast({ message: 'Starting long task execution...', duration: 1000 });

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

    promptAction.showToast({ message: 'Long task completed', duration: 1500 });
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

    promptAction.showToast({ message: 'Custom log added', duration: 1500 });
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

    promptAction.showToast({ message: 'Global tags added', duration: 1500 });
  }

  /**
   * Handle network request test (using RCP auto tracking)
   */
  async handleNetworkRequest(): Promise<void> {
    promptAction.showToast({ message: 'Sending network request...', duration: 1000 });

    try {
      const session = this.createRCPSession();

      const request = new rcp.Request('https://httpbin.org/get', 'GET');
      const response = await session.fetch(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        promptAction.showToast({ message: `Request successful: ${response.statusCode}`, duration: 1500 });
      } else {
        promptAction.showToast({ message: `Request failed: ${response.statusCode}`, duration: 1500 });
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('Network request failed:', err.message || String(error));
      promptAction.showToast({ message: 'Network request failed', duration: 1500 });
    }
  }

  /**
   * Handle NetworkKit http request test (using interceptor chain auto tracking)
   */
  async handleHttpInterceptorRequest(): Promise<void> {
    promptAction.showToast({ message: 'Sending http interceptor request...', duration: 1000 });

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
        promptAction.showToast({ message: `HTTP request successful: ${response.responseCode}`, duration: 1500 });
      } else {
        promptAction.showToast({ message: `HTTP request failed: ${response.responseCode}`, duration: 1500 });
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('HTTP interceptor request failed:', err.message || String(error));
      promptAction.showToast({ message: 'HTTP interceptor request failed', duration: 1500 });
    }
  }

  /**
   * Handle axios request test (using interceptorChain adapter auto tracking)
   */
  async handleAxiosRequest(): Promise<void> {
    promptAction.showToast({ message: 'Sending axios request...', duration: 1000 });

    try {
      const payload: AxiosStylePostData = {
        source: 'axios',
        message: 'Testing FT axios auto track',
        timestamp: Date.now()
      };
      const responseText = await this.executeAxiosRequest('https://httpbin.org/post', payload);
      promptAction.showToast({ message: `Axios request successful: ${responseText.length} chars`, duration: 1500 });
    } catch (error) {
      const err = error as BusinessError;
      console.error('Axios request failed:', err.message || String(error));
      promptAction.showToast({ message: 'Axios request failed', duration: 1500 });
    }
  }

  /**
   * Handle create OTEL span test
   * Similar to Android's createSpanWithOtel functionality
   */
  async handleCreateOtelSpan(): Promise<void> {
    promptAction.showToast({ message: '正在发起链路关联请求...', duration: 1500 });

    try {
      const session = this.createRCPSession();
      await this.sendRequestAndCreateSpan(session);
    } catch (error) {
      const errorObj: Error = error as Error;
      console.error('OTEL span creation failed:', errorObj.message);
      promptAction.showToast({ message: '链路关联请求失败', duration: 1500 });
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

          promptAction.showToast({ message: '链路关联请求已完成', duration: 1500 });
        } else {
          promptAction.showToast({ message: '链路关联请求失败', duration: 1500 });
        }
      } else {
        promptAction.showToast({ message: `Request failed: ${response.statusCode}`, duration: 1500 });
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
