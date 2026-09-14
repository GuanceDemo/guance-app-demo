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
import android.widget.EditText;
import android.widget.Switch;
import android.widget.Spinner;
import android.widget.ArrayAdapter;
import android.widget.AdapterView;
import android.text.InputType;
import android.view.WindowManager;
import org.json.JSONArray;
import java.util.LinkedHashMap;
import java.util.Map;
import org.json.JSONObject;

/** Real Android UI, displayed above the paused Cocos Activity. */
public final class NativeGameActivity extends Activity {
    private final int ink = Color.rgb(235, 242, 255), muted = Color.rgb(143, 162, 189), mint = Color.rgb(92, 242, 197);
    private JSONObject payload;
    private LinearLayout content;
    private boolean completed;
    private JSONObject draft;
    private EditText importInput;
    private final Map<String, View> inputs = new LinkedHashMap<>();
    private final Map<String, View> rows = new LinkedHashMap<>();
    private final Map<String, JSONArray> choices = new LinkedHashMap<>();
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
        if ("settings".equals(payload.optString("page"))) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
            getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
            try {
                draft = state != null && state.containsKey("draft") ? new JSONObject(state.getString("draft")) : payload.getJSONObject("config");
                settings();
                if (state != null) importInput.setText(state.getString("import", ""));
            } catch (Exception error) {
                label("Settings could not be loaded. Return and try again.", 16, ink, 12);
                action("Back to lobby", "lobby", false);
            }
            return;
        }
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
    private void settings() throws Exception {
        label("ANDROID NATIVE  /  SDK SETTINGS", 12, mint, 12);
        label("SDK settings", 34, ink, 12);
        label("Android App ID is used on this device. Save changes, then close and reopen the app if the SDK is already running.", 14, muted, 12);
        String message = payload.optString("settingsMessage");
        if (!message.isEmpty()) card("STATUS", message);
        label("Import gc-demo:// or JSON", 14, muted, 4);
        importInput = new EditText(this); importInput.setTextColor(ink); importInput.setHintTextColor(muted);
        importInput.setHint("Paste shared settings"); importInput.setMinLines(3);
        importInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        importInput.setFilters(new android.text.InputFilter[]{new android.text.InputFilter.LengthFilter(32768)});
        content.addView(importInput, new LinearLayout.LayoutParams(-1, -2));
        action("Import settings", "settings-import", false);
        JSONArray fields = payload.getJSONArray("fields");
        for (int i = 0; i < fields.length(); i++) {
            JSONObject field = fields.getJSONObject(i); String key = field.getString("key"), kind = field.getString("kind");
            LinearLayout row = new LinearLayout(this); row.setOrientation(LinearLayout.VERTICAL); row.setPadding(0, dp(8), 0, dp(12));
            content.addView(row, new LinearLayout.LayoutParams(-1, -2)); rows.put(key, row);
            TextView title = new TextView(this); title.setText(field.getString("label")); title.setTextColor(muted); title.setTextSize(14);
            row.addView(title);
            View input;
            if ("toggle".equals(kind)) {
                Switch toggle = new Switch(this); toggle.setText("Enabled"); toggle.setTextColor(ink);
                toggle.setChecked(draft.optBoolean(key)); input = toggle;
                toggle.setOnCheckedChangeListener((button, checked) -> updateDependencies());
            } else if ("choice".equals(kind)) {
                JSONArray options = field.getJSONArray("options"); choices.put(key, options);
                String[] labels = new String[options.length()]; int selected = 0;
                for (int j = 0; j < options.length(); j++) {
                    labels[j] = options.getJSONObject(j).getString("label");
                    if (options.getJSONObject(j).get("value").toString().equals(draft.optString(key))) selected = j;
                }
                Spinner spinner = new Spinner(this); ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, labels);
                spinner.setAdapter(adapter); spinner.setSelection(selected); input = spinner;
                spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                    public void onItemSelected(AdapterView<?> parent, View view, int position, long id) { updateDependencies(); }
                    public void onNothingSelected(AdapterView<?> parent) {}
                });
            } else {
                EditText edit = new EditText(this); edit.setTextColor(ink); edit.setSingleLine(true);
                edit.setInputType(InputType.TYPE_CLASS_TEXT | ("secret".equals(kind) ? InputType.TYPE_TEXT_VARIATION_PASSWORD : InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS));
                edit.setText(draft.optString(key)); edit.setSelectAllOnFocus(false); input = edit;
            }
            input.setContentDescription(field.getString("label")); input.setMinimumHeight(dp(48));
            row.addView(input, new LinearLayout.LayoutParams(-1, -2)); inputs.put(key, input);
        }
        updateDependencies();
        card("SESSION REPLAY", "1–5 FPS controls capture frequency, not game rendering. Quality presets control resolution, compression and traffic budget. Adaptive capture may reduce the actual frame rate.");
        action("Check connection", "settings-check", false);
        action("Save settings", "settings-save", true);
        action("Cancel / Back to lobby", "lobby", false);
    }
    private JSONObject collectSettings() throws Exception {
        JSONObject result = new JSONObject(draft.toString());
        for (Map.Entry<String, View> entry : inputs.entrySet()) {
            View input = entry.getValue(); Object value;
            if (input instanceof Switch) value = ((Switch) input).isChecked();
            else if (input instanceof Spinner) value = choices.get(entry.getKey()).getJSONObject(((Spinner) input).getSelectedItemPosition()).get("value");
            else value = ((EditText) input).getText().toString().trim();
            result.put(entry.getKey(), value);
        }
        return result;
    }
    private void updateDependencies() {
        if (!inputs.containsKey("replayQuality")) return;
        boolean sdk = ((Switch) inputs.get("enableSdk")).isChecked();
        boolean replay = sdk && ((Switch) inputs.get("enableSessionReplay")).isChecked();
        for (Map.Entry<String, View> entry : inputs.entrySet()) {
            String key = entry.getKey();
            boolean enabled = key.equals("enableSdk") || key.equals("demoApiAddress") || sdk;
            if (key.equals("replayFps") || key.equals("replayQuality")) enabled = replay;
            entry.getValue().setEnabled(enabled); rows.get(key).setAlpha(enabled ? 1 : .45f);
        }
        boolean datakit = ((Spinner) inputs.get("accessType")).getSelectedItemPosition() == 0;
        rows.get("datakitAddress").setVisibility(datakit ? View.VISIBLE : View.GONE);
        rows.get("datawayAddress").setVisibility(datakit ? View.GONE : View.VISIBLE);
        rows.get("datawayClientToken").setVisibility(datakit ? View.GONE : View.VISIBLE);
    }
    @Override protected void onResume() {
        super.onResume();
        if (payload != null) NativeTelemetry.startNativeView(payload.optString("page"));
    }
    @Override protected void onPause() {
        NativeTelemetry.stopNativeView();
        super.onPause();
    }
    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        if (draft != null) try { state.putString("draft", collectSettings().toString()); state.putString("import", importInput.getText().toString()); }
        catch (Exception ignored) { /* Never log settings. */ }
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
            if (completed) return;
            if (value.startsWith("settings-")) {
                try { NativeGameBridge.complete(payload.optInt("requestId"), value, collectSettings(), importInput.getText().toString()); }
                catch (Exception error) { label("Unable to read settings. Please try again.", 14, ink, 8); return; }
            } else NativeGameBridge.complete(payload.optInt("requestId"), value);
            NativeTelemetry.action(value);
            completed = true; finish();
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        });
    }
    @Override public void onBackPressed() {
        if ("lobby".equals(payload.optString("page"))) { moveTaskToBack(true); return; }
        if (!completed) { completed = true; NativeGameBridge.complete(payload.optInt("requestId"), "lobby"); }
        super.onBackPressed();
    }
}
