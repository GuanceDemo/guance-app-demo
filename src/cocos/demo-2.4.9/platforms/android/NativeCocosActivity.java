package com.guance.cocos.demo;

import android.os.Build;
import android.os.Bundle;
import android.view.KeyEvent;
import android.window.OnBackInvokedCallback;
import android.window.OnBackInvokedDispatcher;
import org.cocos2dx.javascript.AppActivity;

/** Keep system Back separate from Cocos 2.4.9's Backspace keyboard mapping. */
public class NativeCocosActivity extends AppActivity {
    private OnBackInvokedCallback backCallback;
    private static volatile String safeArea = "";
    public static String safeArea() { return safeArea; }

    private void updateSafeArea() {
        if (Build.VERSION.SDK_INT < 23) return;
        android.view.View surface = getGLSurfaceView();
        if (surface == null || surface.getWidth() <= 0 || surface.getHeight() <= 0) return;
        android.view.WindowInsets insets = surface.getRootWindowInsets();
        if (insets == null) return;
        int left,top,right,bottom;
        android.graphics.Rect bounds;
        if (Build.VERSION.SDK_INT >= 30) {
            android.graphics.Insets bars = insets.getInsetsIgnoringVisibility(android.view.WindowInsets.Type.systemBars() | android.view.WindowInsets.Type.displayCutout());
            left=bars.left;top=bars.top;right=bars.right;bottom=bars.bottom;
            bounds=getWindowManager().getCurrentWindowMetrics().getBounds();
        } else {
            left=insets.getStableInsetLeft();top=insets.getStableInsetTop();right=insets.getStableInsetRight();bottom=insets.getStableInsetBottom();
            android.view.View decor=getWindow().getDecorView();int[] origin=new int[2];decor.getLocationOnScreen(origin);
            bounds=new android.graphics.Rect(origin[0],origin[1],origin[0]+decor.getWidth(),origin[1]+decor.getHeight());
        }
        int[] origin=new int[2];surface.getLocationOnScreen(origin);
        try {
            String snapshot=new org.json.JSONObject()
                .put("left",Math.max(0,bounds.left+left-origin[0])/(double)surface.getWidth())
                .put("top",Math.max(0,bounds.top+top-origin[1])/(double)surface.getHeight())
                .put("right",Math.max(0,origin[0]+surface.getWidth()-bounds.right+right)/(double)surface.getWidth())
                .put("bottom",Math.max(0,origin[1]+surface.getHeight()-bounds.bottom+bottom)/(double)surface.getHeight()).toString();
            if (!snapshot.equals(safeArea) && (getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) android.util.Log.d("CocosSafeArea",snapshot);
            safeArea=snapshot;
        } catch (org.json.JSONException ignored) { safeArea=""; }
    }

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        android.view.View surface = getGLSurfaceView();
        surface.getViewTreeObserver().addOnGlobalLayoutListener(this::updateSafeArea);
        surface.post(this::updateSafeArea);
        if (Build.VERSION.SDK_INT >= 33) {
            backCallback = NativeGameBridge::requestBack;
            getOnBackInvokedDispatcher().registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT, backCallback);
        }
    }

    @Override public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getKeyCode() == KeyEvent.KEYCODE_BACK) {
            if (event.getAction() == KeyEvent.ACTION_UP && !event.isCanceled()) NativeGameBridge.requestBack();
            return true;
        }
        return super.dispatchKeyEvent(event);
    }

    @Override public void onBackPressed() { NativeGameBridge.requestBack(); }

    @Override protected void onPause() {
        NativeGameBridge.consumeBack();
        super.onPause();
    }

    @Override protected void onDestroy() {
        if (Build.VERSION.SDK_INT >= 33 && backCallback != null) {
            getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback(backCallback);
        }
        super.onDestroy();
    }
}
