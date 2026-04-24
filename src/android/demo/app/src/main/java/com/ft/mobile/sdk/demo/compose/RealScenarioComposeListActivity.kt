package com.ft.mobile.sdk.demo.compose

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ft.mobile.sdk.demo.R
import com.ft.mobile.sdk.demo.ProductDetail
import com.ft.mobile.sdk.demo.WebViewActivity
import com.ft.mobile.sdk.demo.data.ProductItem
import com.ft.mobile.sdk.demo.http.OkHttpClientInstance
import com.ft.mobile.sdk.demo.manager.AccountManager
import com.ft.mobile.sdk.demo.manager.SettingConfigManager
import com.ft.sdk.FTRUMGlobalManager
import com.ft.sdk.sessionreplay.ImagePrivacy
import com.ft.sdk.sessionreplay.compose.sessionReplayImagePrivacy
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject

class RealScenarioComposeListActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                RealScenarioComposeListScreen(
                    onBack = { finish() },
                    onOpenDetail = { productId ->
                        startActivity(RealScenarioComposeDetailActivity.newIntent(this, productId))
                    }
                )
            }
        }
    }
}

class RealScenarioComposeDetailActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val productId = intent.getStringExtra(EXTRA_PRODUCT_ID).orEmpty()
        setContent {
            MaterialTheme {
                RealScenarioComposeDetailScreen(
                    productId = productId,
                    onBack = { finish() }
                )
            }
        }
    }

    companion object {
        private const val EXTRA_PRODUCT_ID = "product_id"

        fun newIntent(context: Context, productId: String): Intent {
            return Intent(context, RealScenarioComposeDetailActivity::class.java).putExtra(
                EXTRA_PRODUCT_ID,
                productId
            )
        }
    }
}

@Composable
private fun RealScenarioComposeListScreen(
    onBack: () -> Unit,
    onOpenDetail: (String) -> Unit
) {
    val context = LocalContext.current
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var products by remember { mutableStateOf<List<ProductItem>>(emptyList()) }
    var reloadKey by remember { mutableStateOf(0) }

    LaunchedEffect(reloadKey) {
        isLoading = true
        errorMessage = null
        runCatching { loadComposeProducts(context) }
            .onSuccess { products = it }
            .onFailure { errorMessage = context.getString(R.string.real_scenario_load_failed, it.message ?: "unknown") }
        isLoading = false
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        ComposeToolbar(
            title = stringResource(R.string.real_scenario_entry_title),
            onBack = onBack,
            actionText = "R",
            onAction = {
                FTRUMGlobalManager.get().startAction("compose_product_feed_refresh", "click")
                reloadKey += 1
            }
        )
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            item {
                Text(
                    text = stringResource(R.string.product_feed_intro),
                    color = Color(0xFF666666),
                    fontSize = 14.sp,
                    lineHeight = 18.sp,
                    modifier = Modifier.padding(start = 10.dp, top = 14.dp, end = 10.dp, bottom = 12.dp)
                )
            }
            when {
                isLoading -> item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(180.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = Color(0xFFFF6600))
                    }
                }
                errorMessage != null -> item {
                    EmptyState(message = errorMessage.orEmpty()) {
                        reloadKey += 1
                    }
                }
                products.isEmpty() -> item {
                    EmptyState(message = stringResource(R.string.real_scenario_empty_text)) {
                        reloadKey += 1
                    }
                }
                else -> items(items = products, key = { it.id }) { item ->
                    ComposeProductRow(
                        item = item,
                        onClick = {
                            FTRUMGlobalManager.get().startAction("compose_product_open_detail", "click")
                            onOpenDetail(item.id)
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun ComposeProductRow(item: ProductItem, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(start = 20.dp, top = 18.dp, end = 20.dp, bottom = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        NetworkImage(
            imageUrl = item.imageUrl,
            modifier = Modifier
                .size(width = 102.dp, height = 70.dp)
                .sessionReplayImagePrivacy(ImagePrivacy.MASK_NONE)
        )
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(start = 12.dp)
        ) {
            Text(
                text = item.tag,
                color = Color(0xFF1C5D99),
                fontSize = 11.sp,
                modifier = Modifier
                    .background(Color(0xFFE8F1FF))
                    .padding(horizontal = 6.dp, vertical = 4.dp)
            )
            Text(
                text = item.title,
                color = Color.Black,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 8.dp)
            )
            Text(
                text = item.subtitle,
                color = Color(0xFF555555),
                fontSize = 12.sp,
                lineHeight = 15.sp,
                modifier = Modifier.padding(top = 5.dp)
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 10.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = item.price,
                    color = Color(0xFFCC4E00),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = item.rating,
                    color = Color(0xFF0A4F8A),
                    fontSize = 12.sp
                )
            }
        }
    }
}

@Composable
private fun RealScenarioComposeDetailScreen(productId: String, onBack: () -> Unit) {
    val context = LocalContext.current
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var detail by remember { mutableStateOf<ProductDetail?>(null) }

    LaunchedEffect(productId) {
        isLoading = true
        errorMessage = null
        runCatching { loadComposeProductDetail(context, productId) }
            .onSuccess { detail = it }
            .onFailure { errorMessage = context.getString(R.string.real_scenario_load_failed, it.message ?: "unknown") }
        isLoading = false
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        ComposeToolbar(
            title = detail?.title ?: stringResource(R.string.real_scenario_entry_title),
            onBack = onBack
        )
        when {
            isLoading -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Color(0xFFFF6600))
            }
            errorMessage != null -> EmptyState(message = errorMessage.orEmpty(), onRetry = onBack)
            detail != null -> ComposeProductDetailContent(detail = detail!!)
        }
    }
}

