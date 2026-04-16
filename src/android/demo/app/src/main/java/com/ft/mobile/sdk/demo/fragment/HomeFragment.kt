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
import com.ft.mobile.sdk.demo.RealScenarioListActivity
import com.ft.mobile.sdk.demo.TechnicalVerificationActivity
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
            ListItem(
                getString(R.string.real_scenario_entry_title),
                getString(R.string.real_scenario_entry_description),
                R.drawable.ic_real_scene
            ),
            ListItem(
                getString(R.string.technical_verification_entry_title),
                getString(R.string.technical_verification_entry_description),
                R.drawable.ic_test_scene
            )
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
            getString(R.string.real_scenario_entry_title) -> {
                startActivity(Intent(context, RealScenarioListActivity::class.java))

            }

            getString(R.string.technical_verification_entry_title) -> {
                startActivity(Intent(context, TechnicalVerificationActivity::class.java))

            }

        }
    }
}
