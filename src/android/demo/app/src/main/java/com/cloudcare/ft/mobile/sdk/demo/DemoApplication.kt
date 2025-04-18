package com.cloudcare.ft.mobile.sdk.demo

//import io.opentelemetry.context.Context
import android.app.Application
import android.content.Context
import com.cloudcare.ft.mobile.sdk.demo.data.AccessType
import com.cloudcare.ft.mobile.sdk.demo.http.HttpEngine
import com.cloudcare.ft.mobile.sdk.demo.manager.SettingConfigManager
import com.ft.sdk.DeviceMetricsMonitorType
import com.ft.sdk.ErrorMonitorType
import com.ft.sdk.FTLoggerConfig
import com.ft.sdk.FTRUMConfig
import com.ft.sdk.FTSDKConfig
import com.ft.sdk.FTSdk
import com.ft.sdk.FTTraceConfig
import io.opentelemetry.api.GlobalOpenTelemetry
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.SpanContext
import io.opentelemetry.api.trace.TraceFlags
import io.opentelemetry.api.trace.TraceState
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.propagation.ContextPropagators
import io.opentelemetry.exporter.otlp.http.trace.OtlpHttpSpanExporter
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.resources.Resource
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor


/**
 * BY huangDianHua
 * DATE:2019-12-13 11:44
 * Description:
 */
open class DemoApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        setSDK(this)
        setOtelSDK()
    }

    companion object {
        private const val CUSTOM_STATIC_TAG = "static_tag"
        private const val CUSTOM_DYNAMIC_TAG = "dynamic_tag"
        private const val SP_STORE_DATA = "store_data"

        fun setSDK(context: Context) {
            val data = SettingConfigManager.readSetting()
            HttpEngine.initAPIAddress(data.demoApiAddress)

            val ftSDKConfig = if (data.type == AccessType.DATAKIT.value)
                FTSDKConfig.builder(data.datakitAddress)
            else FTSDKConfig.builder(
                data.datawayAddress,
                data.datawayClientToken
            )
            ftSDKConfig.setServiceName("ft-sdk-demo")
                .setEnableOkhttpRequestTag(true)
                .setDebug(true)//是否开启Debug模式（开启后能查看调试数据）
            FTSdk.install(ftSDKConfig)

            //配置 Log
            FTSdk.initLogWithConfig(
                FTLoggerConfig()
                    .setEnableConsoleLog(true)
//                .setEnableConsoleLog(true,"log prefix")
                    .setEnableLinkRumData(true)
                    .setEnableCustomLog(true)
                    .setPrintCustomLogToConsole(true)
//                .setLogLevelFilters(arrayOf(Status.CRITICAL))
                    .setSamplingRate(0.8f)

            )

            val sp = context.getSharedPreferences(SP_STORE_DATA, MODE_PRIVATE)
            val customDynamicValue = sp.getString(CUSTOM_DYNAMIC_TAG, "not set")

            //配置 RUM
            FTSdk.initRUMWithConfig(
                FTRUMConfig()
                    .setRumAppId(data.appId)
                    .setEnableTraceUserAction(true)
                    .setEnableTraceUserView(true)
                    .setEnableTraceUserResource(true)
                    .setSamplingRate(1f)
                    .addGlobalContext(CUSTOM_STATIC_TAG, BuildConfig.CUSTOM_VALUE)
                    .addGlobalContext(CUSTOM_DYNAMIC_TAG, customDynamicValue!!)
                    .setExtraMonitorTypeWithError(ErrorMonitorType.ALL.value)
                    .setDeviceMetricsMonitorType(DeviceMetricsMonitorType.ALL.value)
                    .setEnableTrackAppCrash(true)
                    .setEnableTrackAppANR(true)
            )

            //配置 Trace
            FTSdk.initTraceWithConfig(
                FTTraceConfig()
                    .setSamplingRate(1f)
                    .setEnableAutoTrace(true)
                    .setEnableLinkRUMData(true)
            )
        }

        fun setDynamicParams(context: Context, value: String) {
            val sp = context.getSharedPreferences(SP_STORE_DATA, MODE_PRIVATE)
            sp.edit().putString(CUSTOM_DYNAMIC_TAG, value).apply()

        }

        /**
         * 设置 otel SDK
         */
        fun setOtelSDK() {
            val otlpExporter = OtlpHttpSpanExporter.builder()
                .setEndpoint("http://10.0.0.1:9529/otel/v1/traces") // APM 服务器地址
                .build()

            val spanProcessor = SimpleSpanProcessor.create(otlpExporter)

            val sdkTracerProvider = SdkTracerProvider.builder()
                .addSpanProcessor(spanProcessor)
                .setResource(
                    Resource.create(
                        Attributes.of(
                            AttributeKey.stringKey("service.name"),
                            "ft-sdk-demo"
                        )
                    )
                )
                .build()

            OpenTelemetrySdk.builder()
                .setTracerProvider(sdkTracerProvider)
                .setPropagators(ContextPropagators.create(W3CTraceContextPropagator.getInstance()))
                .buildAndRegisterGlobal()
        }


        /**
         * @param traceId
         * @param parentSpanId
         * @param actionName
         *
         */
        fun createSpanWithOtel(
            traceId: String = "",
            parentSpanId: String = "",
            actionName: String,
            callback: () -> Unit
        ): Span {
            val tracer = GlobalOpenTelemetry.getTracer("ft-sdk-demo")

            val hasParent = traceId.isNotEmpty() && parentSpanId.isNotEmpty()

            val childSpanBuilder = tracer.spanBuilder(actionName)

            if (hasParent) {
                val spanContext = SpanContext.create(
                    traceId,
                    parentSpanId,
                    TraceFlags.getSampled(), // 重要：让 Span 参与采样
                    TraceState.getDefault()
                )

                if (spanContext.isValid) {
                    val parentSpan = Span.wrap(spanContext)
                    val parentContext = io.opentelemetry.context.Context.root().with(parentSpan)

                    childSpanBuilder.setParent(parentContext)
                        .setAttribute("custom.has_parent", true)
                }
            }

            val currentSpan: Span = childSpanBuilder
                //设置服务端偏移时间
//                .setStartTimestamp(
//                System.currentTimeMillis() + 10,
//                TimeUnit.MILLISECONDS
//            )
                .startSpan()
            try {
                callback.invoke()
            } finally {
                currentSpan.end()
            }
            return currentSpan
        }
    }


}

