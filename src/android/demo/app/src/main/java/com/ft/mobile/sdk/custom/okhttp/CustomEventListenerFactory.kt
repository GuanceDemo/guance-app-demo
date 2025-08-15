package com.ft.mobile.sdk.custom.okhttp

import com.ft.sdk.FTResourceEventListener
import okhttp3.Call
import okhttp3.Connection
import okhttp3.EventListener
import okhttp3.Handshake
import okhttp3.HttpUrl
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.Response
import java.io.IOException
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Proxy

/**
 * Custom Okhttp EventListener. If your project does not require customization, you can directly call
 * @see com.ft.sdk.FTResourceEventListener.FTFactory()
 *
 */
class CustomEventListenerFactory : FTResourceEventListener.FTFactory() {
    lateinit var eventListener: EventListener
    override fun create(call: Call): EventListener {
        // Implement your custom method here
        eventListener = super.create(call)
        return CustomEventListener(eventListener)
    }
}

/**
 *  Customize a customerListener to forward the received data
 */
class CustomEventListener(val eventListener: EventListener) : EventListener() {
    override fun callEnd(call: Call) {
        super.callEnd(call)
        this.eventListener.callEnd(call)
    }

    override fun callFailed(call: Call, ioe: IOException) {
        super.callFailed(call, ioe)
        this.eventListener.callFailed(call, ioe)

    }

    override fun callStart(call: Call) {
        super.callStart(call)
        this.eventListener.callStart(call)
    }

    override fun canceled(call: Call) {
        super.canceled(call)
        this.eventListener.canceled(call)
    }

    override fun connectEnd(
        call: Call,
        inetSocketAddress: InetSocketAddress,
        proxy: Proxy,
        protocol: Protocol?
    ) {
        super.connectEnd(call, inetSocketAddress, proxy, protocol)
        this.eventListener.connectEnd(call, inetSocketAddress, proxy, protocol)
    }

    override fun connectFailed(
        call: Call,
        inetSocketAddress: InetSocketAddress,
        proxy: Proxy,
        protocol: Protocol?,
        ioe: IOException
    ) {
        super.connectFailed(call, inetSocketAddress, proxy, protocol, ioe)
        this.eventListener.connectFailed(call, inetSocketAddress, proxy, protocol, ioe)
    }

    override fun connectStart(call: Call, inetSocketAddress: InetSocketAddress, proxy: Proxy) {
        super.connectStart(call, inetSocketAddress, proxy)
        this.eventListener.connectStart(call, inetSocketAddress, proxy)
    }

    override fun connectionAcquired(call: Call, connection: Connection) {
        super.connectionAcquired(call, connection)
        this.eventListener.connectionAcquired(call, connection)
    }

    override fun connectionReleased(call: Call, connection: Connection) {
        super.connectionReleased(call, connection)
        this.eventListener.connectionReleased(call, connection)
    }

    override fun dnsEnd(call: Call, domainName: String, inetAddressList: List<InetAddress>) {
        super.dnsEnd(call, domainName, inetAddressList)
        this.eventListener.dnsEnd(call, domainName, inetAddressList)
    }

    override fun dnsStart(call: Call, domainName: String) {
        super.dnsStart(call, domainName)
        this.eventListener.dnsStart(call, domainName)
    }

    override fun proxySelectEnd(call: Call, url: HttpUrl, proxies: List<Proxy>) {
        super.proxySelectEnd(call, url, proxies)
        this.eventListener.proxySelectEnd(call, url, proxies)
    }

    override fun proxySelectStart(call: Call, url: HttpUrl) {
        super.proxySelectStart(call, url)
        this.eventListener.proxySelectStart(call, url)
    }

    override fun requestBodyEnd(call: Call, byteCount: Long) {
        super.requestBodyEnd(call, byteCount)
        this.eventListener.requestBodyEnd(call, byteCount)
    }

    override fun requestBodyStart(call: Call) {
        super.requestBodyStart(call)
        this.eventListener.requestBodyStart(call)
    }

    override fun requestFailed(call: Call, ioe: IOException) {
        super.requestFailed(call, ioe)
        this.eventListener.requestFailed(call, ioe)
    }

    override fun requestHeadersEnd(call: Call, request: Request) {
        super.requestHeadersEnd(call, request)
        this.eventListener.requestHeadersEnd(call, request)
    }

    override fun requestHeadersStart(call: Call) {
        super.requestHeadersStart(call)
        this.eventListener.requestHeadersStart(call)
    }

    override fun responseBodyEnd(call: Call, byteCount: Long) {
        super.responseBodyEnd(call, byteCount)
        this.eventListener.responseBodyEnd(call, byteCount)
    }

    override fun responseBodyStart(call: Call) {
        super.responseBodyStart(call)
        this.eventListener.responseBodyStart(call)
    }

    override fun responseFailed(call: Call, ioe: IOException) {
        super.responseFailed(call, ioe)
        this.eventListener.responseFailed(call, ioe)
    }

    override fun responseHeadersEnd(call: Call, response: Response) {
        super.responseHeadersEnd(call, response)
        this.eventListener.responseHeadersEnd(call, response)
    }

    override fun responseHeadersStart(call: Call) {
        super.responseHeadersStart(call)
        this.eventListener.responseHeadersStart(call)
    }

    override fun secureConnectEnd(call: Call, handshake: Handshake?) {
        super.secureConnectEnd(call, handshake)
        this.eventListener.secureConnectEnd(call, handshake)
    }

    override fun secureConnectStart(call: Call) {
        super.secureConnectStart(call)
        this.eventListener.secureConnectStart(call)
    }
}