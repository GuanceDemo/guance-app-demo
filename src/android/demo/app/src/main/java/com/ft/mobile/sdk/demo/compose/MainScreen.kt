package com.ft.mobile.sdk.demo.compose

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.Checkbox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.ft.mobile.sdk.demo.R
import com.ft.sdk.FTRUMGlobalManager
import com.ft.sdk.sessionreplay.ImagePrivacy
import com.ft.sdk.sessionreplay.TextAndInputPrivacy
import com.ft.sdk.sessionreplay.TouchPrivacy
import com.ft.sdk.sessionreplay.compose.sessionReplayHide
import com.ft.sdk.sessionreplay.compose.sessionReplayImagePrivacy
import com.ft.sdk.sessionreplay.compose.sessionReplayTextAndInputPrivacy
import com.ft.sdk.sessionreplay.compose.sessionReplayTouchPrivacy

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen() {
    val navController = rememberNavController()
    LaunchedEffect(navController) {
        var previousRoute: String? = null

        navController.currentBackStackEntryFlow.collect { backStackEntry ->
            val currentRoute = backStackEntry.destination.route
            if (previousRoute != null) {
                FTRUMGlobalManager.get().stopView()
            }
            FTRUMGlobalManager.get().startView("$currentRoute")
            previousRoute = currentRoute
        }
    }

    MaterialTheme {
        Surface(color = Color(0xFFF6F8FA)) {
            Scaffold(
                topBar = {
                    TopAppBar(title = { Text("Compose Session Replay") })
                }
            ) { paddingValues ->
                NavHost(
                    navController = navController,
                    startDestination = "home",
                    modifier = Modifier.padding(paddingValues)
                ) {
                    composable("home") { HomeScreen(navController) }
                    composable("details") { DetailScreen(navController) }
                }
            }
        }
    }
}

@Composable
fun HomeScreen(navController: NavHostController) {
    var maskedInput by remember { mutableStateOf("13800138000") }
    var visibleInput by remember { mutableStateOf("compose-demo@example.com") }
    var sliderValue by remember { mutableStateOf(0.35f) }
    var switchChecked by remember { mutableStateOf(true) }
    var checkboxChecked by remember { mutableStateOf(false) }
    var selectedTab by remember { mutableStateOf(0) }
    var showSecret by remember { mutableStateOf(true) }
    val feedItems = remember {
        mutableStateListOf(
            "Text and container capture",
            "Masked input semantics",
            "Image privacy override",
            "Touch privacy override"
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        HeaderPanel()
        Spacer(modifier = Modifier.height(16.dp))
        PrivacyPanel(
            maskedInput = maskedInput,
            onMaskedInputChange = { maskedInput = it },
            visibleInput = visibleInput,
            onVisibleInputChange = { visibleInput = it },
            showSecret = showSecret,
            onShowSecretChange = { showSecret = it }
        )
        Spacer(modifier = Modifier.height(16.dp))
        TabsPanel(selectedTab = selectedTab, onSelectedTabChange = { selectedTab = it })
        Spacer(modifier = Modifier.height(16.dp))
        ControlsPanel(
            sliderValue = sliderValue,
            onSliderChange = { sliderValue = it },
            switchChecked = switchChecked,
            onSwitchChange = { switchChecked = it },
            checkboxChecked = checkboxChecked,
            onCheckboxChange = { checkboxChecked = it }
        )
        Spacer(modifier = Modifier.height(16.dp))
        ImageAndHiddenPanel(showSecret = showSecret)
        Spacer(modifier = Modifier.height(16.dp))
        ListPanel(
            feedItems = feedItems,
            onAddItem = {
                feedItems.add("Dynamic compose item ${feedItems.size + 1}")
                FTRUMGlobalManager.get().startAction("Add Compose List Item", "click")
            }
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = trackClick(actionName = "Compose Detail") {
                navController.navigate("details")
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Open detail screen")
        }
    }
}

@Composable
fun DetailScreen(navController: NavHostController) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = "Detail Screen", style = MaterialTheme.typography.titleLarge)
        Text(
            text = "A second Compose view for RUM navigation and replay validation.",
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(top = 8.dp, bottom = 16.dp)
        )
        Button(onClick = trackClick(actionName = "Compose Back") { navController.popBackStack() }) {
            Text("Go Back")
        }
    }
}

@Composable
private fun HeaderPanel() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(160.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(Color(0xFF224B5F))
            .padding(20.dp)
            .sessionReplayTouchPrivacy(TouchPrivacy.SHOW)
    ) {
        Column(modifier = Modifier.align(Alignment.BottomStart)) {
            Text(
                text = "Session Replay Compose",
                style = MaterialTheme.typography.headlineSmall,
                color = Color.White
            )
            Text(
                text = "0.1.3 component and privacy modifier showcase",
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFFE6EEF3)
            )
        }
    }
}

