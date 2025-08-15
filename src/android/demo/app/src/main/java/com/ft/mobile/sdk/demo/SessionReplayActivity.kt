package com.ft.mobile.sdk.demo

import android.graphics.Color
import android.graphics.PorterDuff
import android.os.Bundle
import androidx.appcompat.widget.Toolbar
import androidx.fragment.app.Fragment
import androidx.viewpager2.widget.ViewPager2
import com.ft.mobile.sdk.demo.adapter.ViewPagerAdapter
import com.ft.mobile.sdk.demo.fragment.SessionReplayMaterialFragment
import com.ft.mobile.sdk.demo.fragment.SessionReplayAppcompatFragment
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator


class SessionReplayActivity : BaseActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        setContentView(R.layout.activity_session_replay)
        // Setup Toolbar
        val toolbar: Toolbar = findViewById(R.id.toolbar)
        toolbar.setTitleTextColor(getColor(R.color.white))
        setSupportActionBar(toolbar)
        super.onCreate(savedInstanceState)
        val navIcon = toolbar.navigationIcon
        navIcon?.setColorFilter(Color.WHITE, PorterDuff.Mode.SRC_ATOP)

        title = "Session Replay"

        // Setup ViewPager2 and Adapter
        val viewPager: ViewPager2 = findViewById(R.id.view_pager)
        val fragments: MutableList<Fragment> = ArrayList()
        fragments.add(SessionReplayMaterialFragment())
        fragments.add(SessionReplayAppcompatFragment())

        val adapter = ViewPagerAdapter(this, fragments)
        viewPager.adapter = adapter

        // Setup TabLayout
        val tabLayout: TabLayout = findViewById(R.id.tab_layout)

        TabLayoutMediator(tabLayout, viewPager) { tab, position ->
            when (position) {
                0 -> tab.text = "Material"
                1 -> tab.text = "Appcompat"
            }
        }.attach()
    }
}