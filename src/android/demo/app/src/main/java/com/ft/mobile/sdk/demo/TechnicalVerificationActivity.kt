package com.ft.mobile.sdk.demo

import android.content.Intent
import android.os.Bundle
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.ft.mobile.sdk.demo.adapter.DividerItemDecoration
import com.ft.mobile.sdk.demo.adapter.ListItem
import com.ft.mobile.sdk.demo.adapter.SimpleAdapter

class TechnicalVerificationActivity : BaseActivity(), SimpleAdapter.OnItemClickListener {

    private lateinit var dataList: List<ListItem>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = getString(R.string.technical_verification_entry_title)
        setContentView(R.layout.activity_technical_verification)

        val toolbar: androidx.appcompat.widget.Toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        setupToolbar(toolbar)

        dataList = listOf(
            ListItem(
                getString(R.string.technical_native_entry_title),
                getString(R.string.technical_native_entry_description),
                R.drawable.ic_android
            ),
            ListItem(
                getString(R.string.technical_webview_entry_title),
                getString(R.string.technical_webview_entry_description),
                R.drawable.ic_web
            )
        )

        val recyclerView: RecyclerView = findViewById(R.id.recyclerView)
        recyclerView.layoutManager = LinearLayoutManager(this)
        recyclerView.adapter = SimpleAdapter(dataList, this)
        recyclerView.addItemDecoration(
            DividerItemDecoration(
                this,
                androidx.appcompat.R.drawable.abc_list_divider_material
            )
        )
    }

    override fun onItemClick(data: String) {
        when (data) {
            getString(R.string.technical_native_entry_title) -> {
                startActivity(Intent(this, NativeActivity::class.java))
            }

            getString(R.string.technical_webview_entry_title) -> {
                startActivity(Intent(this, WebViewActivity::class.java))
            }
        }
    }
}
