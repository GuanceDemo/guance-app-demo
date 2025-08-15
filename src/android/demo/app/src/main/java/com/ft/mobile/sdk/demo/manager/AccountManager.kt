package com.ft.mobile.sdk.demo.manager

import android.content.Context
import android.widget.Toast
import com.ft.mobile.sdk.demo.http.HttpEngine
import com.ft.mobile.sdk.demo.http.UserData
import com.ft.sdk.FTSdk
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection


@DelicateCoroutinesApi
object AccountManager {

    private const val PREFS_USER_DATA_NAME = "gc_demo_user_data"
    private const val KEY_USER_NAME = "username"
    private const val KEY_USER_EMAIL = "email"
    private const val KEY_USER_AVATAR = "avatar"

    var isLogin = false

    var userData: UserData? = null

    interface Callback {
        fun success(success: Boolean)
    }

    fun checkLogin(context: Context): Boolean {
        if (userData == null) {
            userData = readUserData(context)
        }


        isLogin = !(userData?.username.isNullOrEmpty()
                && userData?.avatar.isNullOrEmpty()
                && userData?.email.isNullOrEmpty())

        return isLogin
    }

    fun login(context: Context, userName: String, password: String, callback: Callback) {
        GlobalScope.launch(Dispatchers.IO) {
            val data = HttpEngine.login(context, userName, password)
            withContext(Dispatchers.Main) {
                if (data.code == HttpURLConnection.HTTP_OK) {
                    isLogin = true
                    callback.success(true)
                    getUserInfo(context)
                } else {
                    Toast.makeText(
                        context,
                        data.errorMessage,
                        Toast.LENGTH_SHORT
                    ).show()

                }
            }
        }
    }

    fun getUserInfo(context: Context, callback: ((success: Boolean) -> Unit)? = null) {
        GlobalScope.launch(Dispatchers.IO) {
            val data = HttpEngine.userinfo(context)

            withContext(Dispatchers.Main) {
                if (data.code == HttpURLConnection.HTTP_OK) {
                    saveUserData(context, data)

                    val userData = com.ft.sdk.garble.bean.UserData()
                    userData.email = data.email
                    userData.name = data.username
                    userData.id = data.email
                    FTSdk.bindRumUserData(userData)
                    callback?.let {
                        it(true)
                    }
                } else {
                    callback?.let {
                        it(false)
                    }
                }
            }
        }
    }

    private fun saveUserData(context: Context, data: UserData) {
        this.userData = data

        val sharedPreferences = context.getSharedPreferences(
            PREFS_USER_DATA_NAME,
            Context.MODE_PRIVATE
        )
        val editor = sharedPreferences.edit()
        editor.putString(KEY_USER_NAME, data.username)
        editor.putString(KEY_USER_EMAIL, data.email)
        editor.putString(KEY_USER_AVATAR, data.avatar)
        editor.apply()

    }

    private fun readUserData(context: Context): UserData {
        val sharedPreferences = context.getSharedPreferences(
            PREFS_USER_DATA_NAME,
            Context.MODE_PRIVATE
        )
        val userData = UserData()
        userData.username = sharedPreferences.getString(KEY_USER_NAME, null)
        userData.email = sharedPreferences.getString(KEY_USER_EMAIL, null)
        userData.avatar = sharedPreferences.getString(KEY_USER_AVATAR, null)
        return userData
    }

    private fun cleanUserData(context: Context) {
        val sharedPreferences = context
            .getSharedPreferences(PREFS_USER_DATA_NAME, Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        editor.clear()
        editor.apply()
    }

    fun logout(context: Context) {
        isLogin = false
        cleanUserData(context)
        userData = null
        FTSdk.unbindRumUserData()
    }


}



