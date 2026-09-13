package com.ft.mobile.sdk.demo.http

data class WebSocketTestEndpoints(
    val success: String,
    val rejected: String,
    val invalidUpgrade: String
)

object WebSocketTestConfig {

    private const val ECHO_PATH = "/ws/echo"
    private const val REJECT_PATH = "/ws/reject"
    private const val INVALID_UPGRADE_PATH = "/ws/invalid-upgrade"

    fun createEndpoints(demoApiAddress: String): WebSocketTestEndpoints {
        val baseAddress = normalizeBaseAddress(demoApiAddress)
        return WebSocketTestEndpoints(
            success = appendPath(baseAddress, ECHO_PATH),
            rejected = appendPath(baseAddress, REJECT_PATH),
            invalidUpgrade = appendPath(baseAddress, INVALID_UPGRADE_PATH)
        )
    }

    private fun normalizeBaseAddress(address: String): String {
        val baseAddress = address.trim().trimEnd('/')
        return when {
            baseAddress.startsWith("https://", ignoreCase = true) ->
                "wss://${baseAddress.substring(8)}"

            baseAddress.startsWith("http://", ignoreCase = true) ->
                "ws://${baseAddress.substring(7)}"

            else -> baseAddress
        }
    }

    private fun appendPath(baseAddress: String, path: String): String {
        return "${baseAddress.trimEnd('/')}/${path.trimStart('/')}"
    }
}
