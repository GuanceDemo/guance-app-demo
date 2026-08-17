package com.ft.mobile.sdk.demo

import android.os.Bundle
import android.widget.TextView
import com.ft.mobile.sdk.demo.http.OkHttpClientInstance
import com.ft.mobile.sdk.demo.manager.SettingConfigManager
import com.ft.sdk.garble.utils.LogUtils
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

class WebSocketActivity : BaseActivity() {

    private lateinit var resultView: TextView
    private val activeWebSocket = AtomicReference<WebSocket>()
    private val webSocketClient by lazy {
        OkHttpClientInstance.get().newBuilder()
            .connectTimeout(CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(0, TimeUnit.MILLISECONDS)
            .build()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = getString(R.string.native_websocket_entry_title)
        setContentView(R.layout.activity_websocket)

        val toolbar: androidx.appcompat.widget.Toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        setupToolbar(toolbar)

        resultView = findViewById(R.id.websocket_test_result)
        val demoApiAddress = SettingConfigManager.readSetting(this).demoApiAddress
        val successUrl = createWebSocketUrl(demoApiAddress, "/ws/echo")
        val rejectUrl = createWebSocketUrl(demoApiAddress, "/ws/reject")
        val invalidUpgradeUrl = createWebSocketUrl(demoApiAddress, "/ws/invalid-upgrade")

        resultView.text = getString(
            R.string.websocket_test_configuration,
            successUrl,
            rejectUrl,
            invalidUpgradeUrl
        )

        findViewById<android.view.View>(R.id.websocket_success_btn).setOnClickListener {
            startWebSocketTest("success", successUrl)
        }
        findViewById<android.view.View>(R.id.websocket_reject_btn).setOnClickListener {
            startWebSocketTest("rejected", rejectUrl)
        }
        findViewById<android.view.View>(R.id.websocket_invalid_upgrade_btn).setOnClickListener {
            startWebSocketTest("failed", invalidUpgradeUrl)
        }
        findViewById<android.view.View>(R.id.websocket_close_btn).setOnClickListener {
            closeActiveWebSocket()
        }
    }

    private fun startWebSocketTest(scenario: String, url: String) {
        closeActiveWebSocket()
        appendResult("$scenario: connecting to $url")

        val request = try {
            Request.Builder().url(url).build()
        } catch (error: IllegalArgumentException) {
            appendResult("$scenario: invalid URL (${error.message})")
            return
        }

        val webSocket = webSocketClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                appendResult(
                    "$scenario: onOpen status=${response.code}, protocol=${response.protocol}"
                )
                webSocket.send(TEST_MESSAGE)
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                appendResult("$scenario: echo text=$text")
            }

            override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
                appendResult("$scenario: echo bytes=${bytes.size}")
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                appendResult("$scenario: onClosing code=$code, reason=$reason")
                webSocket.close(code, reason)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                appendResult("$scenario: onClosed code=$code, reason=$reason")
                activeWebSocket.compareAndSet(webSocket, null)
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                val status = response?.code?.toString() ?: "none"
                appendResult(
                    "$scenario: onFailure status=$status, " +
                        "error=${t.javaClass.simpleName}: ${t.message}"
                )
                response?.close()
                activeWebSocket.compareAndSet(webSocket, null)
            }
        })
        activeWebSocket.set(webSocket)
    }

    private fun appendResult(message: String) {
        LogUtils.d(TAG, "WebSocket test: $message")
        runOnUiThread {
            if (!isDestroyed) {
                resultView.append("\n$message")
            }
        }
    }

    private fun closeActiveWebSocket() {
        val webSocket = activeWebSocket.get() ?: return
        val closing = webSocket.close(NORMAL_CLOSURE_STATUS, CLOSE_REASON)
        appendResult("close requested=$closing")
        if (!closing) {
            webSocket.cancel()
            activeWebSocket.compareAndSet(webSocket, null)
        }
    }

    override fun onDestroy() {
        activeWebSocket.getAndSet(null)?.cancel()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "WebSocketActivity"
        private const val CONNECT_TIMEOUT_SECONDS = 10L
        private const val NORMAL_CLOSURE_STATUS = 1000
        private const val CLOSE_REASON = "test complete"
        private const val TEST_MESSAGE = "ft-sdk-websocket-handshake-test"

        internal fun createWebSocketUrl(demoApiAddress: String, path: String): String {
            val baseUrl = demoApiAddress.trim().trimEnd('/')
            val webSocketBaseUrl = when {
                baseUrl.startsWith("https://", ignoreCase = true) ->
                    "wss://${baseUrl.substring(8)}"

                baseUrl.startsWith("http://", ignoreCase = true) ->
                    "ws://${baseUrl.substring(7)}"

                else -> baseUrl
            }
            return "$webSocketBaseUrl$path"
        }
    }
}
