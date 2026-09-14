package com.guance.cocos.demo;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import com.ft.sdk.FTSDKConfig;
import com.ft.sdk.FTRUMConfig;
import com.ft.sdk.FTLoggerConfig;
import com.ft.sdk.FTTraceConfig;
import com.ft.sdk.FTRUMGlobalManager;
import com.ft.sdk.FTSdk;
import com.ft.sdk.TraceType;
import com.ft.sdk.sessionreplay.FTSessionReplayConfig;
import org.json.JSONObject;
import java.util.Collections;
import java.util.HashMap;
import java.util.concurrent.FutureTask;

/** App-owned initialization and storage. All SDK lifecycle operations run on the main thread. */
public final class NativeTelemetry {
    private static final String STORE = "gc_demo_hybrid", KEY = "settings";
    private static Context context;
    private static boolean started, stopped, nativeView;

    public static void boot(Context application) {
        context = application.getApplicationContext();
        String saved = read();
        if (!saved.isEmpty()) try { initialize(new JSONObject(saved)); }
        catch (Exception ignored) { /* The settings screen remains available; never log credentials. */ }
    }
    private static String read() { return context.getSharedPreferences(STORE, Context.MODE_PRIVATE).getString(KEY, ""); }
    private static void save(JSONObject config) {
        if (!context.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit().putString(KEY, config.toString()).commit())
            throw new IllegalStateException("Settings could not be saved");
    }
    public static String invoke(String method, String payload) {
        if (Looper.myLooper() == Looper.getMainLooper()) return invokeMain(method, payload);
        FutureTask<String> task = new FutureTask<>(() -> invokeMain(method, payload));
        new Handler(Looper.getMainLooper()).post(task);
        try { return task.get(); }
        catch (Exception error) { return "{\"ok\":false,\"error\":\"Native SDK host is unavailable\"}"; }
    }
    private static String invokeMain(String method, String payload) {
        try {
            Object result = null;
            switch (method) {
                case "read": result = read(); break;
                case "save": save(new JSONObject(payload)); break;
                case "initialize": {
                    JSONObject config = new JSONObject(payload);
                    initialize(config);
                    if (!started) throw new IllegalStateException("Native SDK is disabled");
                    // Only migrate an old localStorage installation; never overwrite pending settings.
                    if (read().isEmpty()) save(config);
                    break;
                }
                case "disable":
                    if (started) { stopNativeView(); FTSdk.shutDown(); started = false; stopped = true; }
                    result = stopped;
                    break;
                default: throw new IllegalArgumentException("Unknown host operation");
            }
            JSONObject response = new JSONObject().put("ok", true);
            if (result != null) response.put("value", result);
            return response.toString();
        } catch (Exception error) {
            return "{\"ok\":false,\"error\":\"Native SDK setup failed. Check settings and restart the app.\"}";
        }
    }
    private static void initialize(JSONObject config) throws Exception {
        if (started || !config.optBoolean("enableSdk", true)) return;
        if (stopped) throw new IllegalStateException("Restart the app before reinitializing the SDK");
        String appId = config.optString("demoAndroidAppId").trim();
        if (appId.isEmpty()) throw new IllegalArgumentException("Android App ID is required");
        FTSDKConfig sdk;
        if ("datakit".equals(config.optString("accessType", "datakit"))) {
            String url = config.optString("datakitAddress").trim();
            if (url.isEmpty()) throw new IllegalArgumentException("DataKit URL is required");
            sdk = FTSDKConfig.builder(url);
        } else {
            String url = config.optString("datawayAddress").trim(), token = config.optString("datawayClientToken").trim();
            if (url.isEmpty() || token.isEmpty()) throw new IllegalArgumentException("DataWay settings are required");
            sdk = FTSDKConfig.builder(url, token);
        }
        sdk.setServiceName("guance_cocos_demo").setEnv("common").setDebug(config.optBoolean("debug", false));
        sdk.addGlobalContext("demo_platform", "android"); sdk.addGlobalContext("demo_framework", "cocos");
        sdk.addGlobalContext("demo_version", "1.0.0"); sdk.addGlobalContext("creator_version", "3.8.8");
        try {
            FTSdk.install(sdk);
            FTRUMConfig rum = new FTRUMConfig().setRumAppId(appId).setSamplingRate(1f)
                // Both native pages and Cocos pages own distinct manual Views / Actions.
                .setEnableTraceUserView(false).setEnableTraceUserAction(false)
                .setEnableTraceUserResource(true).setEnableHttpURLConnectionResource(false)
                .setEnableTrackAppCrash(config.optBoolean("enableNativeCrash", true))
                .setEnableTrackAppANR(config.optBoolean("enableNativeAnr", true))
                .setEnableTrackAppUIBlock(config.optBoolean("enableNativeUiBlock", true));
            FTSdk.initRUMWithConfig(rum);
            FTSdk.initLogWithConfig(new FTLoggerConfig().setSamplingRate(1f).setEnableCustomLog(true)
                .setEnableLinkRumData(true).setPrintCustomLogToConsole(false));
            // Cocos injects headers for XHR. Keep native automatic injection off for that path.
            FTSdk.initTraceWithConfig(new FTTraceConfig().setSamplingRate(1f).setTraceType(TraceType.DDTRACE)
                .setEnableLinkRUMData(true).setEnableAutoTrace(false));
            if (config.optBoolean("enableSessionReplay", true)) {
                // Keep the default native recorder and privacy settings. Hybrid switches it at page boundaries.
                FTSdk.initSessionReplayConfig(new FTSessionReplayConfig().setSampleRate(1f));
            }
            started = true;
        } catch (Exception error) {
            FTSdk.shutDown(); stopped = true;
            throw error;
        }
    }
    public static void startNativeView(String page) {
        if (!started) return;
        stopNativeView();
        String name = "settings".equals(page) ? "NativeSdkSettings" : "results".equals(page) ? "NativeRoundResults" : "NativeGameLobby";
        FTRUMGlobalManager.get().startView(name, new HashMap<String, Object>(Collections.singletonMap("demo_scenario", "hybrid_native")));
        nativeView = true;
    }
    public static void stopNativeView() {
        if (started && nativeView) FTRUMGlobalManager.get().stopView();
        nativeView = false;
    }
    public static void action(String destination) {
        if (started && nativeView) FTRUMGlobalManager.get().addAction("native_navigation", "click", new HashMap<String, Object>(Collections.singletonMap("destination", destination)));
    }
}
