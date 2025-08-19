//
//  Otel.swift
//  FTSDKDemo
//
//  Created by hulilei on 2025/2/28.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import OpenTelemetryProtocolExporterHttp

func otelSdkInit(){
    // 1. Create OTLP Exporter, fill in APM server address
    guard let endpoint = URL(string:"http://10.0.0.1:9529/otel/v1/traces") else {
        fatalError("Invalid endpoint URL")
    }
    
    let exporter = OtlpHttpTraceExporter(endpoint: endpoint)
    
    // 2. Create Span Processor
    let processor = SimpleSpanProcessor(spanExporter: exporter)
    
    
    // 3. Create Resource
    let resource = Resource(attributes: [
        "service.name": AttributeValue.string("ft-sdk-demo")
    ])
    
    // 5. Global registration
    OpenTelemetry.registerTracerProvider(tracerProvider:  TracerProviderBuilder()
        .add(spanProcessor: processor)
        .with(resource: resource)
        .build()
    )
    
    OpenTelemetry.registerPropagators(textPropagators: [W3CTraceContextPropagator.init()], baggagePropagator: W3CBaggagePropagator.init())
}


func createSpanWithOtel(
    traceId: String = "",
    parentSpanId: String = "",
    actionName: String
) -> Span{
    let tracer = OpenTelemetry.instance.tracerProvider.get(instrumentationName: "ft-sdk-demo", instrumentationVersion: nil)
    
    let hasParent = !traceId.isEmpty && !parentSpanId.isEmpty
    
    let childSpanBuilder = tracer.spanBuilder(spanName: actionName)
    if (hasParent) {
        let trace = TraceId(fromHexString: traceId)
        let span = SpanId(fromHexString: parentSpanId)
        
        let traceFlags = TraceFlags().settingIsSampled(true)
        let spanContext = SpanContext.create(
            traceId: trace,
            spanId: span,
            traceFlags: traceFlags,
            traceState: TraceState()
        )
        if (spanContext.isValid) {
            
            childSpanBuilder.setParent(spanContext)
            childSpanBuilder.setAttribute(key: "custom.has_parent", value: true)
        }
    }
    let currentSpan = childSpanBuilder.startSpan()
    defer {
        currentSpan.end()
    }
    return currentSpan
}
