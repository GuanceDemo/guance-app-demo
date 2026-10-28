package com.guance.cocos.demo;

import android.app.Application;

/** Install the host SDK before Creator starts the Cocos runtime. */
public final class NativeSdkApplication extends Application {
    @Override public void onCreate() {
        super.onCreate();
        NativeTelemetry.boot(this);
    }
}
