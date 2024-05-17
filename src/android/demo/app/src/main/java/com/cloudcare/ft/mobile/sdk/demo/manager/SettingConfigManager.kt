package com.cloudcare.ft.mobile.sdk.demo.manager

import android.content.Context
import com.cloudcare.ft.mobile.sdk.demo.BuildConfig
import com.cloudcare.ft.mobile.sdk.demo.data.AccessType
import com.cloudcare.ft.mobile.sdk.demo.data.DEFAULT_API_ADDRESS
import com.cloudcare.ft.mobile.sdk.demo.data.DEFAULT_APP_ID
import com.cloudcare.ft.mobile.sdk.demo.data.DEFAULT_DATAKIT_ADDRESS
import com.cloudcare.ft.mobile.sdk.demo.data.DEFAULT_DATAWAY_ADDRESS
import com.cloudcare.ft.mobile.sdk.demo.data.DEFAULT_DATAWAY_CLIENT_TOKEN
import com.cloudcare.ft.mobile.sdk.demo.http.HttpEngine
import com.ft.sdk.FTApplication
import org.json.JSONObject

private const val PREFS_USER_DATA_NAME = "gc_demo_sdk_setting"
private const val KEY_DEMO_DATAKIT_ADDRESS = "datakitAddress"
private const val KEY_DEMO_DATAWAY_ADDRESS = "datawayAddress"
private const val KEY_DEMO_DATAWAY_CLIENT_TOKEN = "datawayClientToken"
private const val KEY_DEMO_APP_ACCESS_TYPE = "appAccessType"
private const val KEY_DEMO_API_ADDRESS = "demoApiAddress"
private const val KEY_DEMO_APP_ID = "demoAndroidAppId"

data class SettingData(
    val datakitAddress: String,
    val demoApiAddress: String,
    val appId: String,
    val datawayAddress: String,
    val datawayClientToken: String,
    val type: Int,
) {
    fun getUserInfoUrl(): String {
        return demoApiAddress + HttpEngine.API_USER_INFO
    }

    companion object {
        fun readFromJson(jsonString: String): SettingData? {
            try {
                val json = JSONObject(jsonString)
                val datakitAddress = json.optString(KEY_DEMO_DATAKIT_ADDRESS, "")
                val demoApiAddress = json.optString(KEY_DEMO_API_ADDRESS, "")
                val appId = json.optString(KEY_DEMO_APP_ID, "")
                val datawayAddress = json.optString(KEY_DEMO_DATAWAY_ADDRESS, "")
                val datawayClientToken = json.optString(KEY_DEMO_DATAWAY_CLIENT_TOKEN, "")
                val type = json.optInt(KEY_DEMO_APP_ACCESS_TYPE, 0)
                return SettingData(
                    datakitAddress,
                    demoApiAddress,
                    appId,
                    datawayAddress,
                    datawayClientToken,
                    type
                )
            } catch (_: Exception) {


            }
            return null

        }
    }
}

object SettingConfigManager {

    private var data: SettingData? = null

    fun saveSetting(data: SettingData) {
        this.data = data;
        val sharedPreferences = FTApplication.getApplication()
            .getSharedPreferences(PREFS_USER_DATA_NAME, Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        editor.putString(KEY_DEMO_DATAKIT_ADDRESS, data.datakitAddress)
        editor.putString(KEY_DEMO_API_ADDRESS, data.demoApiAddress)
        editor.putString(KEY_DEMO_APP_ID, data.appId)
        editor.putString(KEY_DEMO_DATAWAY_ADDRESS, data.datawayAddress)
        editor.putString(KEY_DEMO_DATAWAY_CLIENT_TOKEN, data.datawayClientToken)
        editor.putInt(KEY_DEMO_APP_ACCESS_TYPE, data.type)
        editor.apply()

    }


    fun readSetting(): SettingData {
        if (data != null) {
            return data!!
        }
        val sharedPreferences = FTApplication.getApplication()
            .getSharedPreferences(PREFS_USER_DATA_NAME, Context.MODE_PRIVATE)

        data = SettingData(
            sharedPreferences.getString(
                KEY_DEMO_DATAKIT_ADDRESS, if (BuildConfig.DEBUG)
                    BuildConfig.DATAKIT_URL
                else
                    DEFAULT_DATAKIT_ADDRESS
            )!!,
            sharedPreferences.getString(
                KEY_DEMO_API_ADDRESS, if (BuildConfig.DEBUG)
                    BuildConfig.DEMO_API_URL
                else
                    DEFAULT_API_ADDRESS
            )!!,
            sharedPreferences.getString(
                KEY_DEMO_APP_ID, if (BuildConfig.DEBUG)
                    BuildConfig.RUM_APP_ID
                else
                    DEFAULT_APP_ID
            )!!,
            sharedPreferences.getString(
                KEY_DEMO_DATAWAY_ADDRESS, if (BuildConfig.DEBUG)
                    BuildConfig.DATAWAY_URL
                else
                    DEFAULT_DATAWAY_ADDRESS
            )!!,
            sharedPreferences.getString(
                KEY_DEMO_DATAWAY_CLIENT_TOKEN, if (BuildConfig.DEBUG)
                    BuildConfig.DATAWAY_CLIENT_TOKEN
                else
                    DEFAULT_DATAWAY_CLIENT_TOKEN
            )!!,
            sharedPreferences.getInt(
                KEY_DEMO_APP_ACCESS_TYPE,
                AccessType.DATAKIT.value
            )
        )
        return data!!
    }


}