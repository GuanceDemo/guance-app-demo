package com.ft.mobile.sdk.demo

import android.app.Application
import com.ft.mobile.sdk.demo.DemoApplication.Companion.setSDK
import com.ft.sdk.FTAutoTrack

/**
 * Use this initialization method when not using ft-plugin
 */
class DemoForManualSet : Application() {

    override fun onCreate() {
        super.onCreate()
        // Must be called before SDK initialization
        FTAutoTrack.startApp(null)
        // Set SDK configuration
        setSDK(this)

    }
}