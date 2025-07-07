package com.cloudcare.ft.mobile.sdk.custom.okhttp

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
    lateinit var guanceEventListener: EventListener
    override fun create(call: Call): EventListener {
        // Implement your custom method here
        guanceEventListener = super.create(call)
        return CustomEventListener(guanceEventListener)
    }
}

/**
 *  Customize a customerListener to forward the received data
 */
class CustomEventListener(val guanceEventListener: EventListener) : EventListener() {
    override fun callEnd(call: Call) {
        super.callEnd(call)
        this.guanceEventListener.callEnd(call)
    }

    override fun callFailed(call: Call, ioe: IOException) {
        super.callFailed(call, ioe)
        this.guanceEventListener.callFailed(call, ioe)

    }

    override fun callStart(call: Call) {
        super.callStart(call)
        this.guanceEventListener.callStart(call)
    }

    override fun canceled(call: Call) {
        super.canceled(call)
        this.guanceEventListener.canceled(call)
    }

    override fun connectEnd(
        call: Call,
        inetSocketAddress: InetSocketAddress,
        proxy: Proxy,
        protocol: Protocol?
    ) {
        super.connectEnd(call, inetSocketAddress, proxy, protocol)
        this.guanceEventListener.connectEnd(call, inetSocketAddress, proxy, protocol)
    }

    override fun connectFailed(
        call: Call,
        inetSocketAddress: InetSocketAddress,
        proxy: Proxy,
        protocol: Protocol?,
        ioe: IOException
    ) {
        super.connectFailed(call, inetSocketAddress, proxy, protocol, ioe)
        this.guanceEventListener.connectFailed(call, inetSocketAddress, proxy, protocol, ioe)
    }

    override fun connectStart(call: Call, inetSocketAddress: InetSocketAddress, proxy: Proxy) {
        super.connectStart(call, inetSocketAddress, proxy)
        this.guanceEventListener.connectStart(call, inetSocketAddress, proxy)
    }

    override fun connectionAcquired(call: Call, connection: Connection) {
        super.connectionAcquired(call, connection)
        this.guanceEventListener.connectionAcquired(call, connection)
    }

    override fun connectionReleased(call: Call, connection: Connection) {
        super.connectionReleased(call, connection)
        this.guanceEventListener.connectionReleased(call, connection)
    }

    override fun dnsEnd(call: Call, domainName: String, inetAddressList: List<InetAddress>) {
        super.dnsEnd(call, domainName, inetAddressList)
        this.guanceEventListener.dnsEnd(call, domainName, inetAddressList)
    }

    override fun dnsStart(call: Call, domainName: String) {
        super.dnsStart(call, domainName)
        this.guanceEventListener.dnsStart(call, domainName)
    }

    override fun proxySelectEnd(call: Call, url: HttpUrl, proxies: List<Proxy>) {
        super.proxySelectEnd(call, url, proxies)
        this.guanceEventListener.proxySelectEnd(call, url, proxies)
    }

    override fun proxySelectStart(call: Call, url: HttpUrl) {
        super.proxySelectStart(call, url)
        this.guanceEventListener.proxySelectStart(call, url)
    }

    override fun requestBodyEnd(call: Call, byteCount: Long) {
        super.requestBodyEnd(call, byteCount)
        this.guanceEventListener.requestBodyEnd(call, byteCount)
    }

    override fun requestBodyStart(call: Call) {
        super.requestBodyStart(call)
        this.guanceEventListener.requestBodyStart(call)
    }

    override fun requestFailed(call: Call, ioe: IOException) {
        super.requestFailed(call, ioe)
        this.guanceEventListener.requestFailed(call, ioe)
    }

    override fun requestHeadersEnd(call: Call, request: Request) {
        super.requestHeadersEnd(call, request)
        this.guanceEventListener.requestHeadersEnd(call, request)
    }

    override fun requestHeadersStart(call: Call) {
        super.requestHeadersStart(call)
        this.guanceEventListener.requestHeadersStart(call)
    }

    override fun responseBodyEnd(call: Call, byteCount: Long) {
        super.responseBodyEnd(call, byteCount)
        this.guanceEventListener.responseBodyEnd(call, byteCount)
    }

    override fun responseBodyStart(call: Call) {
        super.responseBodyStart(call)
        this.guanceEventListener.responseBodyStart(call)
    }

    override fun responseFailed(call: Call, ioe: IOException) {
        super.responseFailed(call, ioe)
        this.guanceEventListener.responseFailed(call, ioe)
    }

    override fun responseHeadersEnd(call: Call, response: Response) {
        super.responseHeadersEnd(call, response)
        this.guanceEventListener.responseHeadersEnd(call, response)
    }

    override fun responseHeadersStart(call: Call) {
        super.responseHeadersStart(call)
        this.guanceEventListener.responseHeadersStart(call)
    }

    override fun secureConnectEnd(call: Call, handshake: Handshake?) {
        super.secureConnectEnd(call, handshake)
        this.guanceEventListener.secureConnectEnd(call, handshake)
    }

    override fun secureConnectStart(call: Call) {
        super.secureConnectStart(call)
        this.guanceEventListener.secureConnectStart(call)
    }
}