@Composable
private fun PrivacyPanel(
    maskedInput: String,
    onMaskedInputChange: (String) -> Unit,
    visibleInput: String,
    onVisibleInputChange: (String) -> Unit,
    showSecret: Boolean,
    onShowSecretChange: (Boolean) -> Unit
) {
    DemoCard(title = "Privacy overrides") {
        OutlinedTextField(
            value = maskedInput,
            onValueChange = onMaskedInputChange,
            label = { Text("Mask all text") },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
            modifier = Modifier
                .fillMaxWidth()
                .sessionReplayTextAndInputPrivacy(TextAndInputPrivacy.MASK_ALL)
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = visibleInput,
            onValueChange = onVisibleInputChange,
            label = { Text("Mask input only") },
            modifier = Modifier
                .fillMaxWidth()
                .sessionReplayTextAndInputPrivacy(TextAndInputPrivacy.MASK_ALL_INPUTS)
        )
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Show red VIP badge")
            Switch(checked = showSecret, onCheckedChange = onShowSecretChange)
        }
    }
}

@Composable
private fun TabsPanel(selectedTab: Int, onSelectedTabChange: (Int) -> Unit) {
    DemoCard(title = "Tabs") {
        TabRow(selectedTabIndex = selectedTab) {
            listOf<String>("Text", "Inputs", "Touch").forEachIndexed { index: Int, title: String ->
                Tab(
                    selected = selectedTab == index,
                    onClick = {
                        onSelectedTabChange(index)
                        FTRUMGlobalManager.get().startAction("Compose Tab $title", "click")
                    },
                    text = { Text(title) }
                )
            }
        }
        Text(
            text = "Selected tab: ${selectedTab + 1}",
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(top = 12.dp)
        )
    }
}

@Composable
private fun ControlsPanel(
    sliderValue: Float,
    onSliderChange: (Float) -> Unit,
    switchChecked: Boolean,
    onSwitchChange: (Boolean) -> Unit,
    checkboxChecked: Boolean,
    onCheckboxChange: (Boolean) -> Unit
) {
    DemoCard(title = "Controls") {
        Text("Slider ${(sliderValue * 100).toInt()}%")
        Slider(
            value = sliderValue,
            onValueChange = onSliderChange,
            modifier = Modifier.sessionReplayTouchPrivacy(TouchPrivacy.SHOW)
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(checked = checkboxChecked, onCheckedChange = onCheckboxChange)
            Text("Checkbox")
            Spacer(modifier = Modifier.size(16.dp))
            Switch(checked = switchChecked, onCheckedChange = onSwitchChange)
            Text("Switch", modifier = Modifier.padding(start = 8.dp))
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            RadioButton(selected = switchChecked, onClick = { onSwitchChange(true) })
            Text("Primary")
            Spacer(modifier = Modifier.size(12.dp))
            RadioButton(selected = !switchChecked, onClick = { onSwitchChange(false) })
            Text("Secondary")
        }
    }
}

@Composable
private fun ImageAndHiddenPanel(showSecret: Boolean) {
    DemoCard(title = "Images and hidden nodes") {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Image(
                painter = painterResource(id = R.mipmap.ic_launcher_foreground),
                contentDescription = "Compose test image",
                modifier = Modifier
                    .size(72.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color(0xFFDCEBFF))
                    .padding(8.dp)
                    .sessionReplayImagePrivacy(ImagePrivacy.MASK_NONE)
            )
            Spacer(modifier = Modifier.size(16.dp))
            Column {
                Text("Launcher asset")
                Text(
                    text = "Image privacy override with clipping",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFF5F6870)
                )
            }
        }
        Spacer(modifier = Modifier.height(12.dp))
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(Color(0xFFC5392F))
                .sessionReplayHide(!showSecret),
            contentAlignment = Alignment.Center
        ) {
            Text("VIP", color = Color.White)
        }
    }
}

@Composable
private fun ListPanel(feedItems: List<String>, onAddItem: () -> Unit) {
    DemoCard(title = "Lazy list capture") {
        Button(onClick = onAddItem, modifier = Modifier.fillMaxWidth()) {
            Text("Add list item")
        }
        Spacer(modifier = Modifier.height(12.dp))
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .height(220.dp)
        ) {
            items(items = feedItems) { item: String ->
                FeedRow(item = item)
            }
        }
    }
}

@Composable
private fun DemoCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = title, style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(12.dp))
            content()
        }
    }
}

@Composable
private fun FeedRow(item: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(Color(0xFFEFF4F7))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(Color(0xFF224B5F)),
            contentAlignment = Alignment.Center
        ) {
            Text(text = item.take(1), color = Color.White)
        }
        Spacer(modifier = Modifier.size(12.dp))
        Column {
            Text(item)
            Text(
                text = "Compose row for replay verification",
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFF5F6870)
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
fun DefaultPreview() {
    MainScreen()
}

fun trackClick(actionName: String, onClick: () -> Unit): () -> Unit {
    return {
        FTRUMGlobalManager.get().startAction(actionName, "click")
        onClick()
    }
}
