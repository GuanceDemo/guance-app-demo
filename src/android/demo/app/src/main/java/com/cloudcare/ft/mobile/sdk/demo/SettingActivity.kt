package com.cloudcare.ft.mobile.sdk.demo

import android.content.Intent
import android.os.Bundle
import android.util.Base64
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Button
import android.widget.RadioGroup
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import com.cloudcare.ft.mobile.sdk.demo.data.AccessType
import com.cloudcare.ft.mobile.sdk.demo.data.GC_SCHEME_URL
import com.cloudcare.ft.mobile.sdk.demo.http.HttpEngine
import com.cloudcare.ft.mobile.sdk.demo.manager.SettingConfigManager
import com.cloudcare.ft.mobile.sdk.demo.manager.SettingData
import com.cloudcare.ft.mobile.sdk.demo.utils.Utils
import com.cloudcare.ft.mobile.sdk.demo.utils.UtilsDialog
import com.ft.sdk.FTSdk
import com.google.android.material.textfield.TextInputEditText
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.nio.charset.StandardCharsets


@DelicateCoroutinesApi
class SettingActivity : BaseActivity() {
    private var datakitAddressEt: TextInputEditText? = null
    private var datawayAddressEt: TextInputEditText? = null
    private var datawayClientTokenEt: TextInputEditText? = null
    private var otelAddressEt: TextInputEditText? = null
    private var demoAPIAddressEt: TextInputEditText? = null
    private var appIDEt: TextInputEditText? = null
    private var settingData: SettingData? = null
    private var radioGroup: RadioGroup? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_setting)
        setTitle(R.string.edit_setting)
        datakitAddressEt = findViewById(R.id.setting_datakit_et)
        datawayAddressEt = findViewById(R.id.setting_dataway_et)
        datawayClientTokenEt = findViewById(R.id.setting_dataway_client_token_et)
        demoAPIAddressEt = findViewById(R.id.setting_demo_api_et)
        otelAddressEt = findViewById(R.id.setting_otel_api_et)
        appIDEt = findViewById(R.id.setting_app_id_et)

        radioGroup = findViewById(R.id.setting_access_type_rg)
        radioGroup?.setOnCheckedChangeListener { radioGroup, id ->
            when (id) {
                R.id.setting_datakit_deploy_rb -> {
                    setDatakitView()
                }

                R.id.setting_dataway_deploy_rb -> {
                    setDatawayView()
                }
            }

        }

        findViewById<Button>(R.id.setting_check).setOnClickListener {
            checkAddressConnect {
                Toast.makeText(
                    this@SettingActivity,
                    getString(R.string.setting_tip_connect_success),
                    Toast.LENGTH_SHORT
                ).show()
            }
        }

        settingData = SettingConfigManager.readSetting()
        setSettingView(settingData!!)
        radioGroup?.check(
            if (settingData!!.type == AccessType.DATAKIT.value)
                R.id.setting_datakit_deploy_rb
            else
                R.id.setting_dataway_deploy_rb
        )
    }

    private fun setSettingView(settingData: SettingData) {
        datakitAddressEt?.setText(settingData.datakitAddress)
        demoAPIAddressEt?.setText(settingData.demoApiAddress)
        datawayAddressEt?.setText(settingData.datawayAddress)
        datawayClientTokenEt?.setText(settingData.datawayClientToken)
        otelAddressEt?.setText(settingData.otelAddress)
        appIDEt?.setText(settingData.appId)
    }

    private fun setDatawayView() {
        findViewById<View>(R.id.setting_dataway_layout)?.visibility = View.VISIBLE
        findViewById<View>(R.id.setting_dataway_client_token_layout)?.visibility = View.VISIBLE
        findViewById<View>(R.id.setting_datakit_layout)?.visibility = View.GONE
    }

    private fun setDatakitView() {
        findViewById<View>(R.id.setting_dataway_layout)?.visibility = View.GONE
        findViewById<View>(R.id.setting_dataway_client_token_layout)?.visibility = View.GONE
        findViewById<View>(R.id.setting_datakit_layout)?.visibility = View.VISIBLE

    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.setting_menu, menu);
        return true
    }

    private fun checkAppId() {
        if (appIDEt?.text.isNullOrEmpty()) {
            appIDEt?.error = "App ID cannot be empty"
        } else {
            appIDEt?.error = null
        }
    }

    private fun checkDatakitAddress() {
        if (!Utils.isValidHttpUrl(datakitAddressEt!!.text.toString())) {
            datakitAddressEt?.error = "Invalid address"
        } else {
            datakitAddressEt?.error = null

        }
    }

    private fun checkDemoAPIAddress() {
        if (!Utils.isValidHttpUrl(demoAPIAddressEt!!.text.toString())) {
            demoAPIAddressEt?.error = "Invalid address"
        } else {
            demoAPIAddressEt?.error = null
        }
    }

    private fun checkDatawayAddress() {
        if (!Utils.isValidHttpUrl(datawayAddressEt!!.text.toString())) {
            datawayAddressEt?.error = "Invalid address"
        } else {
            datawayAddressEt?.error = null
        }
    }

    private fun checkDatawayClientToken() {
        if (datawayClientTokenEt!!.text.isNullOrEmpty()) {
            datawayClientTokenEt?.error = "Invalid address"
        } else {
            datawayClientTokenEt?.error = null
        }
    }

    private fun checkAllInput(): Boolean {
        checkAppId()
        checkDemoAPIAddress()

        if (radioGroup?.checkedRadioButtonId == R.id.setting_datakit_deploy_rb) {
            checkDatakitAddress()

            if (!(appIDEt?.error.isNullOrEmpty()
                        && datakitAddressEt?.error.isNullOrEmpty()
                        && demoAPIAddressEt?.error.isNullOrEmpty())

            ) {
                return false
            }
        } else if (radioGroup?.checkedRadioButtonId == R.id.setting_dataway_deploy_rb) {
            checkDatawayAddress()
            checkDatawayClientToken()

            if (!(appIDEt?.error.isNullOrEmpty()
                        && datawayAddressEt?.error.isNullOrEmpty()
                        && datawayClientTokenEt?.error.isNullOrEmpty()
                        && demoAPIAddressEt?.error.isNullOrEmpty())
            ) {
                return false
            }

        }
        return true

    }


    @DelicateCoroutinesApi
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.setting_import_setting -> {
                val text = Utils.copyFormClipBoard(this)
                if (text.startsWith(GC_SCHEME_URL)) {
                    val data = text.substring(GC_SCHEME_URL.length)
                    val decodeByte = Base64.decode(data, Base64.DEFAULT)
                    val jsonString = String(decodeByte, StandardCharsets.UTF_8)
                    val settingData = SettingData.readFromJson(jsonString)
                    if (settingData != null) {
                        setSettingView(settingData)
                        this.settingData = settingData
                        Toast.makeText(
                            this,
                            getString(R.string.setting_import_success),
                            Toast.LENGTH_SHORT
                        ).show()

                    } else {
                        Toast.makeText(
                            this,
                            getString(R.string.setting_import_fail),
                            Toast.LENGTH_SHORT
                        ).show()
                    }

                } else {
                    Toast.makeText(
                        this,
                        getString(R.string.setting_configure_not_found),
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }

            R.id.setting_save -> {
                if (!checkAllInput()) {
                    return true
                }

                checkAddressConnect {
                    SettingConfigManager.saveSetting(it)

                    val builder: AlertDialog.Builder = AlertDialog.Builder(this)
                    builder.setTitle(getString(R.string.tip))
                    builder.setMessage(getString(R.string.setting_tip_restart))

                    builder.setPositiveButton("OK") { _, _ ->
                        val intent = Intent(this@SettingActivity, MainActivity::class.java)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                        startActivity(intent)
                        FTSdk.shutDown()

                        DemoApplication.setSDK(this@SettingActivity)
                    }

                    val alertDialog: AlertDialog = builder.create()
                    alertDialog.show()
                }


            }

        }
        return super.onOptionsItemSelected(item)
    }

    private fun checkAddressConnect(success: ((data: SettingData) -> Unit)? = null) {
        if (!checkAllInput()) {
            return
        }

        val settingData = SettingData(
            datakitAddressEt?.text.toString(),
            demoAPIAddressEt?.text.toString(),
            appIDEt?.text.toString(),
            datawayAddressEt?.text.toString(),
            datawayClientTokenEt?.text.toString(),
            otelAddressEt?.text.toString(),
            if (radioGroup?.checkedRadioButtonId == R.id.setting_datakit_deploy_rb)
                AccessType.DATAKIT.value else AccessType.DATAWAY.value
        )

        UtilsDialog.showLoadingDialog(this@SettingActivity)
        GlobalScope.launch(Dispatchers.IO) {
            val datakitConnect = if (settingData.type == AccessType.DATAKIT.value)
                HttpEngine.datakitPing(settingData.datakitAddress)
            else
                HttpEngine.datawayPing(settingData.datawayAddress, settingData.datawayClientToken)

            val apiConnect = HttpEngine.apiConnect(settingData.demoApiAddress)

            withContext(Dispatchers.Main) {
                if (settingData.type == AccessType.DATAKIT.value) {
                    if (datakitConnect.code != HttpURLConnection.HTTP_OK) {
                        datakitAddressEt?.error = datakitConnect.errorMessage
                    } else {
                        datakitAddressEt?.error = null
                    }
                } else {
                    if (datakitConnect.code != HttpURLConnection.HTTP_OK) {
                        datawayAddressEt?.error = datakitConnect.errorMessage
                        datawayClientTokenEt?.error = datakitConnect.errorMessage
                    } else {
                        datawayAddressEt?.error = null
                        datawayClientTokenEt?.error = null
                    }
                }

                if (apiConnect.code != HttpURLConnection.HTTP_OK) {
                    demoAPIAddressEt?.error = apiConnect.errorMessage
                } else {
                    demoAPIAddressEt?.error = null

                }
                UtilsDialog.hideLoadingDialog()

                if (settingData.type == AccessType.DATAKIT.value) {
                    if (!(demoAPIAddressEt?.error.isNullOrEmpty()
                                && datakitAddressEt?.error.isNullOrEmpty())
                    ) {
                        return@withContext
                    }
                } else {
                    if (!(demoAPIAddressEt?.error.isNullOrEmpty()
                                && datawayAddressEt?.error.isNullOrEmpty()
                                && datawayClientTokenEt?.error.isNullOrEmpty())
                    ) {
                        return@withContext
                    }

                }



                success?.let {
                    it(settingData)
                }

            }
        }


    }
}