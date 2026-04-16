package com.ft.mobile.sdk.demo

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.widget.ProgressBar
import com.ft.mobile.sdk.demo.manager.SettingConfigManager


class WebViewActivity : BaseActivity() {

    var webView: WebView? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_webview)
        
        // Setup Toolbar
        val toolbar: androidx.appcompat.widget.Toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        setupToolbar(toolbar)

        WebView.setWebContentsDebuggingEnabled(true)
        val data = SettingConfigManager.readSetting(this@WebViewActivity)
        title = intent.getStringExtra(EXTRA_TITLE) ?: getString(R.string.technical_webview_entry_title)

        webView = findViewById<WebView>(R.id.webView)
        val progressBar = findViewById<ProgressBar>(R.id.progressBar)

        // Configure WebView settings
        val webSettings: WebSettings = webView!!.settings
        webSettings.javaScriptEnabled = true // Enable JavaScript

        // Set WebViewClient to handle page loading
        webView!!.webChromeClient = object : WebChromeClient() {
            override fun onReceivedTitle(view: WebView, title: String) {
                super.onReceivedTitle(view, title)
                setTitle(title)
            }

            override fun onProgressChanged(view: WebView, newProgress: Int) {
                super.onProgressChanged(view, newProgress)
                progressBar.progress = newProgress
                if (newProgress == 100) {
                    progressBar.visibility = View.GONE
                } else {
                    progressBar.visibility = View.VISIBLE
                }
            }
        }

        // Load web page
        val targetUrl = intent.getStringExtra(EXTRA_URL)
            ?: "${data.demoApiAddress}?requestUrl=${data.getUserInfoUrl()}"
        webView!!.loadUrl(targetUrl)

    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.webview_menu, menu)
        return super.onCreateOptionsMenu(menu)
    }


    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.webview_refresh -> {
                webView?.reload()
            }
        }

        return super.onOptionsItemSelected(item)
    }

    companion object {
        private const val EXTRA_URL = "extra_url"
        private const val EXTRA_TITLE = "extra_title"

        fun newIntent(context: android.content.Context, title: String, url: String): android.content.Intent {
            return android.content.Intent(context, WebViewActivity::class.java)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_URL, url)
        }
    }

}
