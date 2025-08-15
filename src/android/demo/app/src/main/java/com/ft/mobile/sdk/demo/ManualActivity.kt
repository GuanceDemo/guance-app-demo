package com.ft.mobile.sdk.demo

import android.os.Bundle
import android.widget.Button
import com.ft.mobile.sdk.custom.okhttp.CustomEventListenerFactory
import com.ft.mobile.sdk.custom.okhttp.CustomInterceptor
import com.ft.sdk.FTRUMGlobalManager
import com.ft.sdk.FTResourceEventListener
import com.ft.sdk.FTResourceInterceptor
import com.ft.sdk.FTTraceInterceptor
import com.ft.sdk.FTTraceManager
import com.ft.sdk.garble.bean.AppState
import com.ft.sdk.garble.bean.ErrorType
import com.ft.sdk.garble.bean.NetStatusBean
import com.ft.sdk.garble.bean.ResourceParams
import com.ft.sdk.garble.http.RequestMethod
import com.ft.sdk.garble.utils.LogUtils
import com.ft.sdk.garble.utils.Utils
import okhttp3.Call
import okhttp3.EventListener
import okhttp3.Handshake
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.Response
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.URL
import java.util.UUID

/**
 *  Demonstration of manual Action, Resource, and Trace
 *
 */
