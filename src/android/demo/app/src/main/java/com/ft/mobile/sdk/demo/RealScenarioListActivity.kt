package com.ft.mobile.sdk.demo

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ProgressBar
import android.widget.TextView
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.ft.mobile.sdk.demo.adapter.ProductAdapter
import com.ft.mobile.sdk.demo.data.ProductItem
import com.ft.mobile.sdk.demo.manager.SettingConfigManager
import com.ft.mobile.sdk.demo.http.OkHttpClientInstance
import com.ft.sdk.FTRUMGlobalManager
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.Request
import org.json.JSONArray

@DelicateCoroutinesApi
class RealScenarioListActivity : BaseActivity(), ProductAdapter.OnItemClickListener {

    private lateinit var productAdapter: ProductAdapter
    private lateinit var refreshLayout: SwipeRefreshLayout
    private lateinit var emptyView: TextView
    private lateinit var progressBar: ProgressBar
    private val products = mutableListOf<ProductItem>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = getString(R.string.real_scenario_entry_title)
        setContentView(R.layout.activity_real_scenario_list)

        val toolbar: androidx.appcompat.widget.Toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        setupToolbar(toolbar)

        val recyclerView: RecyclerView = findViewById(R.id.recyclerView)
        refreshLayout = findViewById(R.id.real_scenario_refresh_layout)
        emptyView = findViewById(R.id.real_scenario_empty)
        progressBar = findViewById(R.id.real_scenario_loading)

        productAdapter = ProductAdapter(products, this)
        recyclerView.layoutManager = LinearLayoutManager(this)
        recyclerView.adapter = productAdapter

        refreshLayout.setOnRefreshListener {
            FTRUMGlobalManager.get().startAction("product_feed_refresh", "pull_to_refresh")
            loadProducts(showLoading = false)
        }

        loadProducts(showLoading = true)
    }

    private fun loadProducts(showLoading: Boolean) {
        if (showLoading) {
            progressBar.visibility = View.VISIBLE
            emptyView.visibility = View.GONE
        }

        GlobalScope.launch(Dispatchers.IO) {
            val result = runCatching {
                val setting = SettingConfigManager.readSetting(this@RealScenarioListActivity)
                val request = Request.Builder()
                    .url("${setting.demoApiAddress}/api/products")
                    .build()
                OkHttpClientInstance.get().newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        error("HTTP ${response.code}")
                    }
                    val body = response.body?.string().orEmpty()
                    parseProductList(JSONArray(body), setting.demoApiAddress)
                }
            }

            withContext(Dispatchers.Main) {
                progressBar.visibility = View.GONE
                refreshLayout.isRefreshing = false

                result.onSuccess { items ->
                    products.clear()
                    products.addAll(items)
                    productAdapter.notifyDataSetChanged()
                    emptyView.visibility = if (items.isEmpty()) View.VISIBLE else View.GONE
                    emptyView.text = getString(R.string.real_scenario_empty_text)
                }.onFailure {
                    products.clear()
                    productAdapter.notifyDataSetChanged()
                    emptyView.visibility = View.VISIBLE
                    emptyView.text = getString(R.string.real_scenario_load_failed, it.message ?: "unknown")
                }
            }
        }
    }

    private fun parseProductList(array: JSONArray, demoApiAddress: String): List<ProductItem> {
        val result = mutableListOf<ProductItem>()
        for (index in 0 until array.length()) {
            val item = array.getJSONObject(index)
            result.add(
                ProductItem(
                    id = item.optString("id"),
                    title = item.optString("title"),
                    subtitle = item.optString("subtitle"),
                    imageUrl = resolveImageUrl(demoApiAddress, item.optString("image_url")),
                    price = item.optString("price"),
                    rating = item.optString("rating"),
                    tag = item.optString("tag")
                )
            )
        }
        return result
    }

    private fun resolveImageUrl(demoApiAddress: String, imageUrl: String): String {
        if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
            return imageUrl
        }
        return "${demoApiAddress.trimEnd('/')}/${imageUrl.trimStart('/')}"
    }

    override fun onItemClick(item: ProductItem) {
        startActivity(RealScenarioDetailActivity.newIntent(this, item.id))
    }
}