@OptIn(DelicateCoroutinesApi::class)
@Composable
private fun ComposeProductDetailContent(detail: ProductDetail) {
    val context = LocalContext.current
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        content = {
            item {
                NetworkImage(
                    imageUrl = detail.imageUrl,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(240.dp)
                        .sessionReplayImagePrivacy(ImagePrivacy.MASK_NONE)
                )
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = stringResource(
                            R.string.product_status_format,
                            AccountManager.userData?.username ?: stringResource(R.string.default_username),
                            detail.rating,
                            detail.stock
                        ),
                        color = Color(0xFF1C5D99),
                        fontSize = 12.sp,
                        modifier = Modifier
                            .background(Color(0xFFE8F1FF))
                            .padding(horizontal = 12.dp, vertical = 8.dp)
                    )
                    Text(
                        text = detail.title,
                        color = Color(0xFF111111),
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(top = 14.dp)
                    )
                    Text(
                        text = detail.price,
                        color = Color(0xFFCC4E00),
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                    Text(
                        text = detail.subtitle,
                        color = Color(0xFF555555),
                        fontSize = 15.sp,
                        lineHeight = 20.sp,
                        modifier = Modifier.padding(top = 10.dp)
                    )
                    InfoBlock(
                        text = detail.highlights.joinToString(prefix = "Highlights: ", separator = " · "),
                        background = Color(0xFFF4F7FB)
                    )
                    InfoBlock(
                        text = detail.specs.entries.joinToString(
                            prefix = stringResource(R.string.product_specs_prefix),
                            separator = "\n"
                        ) { "${it.key}: ${it.value}" },
                        background = Color(0xFFF8F8F8)
                    )
                    Text(
                        text = detail.description,
                        color = Color(0xFF444444),
                        fontSize = 15.sp,
                        lineHeight = 22.sp,
                        modifier = Modifier.padding(top = 16.dp)
                    )
                    Button(
                        onClick = {
                            FTRUMGlobalManager.get().startAction("compose_product_open_webview", "click")
                            context.startActivity(
                                WebViewActivity.newIntent(
                                    context,
                                    context.getString(R.string.product_webview_title),
                                    buildComposeProductUrl(context, detail.id)
                                )
                            )
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF6600)),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 20.dp, bottom = 18.dp)
                    ) {
                        Text(stringResource(R.string.product_open_webview))
                    }
                }
            }
        }
    )
}

@Composable
private fun InfoBlock(text: String, background: Color) {
    Text(
        text = text,
        color = Color(0xFF333333),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 14.dp)
            .background(background)
            .padding(12.dp)
    )
}

