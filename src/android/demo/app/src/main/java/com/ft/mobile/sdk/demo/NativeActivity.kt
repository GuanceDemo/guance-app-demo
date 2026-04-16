package com.ft.mobile.sdk.demo

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import androidx.appcompat.app.AlertDialog
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
        title = getString(R.string.technical_native_entry_title)
        setContentView(R.layout.activity_native_view)
        
        // Setup Toolbar
        val toolbar: androidx.appcompat.widget.Toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        setupToolbar(toolbar)

        val businessGroup = findViewById<View>(R.id.native_business_group)
        val labGroup = findViewById<View>(R.id.native_lab_group)
        val businessTab = findViewById<Button>(R.id.native_business_tab)
        val labTab = findViewById<Button>(R.id.native_lab_tab)

        fun showBusinessTab() {
            businessGroup.visibility = View.VISIBLE
            labGroup.visibility = View.GONE
            businessTab.isEnabled = false
            labTab.isEnabled = true
        }

        fun showLabTab() {
            businessGroup.visibility = View.GONE
            labGroup.visibility = View.VISIBLE
            businessTab.isEnabled = true
            labTab.isEnabled = false
        }

        businessTab.setOnClickListener { showBusinessTab() }
        labTab.setOnClickListener { showLabTab() }
        showBusinessTab()

        findViewById<Button>(R.id.native_dynamic_rum_tag_btn).setOnClickListener {
            val intent = Intent(this@NativeActivity, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            startActivity(intent)
            DemoApplication.setDynamicParams(this, "set from dynamic")
            DemoApplication.setSDK(this@NativeActivity)
        }

        findViewById<View>(R.id.native_manual_demo_btn).setOnClickListener {
            startActivity(Intent(this@NativeActivity, ManualActivity::class.java))
        }

        findViewById<View>(R.id.native_crash_java_kotlin_data_btn).setOnClickListener {
            showRiskDialog(
                title = getString(R.string.native_risk_java_title),
                message = getString(R.string.native_risk_java_message)
            ) {
                Thread { val i = 1 / 0 }.start()
            }
        }
        findViewById<View>(R.id.native_crash_c_cpp_data_btn).setOnClickListener {
            showRiskDialog(
                title = getString(R.string.native_risk_native_title),
                message = getString(R.string.native_risk_native_message)
            ) {
                NativeLib().crashTest()
            }
        }


        findViewById<View>(R.id.native_long_task_data_btn).setOnClickListener {
            showRiskDialog(
                title = getString(R.string.native_risk_longtask_title),
                message = getString(R.string.native_risk_longtask_message)
            ) {
                try {
                    Thread.sleep(2000)
                } catch (e: InterruptedException) {
                    e.printStackTrace()
                }
            }
        }
        findViewById<View>(R.id.native_session_replay_compat).setOnClickListener {
            startActivity(Intent(this@NativeActivity, SessionReplayActivity::class.java))
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
    }

    private fun showRiskDialog(title: String, message: String, onConfirm: () -> Unit) {
        AlertDialog.Builder(this)
            .setTitle(title)
            .setMessage(message)
            .setPositiveButton(R.string.native_risk_confirm) { _, _ -> onConfirm() }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun convert64To128Bit(traceId64: BigInteger): String {
        return "0000000000000000" + traceId64.toString(16).padStart(16, '0')
    }

    private fun convertHex(spanId: BigInteger): String {
        return spanId.toString(16).padStart(16, '0')
    }


}
