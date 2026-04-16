package com.ft.mobile.sdk.demo

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.ft.mobile.sdk.demo.http.OkHttpClientInstance
import com.ft.mobile.sdk.demo.manager.AccountManager
import com.ft.mobile.sdk.demo.manager.SettingConfigManager
import com.google.android.material.button.MaterialButton
import com.squareup.picasso.Picasso
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject

@DelicateCoroutinesApi
class RealScenarioDetailActivity : BaseActivity() {

    private lateinit var productId: String
    private lateinit var imageView: ImageView
    private lateinit var titleView: TextView
    private lateinit var priceView: TextView
    private lateinit var subtitleView: TextView
    private lateinit var descriptionView: TextView
    private lateinit var highlightsView: TextView
    private lateinit var specsView: TextView
    private lateinit var statusView: TextView
    private lateinit var loadingView: View
    private lateinit var contentView: View

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_real_scenario_detail)

        val toolbar: androidx.appcompat.widget.Toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        setupToolbar(toolbar)

        productId = intent.getStringExtra(EXTRA_PRODUCT_ID).orEmpty()
        imageView = findViewById(R.id.story_image)
        titleView = findViewById(R.id.story_title)
        priceView = findViewById(R.id.story_price)
        subtitleView = findViewById(R.id.story_summary)
        descriptionView = findViewById(R.id.story_content)
        highlightsView = findViewById(R.id.story_highlights)
        specsView = findViewById(R.id.story_specs)
        statusView = findViewById(R.id.story_status)
        loadingView = findViewById(R.id.story_loading)
        contentView = findViewById(R.id.story_content_group)

        bindActions()
        loadProductDetail()
    }

    private fun bindActions() {
        findViewById<MaterialButton>(R.id.story_open_webview).setOnClickListener {
            startActivity(
                WebViewActivity.newIntent(
                    this,
                    getString(R.string.product_webview_title),
                    buildProductUrl(productId)
                )
            )
        }
    }

    private fun loadProductDetail() {
        loadingView.visibility = View.VISIBLE
        contentView.visibility = View.GONE

        GlobalScope.launch(Dispatchers.IO) {
            val result = runCatching {
                val setting = SettingConfigManager.readSetting(this@RealScenarioDetailActivity)
                val request = Request.Builder()
                    .url("${setting.demoApiAddress}/api/products/$productId")
                    .build()
                OkHttpClientInstance.get().newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        error("HTTP ${response.code}")
                    }
                    parseProductDetail(JSONObject(response.body?.string().orEmpty()), setting.demoApiAddress)
                }
            }

            withContext(Dispatchers.Main) {
                loadingView.visibility = View.GONE
                result.onSuccess { detail ->
                    title = detail.title
                    bindDetail(detail)
                    contentView.visibility = View.VISIBLE
                }.onFailure {
                    contentView.visibility = View.VISIBLE
                    titleView.text = getString(R.string.real_scenario_load_failed, it.message ?: "unknown")
                }
            }
        }
    }

    private fun bindDetail(detail: ProductDetail) {
        Picasso.get()
            .load(detail.imageUrl)
            .placeholder(R.drawable.ic_android)
            .error(R.drawable.ic_android)
            .fit()
            .centerCrop()
            .into(imageView)
        titleView.text = detail.title
        priceView.text = detail.price
        subtitleView.text = detail.subtitle
        descriptionView.text = detail.description
        highlightsView.text = detail.highlights.joinToString(prefix = "Highlights: ", separator = " · ")
        specsView.text = detail.specs.entries.joinToString(
            prefix = getString(R.string.product_specs_prefix),
            separator = "\n"
        ) { "${it.key}: ${it.value}" }
        statusView.text = getString(
            R.string.product_status_format,
            AccountManager.userData?.username ?: getString(R.string.default_username),
            detail.rating,
            detail.stock
        )
    }

    private fun parseProductDetail(json: JSONObject, demoApiAddress: String): ProductDetail {
        val highlightsArray = json.optJSONArray("highlights") ?: JSONArray()
        val specsJson = json.optJSONObject("specs") ?: JSONObject()
        val highlights = mutableListOf<String>()
        val specs = linkedMapOf<String, String>()

        for (index in 0 until highlightsArray.length()) {
            highlights.add(highlightsArray.optString(index))
        }

        specsJson.keys().forEach { key ->
            specs[key] = specsJson.optString(key)
        }

        return ProductDetail(
            id = json.optString("id"),
            title = json.optString("title"),
            subtitle = json.optString("subtitle"),
            imageUrl = resolveImageUrl(demoApiAddress, json.optString("image_url")),
            price = json.optString("price"),
            rating = json.optString("rating"),
            stock = json.optString("stock"),
            description = json.optString("description"),
            highlights = highlights,
            specs = specs
        )
    }

    private fun resolveImageUrl(demoApiAddress: String, imageUrl: String): String {
        if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
            return imageUrl
        }
        return "${demoApiAddress.trimEnd('/')}/${imageUrl.trimStart('/')}"
    }

    private fun buildProductUrl(productId: String): String {
        val setting = SettingConfigManager.readSetting(this)
        return "${setting.demoApiAddress}/product/$productId"
    }

    companion object {
        private const val EXTRA_PRODUCT_ID = "product_id"

        fun newIntent(context: Context, productId: String): Intent {
            return Intent(context, RealScenarioDetailActivity::class.java).putExtra(
                EXTRA_PRODUCT_ID,
                productId
            )
        }
    }
}

data class ProductDetail(
    val id: String,
    val title: String,
    val subtitle: String,
    val imageUrl: String,
    val price: String,
    val rating: String,
    val stock: String,
    val description: String,
    val highlights: List<String>,
    val specs: Map<String, String>
)
