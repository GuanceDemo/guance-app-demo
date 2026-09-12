package com.guance.cocos.demo;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import org.json.JSONObject;

/** Real Android UI, displayed above the paused Cocos Activity. */
public final class NativeGameActivity extends Activity {
    private final int ink = Color.rgb(235, 242, 255), muted = Color.rgb(143, 162, 189), mint = Color.rgb(92, 242, 197);
    private JSONObject payload;
    private LinearLayout content;
    private boolean completed;
    private int dp(float value) { return Math.round(value * getResources().getDisplayMetrics().density); }
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        try { payload = new JSONObject(getIntent().getStringExtra("payload")); }
        catch (Exception error) { finish(); return; }
        getWindow().setStatusBarColor(Color.rgb(9, 17, 33));
        getWindow().setNavigationBarColor(Color.rgb(9, 17, 33));
        ScrollView scroll = new ScrollView(this); scroll.setFillViewport(true);
        scroll.setBackgroundColor(Color.rgb(9, 17, 33));
        content = new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(26), dp(28), dp(26), dp(30));
        scroll.addView(content, new ScrollView.LayoutParams(-1, -2)); setContentView(scroll);
        boolean results = "results".equals(payload.optString("page"));
        label("GUANCE  /  ARCADE", 13, mint, 8);
        label(results ? "ROUND COMPLETE" : "ANDROID NATIVE  /  GAME LOBBY", 11, muted, 18);
        label(results ? "Nice flying." : "Crystal Dash", 38, ink, 8);
        label(results ? "Your Cocos round, back in a native screen." : "A little focus. A lot of sparkle.", 16, muted, 14);
        if (results) {
            label(String.valueOf(payload.optInt("score")), 64, mint, 0);
            label("POINTS EARNED", 12, muted, 22);
            card("ROUND STATS", payload.optInt("gems") + " gems collected   ·   " + payload.optDouble("duration") + "s played\n"
                + ("health".equals(payload.optString("reason")) ? "All shields used" : "Time completed")
                + "   ·   Best " + payload.optInt("best"));
            action("Play again", "play", true);
            action("Back to lobby", "lobby", false);
            action("Open SDK lab", "lab", false);
        } else {
            View artwork = new View(this) {
                final Paint paint = new Paint(3);
                @Override protected void onDraw(Canvas canvas) {
                    super.onDraw(canvas);
                    float w = getWidth(), h = getHeight();
                    paint.setColor(Color.rgb(19, 34, 57)); canvas.drawRoundRect(0, 0, w, h, dp(22), dp(22), paint);
                    paint.setColor(Color.rgb(50, 76, 106));
                    for (int i = 0; i < 25; i++) canvas.drawCircle((i * 83 % 100) * w / 100, (i * 47 % 100) * h / 100, dp(1.5f), paint);
                    paint.setColor(mint);
                    Path ship = new Path(); ship.moveTo(w * .50f, h * .25f); ship.lineTo(w * .64f, h * .77f);
                    ship.lineTo(w * .50f, h * .64f); ship.lineTo(w * .36f, h * .77f); ship.close(); canvas.drawPath(ship, paint);
                    paint.setColor(Color.rgb(255, 220, 118));
                    for (int i = 0; i < 3; i++) { float x = w * (.2f + .3f * i), y = h * (i == 1 ? .12f : .4f);
                        Path gem = new Path(); gem.moveTo(x, y - dp(9)); gem.lineTo(x + dp(7), y); gem.lineTo(x, y + dp(9)); gem.lineTo(x - dp(7), y); gem.close(); canvas.drawPath(gem, paint); }
                }
            };
            LinearLayout.LayoutParams art = new LinearLayout.LayoutParams(-1, dp(170)); art.bottomMargin = dp(18); content.addView(artwork, art);
            card("45 SECONDS  ·  3 SHIELDS", "Drag to fly. Collect green gems and dodge red meteors. Build a streak for bonus points.");
            label("PERSONAL BEST   " + payload.optInt("best"), 13, mint, 12);
            action("Play Crystal Dash", "play", true);
            action("SDK experiments", "lab", false);
            action("Connection settings", "settings", false);
        }
        label(payload.optString("sdkStatus", "SDK not configured"), 12, muted, 8);
        label("NATIVE UI → COCOS GAME → NATIVE RESULTS", 10, muted, 0);
    }
    private void label(String value, int size, int color, int bottom) {
        TextView text = new TextView(this); text.setText(value); text.setTextSize(size); text.setTextColor(color);
        text.setTypeface(Typeface.create("sans-serif", size >= 30 ? Typeface.BOLD : Typeface.NORMAL));
        text.setLineSpacing(dp(3), 1); LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, -2);
        params.bottomMargin = dp(bottom); content.addView(text, params);
    }
    private void card(String title, String message) { label(title, 12, mint, 7); label(message, 15, muted, 20); }
    private void action(String title, String value, boolean primary) {
        Button button = new Button(this); button.setText(title); button.setAllCaps(false); button.setTextSize(16);
        button.setTextColor(primary ? Color.rgb(9, 17, 33) : ink); button.setGravity(Gravity.CENTER);
        GradientDrawable background = new GradientDrawable(); background.setColor(primary ? mint : Color.rgb(25, 40, 62)); background.setCornerRadius(dp(14));
        button.setBackground(background); LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, dp(52));
        params.bottomMargin = dp(12); content.addView(button, params);
        button.setOnClickListener(view -> {
            if (completed) return; completed = true;
            NativeGameBridge.complete(payload.optInt("requestId"), value); finish();
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        });
    }
    @Override public void onBackPressed() {
        if ("lobby".equals(payload.optString("page"))) { moveTaskToBack(true); return; }
        if (!completed) { completed = true; NativeGameBridge.complete(payload.optInt("requestId"), "lobby"); }
        super.onBackPressed();
    }
}
