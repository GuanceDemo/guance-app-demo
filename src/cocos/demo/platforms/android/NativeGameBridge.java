package com.guance.cocos.demo;

import android.app.Activity;
import android.content.Intent;
import com.cocos.lib.GlobalObject;
import org.json.JSONObject;

/** App-owned navigation bridge. Only non-sensitive round data crosses this boundary. */
public final class NativeGameBridge {
    private static String action = "";
    private static boolean backRequested;
    static synchronized void requestBack() { backRequested = true; }
    public static synchronized boolean consumeBack() {
        boolean result = backRequested; backRequested = false; return result;
    }
    public static void show(String payload) {
        Activity host = GlobalObject.getActivity();
        if (host == null) throw new IllegalStateException("Cocos Activity is unavailable");
        synchronized (NativeGameBridge.class) { action = ""; backRequested = false; }
        host.runOnUiThread(() -> {
            try {
                Intent intent = new Intent(host, NativeGameActivity.class);
                intent.putExtra("payload", payload);
                host.startActivity(intent);
                host.overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
            } catch (RuntimeException error) {
                try { complete(new JSONObject(payload).optInt("requestId"), "unavailable"); }
                catch (Exception ignored) { /* No SDK credentials are passed or logged. */ }
            }
        });
    }
    static synchronized void complete(int requestId, String value) {
        try { action = new JSONObject().put("requestId", requestId).put("action", value).toString(); }
        catch (Exception ignored) { action = ""; }
    }
    public static synchronized String consumeAction() { String result = action; action = ""; return result; }
}
