import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import * as ftcrash from 'libftcrash.so';
import { FTRUMGlobalManager } from 'ft_sdk/src/main/ets/components/rum/FTRUMGlobalManager';
import { FTSDK } from 'ft_sdk/src/main/ets/components/FTSDK';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';
import { ErrorType, AppState } from 'ft_sdk/src/main/ets/components/rum/enum/RUMEnums';
import { rcp } from '@kit.RemoteCommunicationKit';
import { http } from '@kit.NetworkKit';
import axios, { AxiosInstance, AxiosResponse } from '@ohos/axios';
import {
  applyFTHttpTrack,
  createFTHttpInterceptorChain,
  createFTRCPTrackConfig
} from 'ft_sdk/src/main/ets/components/network/FTHttpAutoTrack';
import OpenTelemetry from 'otel_sdk';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { API_USER_INFO } from '../constants/Constant';

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
struct NativePage {
  aboutToAppear(): void {
    // View tracking is now handled automatically by FTSDK
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

        Text('Native View')
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
          // ===== RUM View Test =====
          Text('RUM View Test')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 16, left: 16, bottom: 8 })

          Button('Custom View Tracking')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#4CAF50')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.handleCustomView();
            })

          // ===== RUM Action Test =====
          Text('RUM Action Test')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 16, left: 16, bottom: 8 })

          Button('Add Custom Action')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#2196F3')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.handleCustomAction();
            })

          Button('Action Start/Stop')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#2196F3')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ top: 12, left: 16, right: 16 })
            .onClick(() => {
              this.handleActionStartStop();
            })

          // ===== RUM Error Test =====
          Text('RUM Error Test')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 16, left: 16, bottom: 8 })

          Button('Add Custom Error')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#F44336')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.handleCustomError();
            })

          Button('Crash Cpp')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#F44336')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ top: 12, left: 16, right: 16 })
            .onClick(() => {
              this.handleCppCrash();
            })

          // ===== RUM LongTask Test =====
          Text('RUM LongTask Test')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 16, left: 16, bottom: 8 })

          Button('UIBlock(Longtask)')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#FF9800')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.handleLongTask();
            })

          // ===== Log Test =====
          Text('Log Test')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 16, left: 16, bottom: 8 })

          Button('Add Custom Log')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#9C27B0')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.handleCustomLog();
            })

          // ===== Global Tag Test =====
          Text('Global Tag Test')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 16, left: 16, bottom: 8 })

          Button('Add Global Tag')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#00BCD4')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.handleGlobalTag();
            })

          // ===== Network Request Test =====
          Text('Network Request Test (Auto Track)')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 16, left: 16, bottom: 8 })

          Button('Send Network Request')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#3F51B5')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.handleNetworkRequest();
            })

          Button('Send HTTP Interceptor Request')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#3F51B5')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ top: 12, left: 16, right: 16 })
            .onClick(() => {
              this.handleHttpInterceptorRequest();
            })

          Button('Send Axios Request')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#3F51B5')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ top: 12, left: 16, right: 16 })
            .onClick(() => {
              this.handleAxiosRequest();
            })

          // ===== OTEL Test =====
          Text('OpenTelemetry Test')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 16, left: 16, bottom: 8 })

          Button('Create OTEL Span')
            .width('calc(100% - 32vp)')
            .fontSize(16)
            .backgroundColor('#673AB7')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .margin({ left: 16, right: 16, bottom: 16 })
            .onClick(() => {
              this.handleCreateOtelSpan();
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
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
    at NativePage.handleCustomError (NativePage.ets:175)
    at Button.onClick (NativePage.ets:125)`;

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
    promptAction.showToast({ message: 'Sending request with OTEL headers...', duration: 1500 });

    try {
      const session = this.createRCPSession();
      await this.sendRequestAndCreateSpan(session);
    } catch (error) {
      const errorObj: Error = error as Error;
      console.error('OTEL span creation failed:', errorObj.message);
      promptAction.showToast({ message: 'OTEL span creation failed', duration: 1500 });
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
    return axios.create({
      interceptorChain: createFTHttpInterceptorChain(),
      timeout: 10000,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
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

          promptAction.showToast({ message: 'OTEL Span created!', duration: 1500 });
        } else {
          promptAction.showToast({ message: 'Failed to create OTEL Span', duration: 1500 });
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
