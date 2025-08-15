package com.ft.mobile.sdk.demo.manager

import android.content.Context
import com.ft.mobile.sdk.demo.BuildConfig
import com.ft.mobile.sdk.demo.data.AccessType
import com.ft.mobile.sdk.demo.data.DEFAULT_API_ADDRESS
import com.ft.mobile.sdk.demo.data.DEFAULT_APP_ID
import com.ft.mobile.sdk.demo.data.DEFAULT_DATAKIT_ADDRESS
import com.ft.mobile.sdk.demo.data.DEFAULT_DATAWAY_ADDRESS
import com.ft.mobile.sdk.demo.data.DEFAULT_DATAWAY_CLIENT_TOKEN
import com.ft.mobile.sdk.demo.data.DEFAULT_OTEL_ADDRESS
import com.ft.mobile.sdk.demo.http.HttpEngine
import com.ft.sdk.FTApplication
import com.ft.sdk.sessionreplay.SessionReplayPrivacy
import org.json.JSONObject

private const val PREFS_USER_DATA_NAME = "gc_demo_sdk_setting"
private const val KEY_DEMO_DATAKIT_ADDRESS = "datakitAddress"
private const val KEY_DEMO_DATAWAY_ADDRESS = "datawayAddress"
private const val KEY_OTEL_ADDRESS = "otelAddress"
private const val KEY_DEMO_DATAWAY_CLIENT_TOKEN = "datawayClientToken"
private const val KEY_DEMO_APP_ACCESS_TYPE = "appAccessType"
private const val KEY_DEMO_API_ADDRESS = "demoApiAddress"
private const val KEY_DEMO_APP_ID = "demoAndroidAppId"
private const val KEY_DEMO_ENABLE_SESSION_REPLAY = "demoEnableSessionReplay"
private const val KEY_DEMO_ENABLE_SESSION_REPLAY_PRIVACY_TYPE = "demoEnableSessionReplayPrivacyType"

data class SettingData(
    val datakitAddress: String,
    val demoApiAddress: String,
    val appId: String,
    val datawayAddress: String,
    val datawayClientToken: String,
    val otelAddress: String,
    val type: Int,
    val enableSessionReplay: Boolean,
    val sessionReplayPrivacyType: SessionReplayPrivacy
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
                val otelAddress = json.optString(KEY_OTEL_ADDRESS, "")
                val type = json.optInt(KEY_DEMO_APP_ACCESS_TYPE, 0)
                val enableSessionReplay = json.optBoolean(KEY_DEMO_ENABLE_SESSION_REPLAY, false)
                val sessionReplayType = json.optInt(KEY_DEMO_ENABLE_SESSION_REPLAY_PRIVACY_TYPE, 0)
                return SettingData(
                    datakitAddress,
                    demoApiAddress,
                    appId,
                    datawayAddress,
                    datawayClientToken,
                    otelAddress,
                    type,
                    enableSessionReplay,
                    SessionReplayPrivacy.values()[sessionReplayType]
                )
            } catch (_: Exception) {


            }
            return null

        }
    }
}

object SettingConfigManager {

    private var data: SettingData? = null

    private val defaultDatakitUrl: String by lazy {
        if (BuildConfig.DEBUG) {
            BuildConfig.DATAKIT_URL.ifEmpty { DEFAULT_DATAKIT_ADDRESS }
        } else {
            DEFAULT_DATAKIT_ADDRESS
        }
    }

    private val defaultDemoApiUrl: String by lazy {
        if (BuildConfig.DEBUG)
            BuildConfig.DEMO_API_URL.ifEmpty { DEFAULT_API_ADDRESS }
        else
            DEFAULT_API_ADDRESS
    }

    private val defaultAppId: String by lazy {
        if (BuildConfig.DEBUG)
            BuildConfig.RUM_APP_ID.ifEmpty { DEFAULT_APP_ID }
        else
            DEFAULT_APP_ID
    }

    private val defaulDatawayUrl: String by lazy {
        if (BuildConfig.DEBUG)
            BuildConfig.DATAWAY_URL.ifEmpty { DEFAULT_DATAWAY_ADDRESS }
        else
            DEFAULT_DATAWAY_ADDRESS
    }

    private val defaultDatawayClientToken: String by lazy {
        if (BuildConfig.DEBUG)
            BuildConfig.DATAWAY_CLIENT_TOKEN.ifEmpty { DEFAULT_DATAWAY_CLIENT_TOKEN }
        else
            DEFAULT_DATAWAY_ADDRESS
    }

    private val defaultOtelUrl: String by lazy {
        if (BuildConfig.DEBUG)
            BuildConfig.OTEL_URL.ifEmpty { DEFAULT_OTEL_ADDRESS }
        else
            DEFAULT_OTEL_ADDRESS
    }

    fun saveSetting(context: Context,data: SettingData) {
        this.data = data;
        val sharedPreferences = context
            .getSharedPreferences(PREFS_USER_DATA_NAME, Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        editor.putString(KEY_DEMO_DATAKIT_ADDRESS, data.datakitAddress)
        editor.putString(KEY_DEMO_API_ADDRESS, data.demoApiAddress)
        editor.putString(KEY_DEMO_APP_ID, data.appId)
        editor.putString(KEY_DEMO_DATAWAY_ADDRESS, data.datawayAddress)
        editor.putString(KEY_DEMO_DATAWAY_CLIENT_TOKEN, data.datawayClientToken)
        editor.putString(KEY_OTEL_ADDRESS, data.otelAddress.ifEmpty { defaultOtelUrl })
        editor.putInt(KEY_DEMO_APP_ACCESS_TYPE, data.type)
        editor.putBoolean(KEY_DEMO_ENABLE_SESSION_REPLAY, data.enableSessionReplay)
        editor.putInt(KEY_DEMO_ENABLE_SESSION_REPLAY_PRIVACY_TYPE, data.sessionReplayPrivacyType.ordinal)
        editor.apply()

    }


    fun readSetting(context: Context): SettingData {
        if (data != null) {
            return data!!
        }
        val sharedPreferences = context
            .getSharedPreferences(PREFS_USER_DATA_NAME, Context.MODE_PRIVATE)

        data = SettingData(
            sharedPreferences.getString(KEY_DEMO_DATAKIT_ADDRESS, defaultDatakitUrl)!!,
            sharedPreferences.getString(KEY_DEMO_API_ADDRESS, defaultDemoApiUrl)!!,
            sharedPreferences.getString(KEY_DEMO_APP_ID, defaultAppId)!!,
            sharedPreferences.getString(KEY_DEMO_DATAWAY_ADDRESS, defaulDatawayUrl)!!,
            sharedPreferences.getString(KEY_DEMO_DATAWAY_CLIENT_TOKEN, defaultDatawayClientToken)!!,
            sharedPreferences.getString(KEY_OTEL_ADDRESS, defaultOtelUrl)!!,
            sharedPreferences.getInt(KEY_DEMO_APP_ACCESS_TYPE, AccessType.DATAKIT.value),
            sharedPreferences.getBoolean(
                KEY_DEMO_ENABLE_SESSION_REPLAY,
                false
            ),
            SessionReplayPrivacy.values()[sharedPreferences.getInt(
                KEY_DEMO_ENABLE_SESSION_REPLAY_PRIVACY_TYPE,
                0
            )]
        )
        return data!!
    }


}