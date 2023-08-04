//
//  Guance.swift
//  Guance
//
//  Created by hulilei on 2023/7/20.
//

import WidgetKit
import SwiftUI
import FTMobileSDK
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        Task(priority: .medium) {
            await  ModelData.shared.getUserInfo()
        }
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct GuanceEntryView : View {

    var entry: Provider.Entry
    @State var userInfo:UserInfo =  ModelData.shared.userInfo

    
    init(entry: Provider.Entry, userInfo: UserInfo = ModelData.shared.userInfo){
        self.entry = entry
        self.userInfo = userInfo
        FTExternalDataManager.shared().startView(withName: "GuanceEntryView")
    }
    var body: some View {
        VStack {
            Text(entry.date, style: .time)
            HStack{
                Image(systemName: "person")
                Text(":\(userInfo.username)")
            }
            HStack{
                Image(systemName: "envelope")
                Text(":\(userInfo.email)")

            }
        }
    }
}

struct Guance: Widget {

    let kind: String = "Guance"
    init() {
        let extensionConfig = FTExtensionConfig.init(groupIdentifier: GroupIdentifier)
        extensionConfig.enableTrackAppCrash = true
        extensionConfig.enableRUMAutoTraceResource = true
        extensionConfig.enableTracerAutoTrace = true
        extensionConfig.enableSDKDebugLog = true
        FTExtensionManager.start(with: extensionConfig)
    }
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GuanceEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct Guance_Previews: PreviewProvider {
    static var previews: some View {
        GuanceEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            
    }
}