@Composable
private fun ComposeToolbar(
    title: String,
    onBack: () -> Unit,
    actionText: String? = null,
    onAction: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            // FIXME: Work around Compose Session Replay missing colors for background-only
            // layout nodes. Remove this once the SDK captures non-semantic container backgrounds.
            .semantics { }
            .background(Color(0xFFFF6600))
            .padding(horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "<",
            color = Color.White,
            fontSize = 34.sp,
            modifier = Modifier
                .size(48.dp)
                .clickable(onClick = onBack)
                .padding(start = 8.dp)
        )
        Text(
            text = title,
            color = Color.White,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            maxLines = 1,
            modifier = Modifier.weight(1f)
        )
        if (actionText != null && onAction != null) {
            Text(
                text = actionText,
                color = Color.White,
                fontSize = 24.sp,
                modifier = Modifier
                    .size(48.dp)
                    .clickable(onClick = onAction)
                    .padding(top = 8.dp, start = 12.dp)
            )
        } else {
            Spacer(modifier = Modifier.size(48.dp))
        }
    }
}

@Composable
private fun NetworkImage(imageUrl: String, modifier: Modifier = Modifier) {
    var imageBitmap by remember(imageUrl) { mutableStateOf<ImageBitmap?>(null) }

    LaunchedEffect(imageUrl) {
        imageBitmap = runCatching { loadComposeImageBitmap(imageUrl) }.getOrNull()
    }

    Box(
        modifier = modifier.background(Color(0xFFE9EEF5)),
        contentAlignment = Alignment.Center
    ) {
        val bitmap = imageBitmap
        if (bitmap != null) {
            Image(
                bitmap = bitmap,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        } else {
            Text(
                text = stringResource(R.string.app_name),
                color = Color(0xFF7890A6),
                fontSize = 11.sp
            )
        }
    }
}

@Composable
private fun EmptyState(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = message, color = Color(0xFF666666), fontSize = 14.sp)
        Button(
            onClick = onRetry,
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF6600)),
            modifier = Modifier.padding(top = 16.dp)
        ) {
            Text("OK")
        }
    }
}

private suspend fun loadComposeProducts(context: Context): List<ProductItem> = withContext(Dispatchers.IO) {
    val setting = SettingConfigManager.readSetting(context)
    val request = Request.Builder()
        .url("${setting.demoApiAddress}/api/products")
        .build()
    OkHttpClientInstance.get().newCall(request).execute().use { response ->
        if (!response.isSuccessful) {
            error("HTTP ${response.code}")
        }
        parseProductList(JSONArray(response.body?.string().orEmpty()), setting.demoApiAddress)
    }
}

private suspend fun loadComposeProductDetail(context: Context, productId: String): ProductDetail =
    withContext(Dispatchers.IO) {
        val setting = SettingConfigManager.readSetting(context)
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

private fun parseProductList(array: JSONArray, demoApiAddress: String): List<ProductItem> {
    val result = mutableListOf<ProductItem>()
    for (index in 0 until array.length()) {
        val item = array.getJSONObject(index)
        result.add(
            ProductItem(
                id = item.optString("id"),
                title = item.optString("title"),
                subtitle = item.optString("subtitle"),
                imageUrl = resolveComposeImageUrl(demoApiAddress, item.optString("image_url")),
                price = item.optString("price"),
                rating = item.optString("rating"),
                tag = item.optString("tag")
            )
        )
    }
    return result
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
        imageUrl = resolveComposeImageUrl(demoApiAddress, json.optString("image_url")),
        price = json.optString("price"),
        rating = json.optString("rating"),
        stock = json.optString("stock"),
        description = json.optString("description"),
        highlights = highlights,
        specs = specs
    )
}

private fun buildComposeProductUrl(context: Context, productId: String): String {
    val setting = SettingConfigManager.readSetting(context)
    return "${setting.demoApiAddress}/product/$productId"
}

private suspend fun loadComposeImageBitmap(imageUrl: String): ImageBitmap = withContext(Dispatchers.IO) {
    val request = Request.Builder()
        .url(imageUrl)
        .build()
    OkHttpClientInstance.get().newCall(request).execute().use { response ->
        if (!response.isSuccessful) {
            error("HTTP ${response.code}")
        }
        val bytes = response.body?.bytes() ?: error("empty image body")
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size)?.asImageBitmap()
            ?: error("decode image failed")
    }
}

private fun resolveComposeImageUrl(demoApiAddress: String, imageUrl: String): String {
    if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
        return imageUrl
    }
    return "${demoApiAddress.trimEnd('/')}/${imageUrl.trimStart('/')}"
}
