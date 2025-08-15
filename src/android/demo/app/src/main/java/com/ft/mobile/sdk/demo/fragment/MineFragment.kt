package com.ft.mobile.sdk.demo.fragment

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.ft.mobile.sdk.demo.BuildConfig
import com.ft.mobile.sdk.demo.MainActivity
import com.ft.mobile.sdk.demo.R
import com.ft.mobile.sdk.demo.data.AccessType
import com.ft.mobile.sdk.demo.manager.AccountManager
import com.ft.mobile.sdk.demo.manager.SettingConfigManager
import com.ft.mobile.sdk.demo.utils.CircleTransform
import com.ft.sdk.FTRUMGlobalManager
import com.squareup.picasso.Picasso
import kotlinx.coroutines.DelicateCoroutinesApi

@DelicateCoroutinesApi
class MineFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val view = inflater.inflate(R.layout.fragment_item_mine, container, false)
        setUpView(view)
        return view

    }

    private fun setUpView(view: View) {
        view.findViewById<View>(R.id.mine_edit_setting).setOnClickListener {
            startActivity(Intent(context, com.ft.mobile.sdk.demo.SettingActivity::class.java))
        }

        bindUserView(view)

        view.findViewById<View>(R.id.mine_logout).setOnClickListener {

            context?.let { c1 -> AccountManager.logout(c1) }
            (context as MainActivity).goToLogin()
        }

        view.findViewById<TextView>(R.id.mine_app_version).text =
            "${BuildConfig.VERSION_NAME}${(if (BuildConfig.DEBUG) "-Debug" else "")} (${BuildConfig.VERSION_CODE})"

        context?.let {
           val settingData= SettingConfigManager.readSetting(it)
            view.findViewById<TextView>(R.id.mine_settings_access_type_label).text = getString(
                R.string.sdk_access_type_format,
                if (settingData.type == AccessType.DATAKIT.value) "Datakit" else "Dataway"
            )
        }
        val refreshView: SwipeRefreshLayout = view.findViewById(R.id.mine_refresh_layout)
        refreshView.setOnRefreshListener {
            FTRUMGlobalManager.get().startAction("User data refresh", "refresh_user_data")
            refreshUserInfo(view) {
                refreshView.isRefreshing = false
            }

        }

        view.findViewById<View>(R.id.mine_user_info_rl).setOnClickListener {
            refreshUserInfo(view)
        }
    }

    private fun refreshUserInfo(view: View, callback: ((success: Boolean) -> Unit)? = null) {
        Toast.makeText(context, "Refreshing", Toast.LENGTH_SHORT).show()
        context?.let {
            AccountManager.getUserInfo(it) { success ->
                callback?.let {
                    it(success)
                }
                if (success) {
                    bindUserView(view)
                    Toast.makeText(it, "Success", Toast.LENGTH_SHORT).show()
                } else {
                    Toast.makeText(it, "Fail", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun bindUserView(view: View) {
        val userdata = AccountManager.userData

        val avatarIv = view.findViewById<ImageView>(R.id.mine_avatar)
        Picasso.get()
            .load(userdata?.avatar)
            .transform(CircleTransform())
//            .placeholder(R.drawable.placeholder) // Optional placeholder image while loading
//            .error(R.drawable.error_image) // Optional error image if the loading fails
            .into(avatarIv)
        val userNameTv = view.findViewById<TextView>(R.id.mine_username)
        userNameTv.text = userdata?.username
        val emailTv = view.findViewById<TextView>(R.id.mine_email)
        emailTv.text = userdata?.email
    }


}