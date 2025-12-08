package com.ft.mobile.sdk.demo

import android.graphics.Color
import android.graphics.PorterDuff
import android.os.Bundle
import android.view.MenuItem
import androidx.appcompat.app.ActionBar
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.core.view.WindowCompat

open class BaseActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupStatusBar()
    }

    protected fun setupStatusBar() {
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        // Force light theme: always use dark icons on light background
        windowInsetsController.isAppearanceLightStatusBars = true
        window.statusBarColor = android.graphics.Color.TRANSPARENT
    }

    /**
     * Setup Toolbar with white title and navigation icon
     * Call this after setSupportActionBar(toolbar)
     */
    protected fun setupToolbar(toolbar: Toolbar) {
        // Enable home button (back arrow)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        // Set white title text color
        toolbar.setTitleTextColor(Color.WHITE)
        // Set white navigation icon
        val navIcon = toolbar.navigationIcon
        navIcon?.setColorFilter(Color.WHITE, PorterDuff.Mode.SRC_ATOP)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            android.R.id.home -> {
                finish()
            }
        }
        return super.onOptionsItemSelected(item)
    }


}