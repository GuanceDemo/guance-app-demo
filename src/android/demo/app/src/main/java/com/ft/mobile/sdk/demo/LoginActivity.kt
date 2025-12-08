package com.ft.mobile.sdk.demo

import android.content.Intent
import android.os.Bundle
import android.text.SpannableString
import android.text.Spanned
import android.text.style.UnderlineSpan
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import com.ft.mobile.sdk.demo.data.DEFAULT_PASSWORD
import com.ft.mobile.sdk.demo.data.DEFAULT_USER_NAME
import com.ft.mobile.sdk.demo.manager.AccountManager
import com.google.android.material.textfield.TextInputEditText
import kotlinx.coroutines.DelicateCoroutinesApi


@DelicateCoroutinesApi
class LoginActivity : AppCompatActivity(), AccountManager.Callback {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupStatusBar()
        setContentView(R.layout.activity_login)

        // Apply window insets to handle edge-to-edge display
        val rootView = findViewById<View>(android.R.id.content)
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        val usernameEt = findViewById<TextInputEditText>(R.id.login_username)
        val passwordEt = findViewById<TextInputEditText>(R.id.login_password)

        findViewById<Button>(R.id.login_btn).setOnClickListener {
            AccountManager.login(
                this@LoginActivity,
                usernameEt.text.toString(),
                passwordEt.text.toString(),
                this
            )
        }
        supportActionBar?.hide()

        usernameEt.setText(DEFAULT_USER_NAME)
        passwordEt.setText(DEFAULT_PASSWORD)


        val editBtn = findViewById<TextView>(R.id.login_setting_btn)

        val spannableString = SpannableString(getString(R.string.edit_setting))

        val underlineSpan = UnderlineSpan()

        spannableString.setSpan(
            underlineSpan,
            0,
            spannableString.length,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        )

        editBtn.text = spannableString

        editBtn.setOnClickListener {
            startActivity(Intent(this, com.ft.mobile.sdk.demo.SettingActivity::class.java))
        }
    }


    override fun success(success: Boolean) {
        if (success) {
            setResult(RESULT_OK)
            finish()
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
        finishAffinity()
    }

    private fun setupStatusBar() {
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        // Force light theme: always use dark icons on light background
        windowInsetsController.isAppearanceLightStatusBars = true
        window.statusBarColor = android.graphics.Color.TRANSPARENT
    }

}