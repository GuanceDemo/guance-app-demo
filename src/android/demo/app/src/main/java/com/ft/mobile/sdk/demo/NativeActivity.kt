package com.ft.mobile.sdk.demo

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import com.ft.mobile.sdk.demo.compose.ComposeActivity
import com.ft.mobile.sdk.demo.http.HttpEngine
import com.ft.mobile.sdk.demo.nativelib.NativeLib
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.math.BigInteger
import java.net.HttpURLConnection


class NativeActivity : BaseActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Native View"
        setContentView(R.layout.activity_native_view)

        findViewById<Button>(R.id.native_dynamic_rum_tag_btn).setOnClickListener {
            val intent = Intent(this@NativeActivity, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            startActivity(intent)
            DemoApplication.setDynamicParams(this, "set from dynamic")
            DemoApplication.setSDK(this@NativeActivity)
        }

        findViewById<View>(R.id.native_crash_java_kotlin_data_btn).setOnClickListener { v: View? ->
            Thread { val i = 1 / 0 }.start()
        }
        findViewById<View>(R.id.native_crash_c_cpp_data_btn).setOnClickListener { v: View? ->
            NativeLib().crashTest()
        }


        findViewById<View>(R.id.native_long_task_data_btn).setOnClickListener { v: View? ->
            try {
                Thread.sleep(2000)
            } catch (e: InterruptedException) {
                e.printStackTrace()
            }
        }
        findViewById<View>(R.id.native_session_replay_compat).setOnClickListener {
            startActivity(Intent(this@NativeActivity, SessionReplayActivity::class.java))
        }

        findViewById<View>(R.id.native_compose_activity_btn).setOnClickListener {
            startActivity(Intent(this@NativeActivity, ComposeActivity::class.java))
        }


        findViewById<View>(R.id.native_dynamic_create_otel_data).setOnClickListener {

            GlobalScope.launch(Dispatchers.IO) {
                val response = HttpEngine.userinfoWithOtel()
//                val parentId = Utils.getGUID_16()
//                val traceId = Utils.randomUUID()
                var traceId = response.headers["trace_id"]
                var parentId = response.headers["span_id"]
                // If using ddtrace, traceid needs to be converted from 64-bit int to 128-bit hex, and spanid needs to be converted to hex
                traceId = traceId?.toBigInteger()?.let { it1 -> convert64To128Bit(it1) }
                parentId = parentId?.toBigInteger()?.let { it1 -> convertHex(it1) }
                println(response.body?.string())
                withContext(Dispatchers.Main) {
                    if (response.code == HttpURLConnection.HTTP_OK) {
                        if (traceId != null && parentId != null) {
                            DemoApplication.createSpanWithOtel(
                                traceId,
                                parentId,
                                "add.action.after_request"
                            ) {
                            }

                        }
                    }

                }
            }

        }
        findViewById<View>(R.id.native_compose_activity_btn).setOnClickListener {
            startActivity(Intent(this@NativeActivity, ComposeActivity::class.java))
        }
    }

    private fun convert64To128Bit(traceId64: BigInteger): String {
        return "0000000000000000" + traceId64.toString(16).padStart(16, '0')
    }

    private fun convertHex(spanId: BigInteger): String {
        return spanId.toString(16).padStart(16, '0')
    }


}
