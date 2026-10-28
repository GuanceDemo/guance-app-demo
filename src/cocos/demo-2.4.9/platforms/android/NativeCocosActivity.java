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

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
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
