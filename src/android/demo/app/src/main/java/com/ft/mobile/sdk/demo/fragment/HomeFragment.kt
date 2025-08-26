package com.ft.mobile.sdk.demo.fragment

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.ft.mobile.sdk.demo.NativeActivity
import com.ft.mobile.sdk.demo.R
import com.ft.mobile.sdk.demo.WebViewActivity
import com.ft.mobile.sdk.demo.adapter.DividerItemDecoration
import com.ft.mobile.sdk.demo.adapter.ListItem
import com.ft.mobile.sdk.demo.adapter.SimpleAdapter

class HomeFragment : Fragment(), SimpleAdapter.OnItemClickListener {

    private lateinit var dataList: List<ListItem>

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {

        // Initialize dataList with context available
        dataList = listOf(
            ListItem("Native View", getString(R.string.native_view_description), R.drawable.ic_android),
            ListItem("WebView", getString(R.string.webview_description), R.drawable.ic_web)
        )

        val rootView = inflater.inflate(
            R.layout.fragment_item_index, container, false
        )
        val recyclerView: RecyclerView = rootView.findViewById(R.id.recyclerView)
        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.adapter = SimpleAdapter(dataList, this)
        recyclerView.addItemDecoration(
            DividerItemDecoration(
                context,
                androidx.appcompat.R.drawable.abc_list_divider_material
            )
        )
        return rootView
    }

    override fun onItemClick(data: String) {
        when (data) {
            "Native View" -> {
                startActivity(Intent(context, NativeActivity::class.java))

            }

            "WebView" -> {
                startActivity(Intent(context, WebViewActivity::class.java))

            }

        }
    }
}