class ManualActivity : BaseActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_manual)

        findViewById<Button>(R.id.manual_action_btn).setOnClickListener {
            FTRUMGlobalManager.get().startAction("[action button]", "click")
        }


        findViewById<Button>(R.id.manual_http_btn).setOnClickListener {
            //Manually set OKHttp
            Thread {
                val requestBuilder: Request.Builder = Request.Builder()
                    .url("https://httpbin.org/status/200")
                    .method("get", null)

                val builder = OkHttpClient.Builder()
                    .addInterceptor(FTTraceInterceptor())
                    .addInterceptor(FTResourceInterceptor())
                    .eventListenerFactory(FTResourceEventListener.FTFactory())
                val client = builder.build()

                try {
                    val response: Response =
                        client.newCall(requestBuilder.build()).execute()
                    LogUtils.d("http request", "response:${response.code}")
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }.start()

        }

        findViewById<Button>(R.id.manual_http_custom_interceptor_btn).setOnClickListener {
            //OKHttp custom EventListener Interceptor
            Thread {
                val requestBuilder: Request.Builder = Request.Builder()
                    .url("https://httpbin.org/status/200")
                    .method("get", null)

                val builder = OkHttpClient.Builder()
                    .addInterceptor(FTTraceInterceptor())
                    .addInterceptor(FTResourceInterceptor())
                    .addInterceptor(CustomInterceptor())
                    .eventListenerFactory(CustomEventListenerFactory())
                val client = builder.build()

                try {
                    val response: Response =
                        client.newCall(requestBuilder.build()).execute()
                    LogUtils.d("http request", "response:${response.code}")
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }.start()

        }

        findViewById<Button>(R.id.manual_http_okhttp_custom_btn).setOnClickListener {
            //Custom Resource TraceHeader
            Thread {
                val uuid = UUID.randomUUID().toString()
                val url = "https://httpbin.org/status/200"
                //Get trace header identifier
                val headers = FTTraceManager.get().getTraceHeader(uuid, url)

                var response: Response?

                val params = ResourceParams()
                val netStatusBean = NetStatusBean()

                val client: OkHttpClient = OkHttpClient.Builder().addInterceptor { chain ->
                    //Start resource
                    FTRUMGlobalManager.get().startResource(uuid)
                    val original = chain.request()

                    val requestBuilder = original.newBuilder()
                    for (key in headers.keys) {
                        requestBuilder.header(key!!, headers[key]!!)
                    }
                    val request = requestBuilder.build()

                    response = chain.proceed(request)

                    //End resource
                    FTRUMGlobalManager.get().stopResource(uuid)

                    if (response != null) {

                        params.responseContentType = response!!.header("Content-Type")
                        params.responseConnection = response!!.header("Connection")
                        params.responseContentEncoding = response!!.header("Content-Encoding")
                        params.responseHeader = response!!.headers.toString()
                        params.requestHeader = request.headers.toString()
                        params.resourceStatus = response!!.code
                        params.resourceMethod = request.method
                        params.url = url
                        FTRUMGlobalManager.get().addResource(uuid, params, netStatusBean)

                        val requestHeaderMap = HashMap<String, String>()
                        val responseHeaderMap = HashMap<String, String>()
                        request.headers.forEach {
                            requestHeaderMap[it.first] = it.second
                        }
                        response!!.headers.forEach {
                            responseHeaderMap[it.first] = it.second

                        }

                    }
                    response!!
                }.eventListener(object : EventListener() {
                    override fun callEnd(call: Call) {
                        super.callEnd(call)
                        //Send resource metric data
                        FTRUMGlobalManager.get().addResource(uuid, params, netStatusBean)

                    }

                    override fun callStart(call: Call) {
                        super.callStart(call)
                        netStatusBean.callStartTime = Utils.getCurrentNanoTime()
                    }

                    override fun responseHeadersStart(call: Call) {
                        super.responseHeadersStart(call)
                        netStatusBean.headerStartTime = Utils.getCurrentNanoTime()

                    }

                    override fun requestHeadersEnd(call: Call, request: Request) {
                        super.requestHeadersEnd(call, request)
                        netStatusBean.headerEndTime = Utils.getCurrentNanoTime()
                    }


                    override fun requestBodyStart(call: Call) {
                        super.requestBodyStart(call)
                        netStatusBean.bodyStartTime = Utils.getCurrentNanoTime()

                    }

                    override fun responseBodyEnd(call: Call, byteCount: Long) {
                        super.responseBodyEnd(call, byteCount)
                        netStatusBean.bodyEndTime = Utils.getCurrentNanoTime()

                    }

                    override fun dnsEnd(
                        call: Call,
                        domainName: String,
                        inetAddressList: List<InetAddress>
                    ) {
                        super.dnsEnd(call, domainName, inetAddressList)
                        netStatusBean.dnsStartTime = Utils.getCurrentNanoTime()

                    }

                    override fun dnsStart(call: Call, domainName: String) {
                        super.dnsStart(call, domainName)
                        netStatusBean.dnsEndTime = Utils.getCurrentNanoTime()

                    }

                    override fun secureConnectStart(call: Call) {
                        super.secureConnectStart(call)
                        netStatusBean.sslEndTime = Utils.getCurrentNanoTime()

                    }

                    override fun secureConnectEnd(call: Call, handshake: Handshake?) {
                        super.secureConnectEnd(call, handshake)
                        netStatusBean.sslStartTime = Utils.getCurrentNanoTime()

                    }

                    override fun connectStart(
                        call: Call,
                        inetSocketAddress: InetSocketAddress,
                        proxy: Proxy
                    ) {
                        super.connectStart(call, inetSocketAddress, proxy)
                        netStatusBean.tcpStartTime = Utils.getCurrentNanoTime()

                    }

                    override fun connectEnd(
                        call: Call,
                        inetSocketAddress: InetSocketAddress,
                        proxy: Proxy,
                        protocol: Protocol?
                    ) {
                        super.connectEnd(call, inetSocketAddress, proxy, protocol)
                        netStatusBean.tcpEndTime = Utils.getCurrentNanoTime()

                    }
                }).build()

                val builder: Request.Builder = Request.Builder().url(url)
                    .method(RequestMethod.GET.name, null)

                val res: Response = client.newCall(builder.build()).execute()
                LogUtils.i("log", res.body?.string() + "")

            }.start()
        }

        findViewById<Button>(R.id.manual_http_http_url_connection_custom_btn).setOnClickListener {
            Thread {
                val uuid = UUID.randomUUID().toString()
                val netStatusBean = NetStatusBean()
                val params = ResourceParams()


                val url = "https://httpbin.org/status/200"
                try {
                    //Start resource
                    FTRUMGlobalManager.get().startResource(uuid)

                    val urlObj = URL(url)
                    val method = "GET"
                    val connection = urlObj.openConnection() as HttpURLConnection

                    //Set trace header
                    val headers = FTTraceManager.get().getTraceHeader(uuid, url)
                    for ((key, value) in headers) {
                        connection.setRequestProperty(key, value)
                    }

                    connection.requestMethod = method

                    //Set start time
                    netStatusBean.callStartTime = Utils.getCurrentNanoTime()
                    params.resourceMethod = method
                    params.url = url
                    //Set request header
                    params.requestHeader = connection.requestProperties.toString()

                    connection.connect()

                    val responseCode = connection.responseCode
                    val responseHeaders = connection.headerFields

                    netStatusBean.bodyEndTime = Utils.getCurrentNanoTime()
                    params.responseContentType = connection.contentType
                    params.responseContentEncoding = (connection.getHeaderField("Connection"))
                    params.responseContentEncoding = connection.contentEncoding
                    params.responseHeader = responseHeaders.toString()
                    params.resourceStatus = responseCode

                    val inputStream =
                        if (responseCode >= 400) connection.errorStream else connection.inputStream
                    var responseBody = ""
                    if (inputStream != null) {
                        BufferedReader(InputStreamReader(inputStream))
                            .use { reader ->
                                val stringBuilder = StringBuilder()
                                var line: String?
                                while ((reader.readLine().also { line = it }) != null) {
                                    stringBuilder.append(line)
                                }
                                responseBody = stringBuilder.toString()
                            }
                    }

                    //End request
                    FTRUMGlobalManager.get().stopResource(uuid)
                    //Add metrics and request

                    println(responseBody)
                } catch (e: Exception) {
                    // Handle errors
                    FTRUMGlobalManager.get().stopResource(uuid)
                    e.printStackTrace()
                }
                FTRUMGlobalManager.get().addResource(uuid, params, netStatusBean)
            }.start()

        }
        findViewById<Button>(R.id.manual_error_btn).setOnClickListener {
            FTRUMGlobalManager.get()
                .addError("crash stack", "error msg", ErrorType.JAVA, AppState.RUN)
        }

        findViewById<Button>(R.id.manual_longtask_btn).setOnClickListener {
            FTRUMGlobalManager.get().addLongTask("long task", 6000000)
        }
    }

    override fun onResume() {
        super.onResume()
        FTRUMGlobalManager.get().startView("ManualActivity");
    }

    override fun onPause() {
        super.onPause()
        FTRUMGlobalManager.get().stopView()
    }
}