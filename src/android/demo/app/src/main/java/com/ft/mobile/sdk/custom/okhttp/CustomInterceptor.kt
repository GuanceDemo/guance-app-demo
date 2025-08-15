package com.ft.mobile.sdk.custom.okhttp

import okhttp3.Interceptor
import okhttp3.Response

/**
 * Custom implementation of an interceptor. If you need to process request data a second time, please place the Interceptor at the end, otherwise you may lose Resource data.
 * @see com.ft.mobile.sdk.demo.ManualActivity
 */
class CustomInterceptor : okhttp3.Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        // Implement your method here
        return chain.proceed(chain.request())
    }
}