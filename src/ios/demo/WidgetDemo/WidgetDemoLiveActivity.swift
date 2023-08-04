//
//  WidgetDemoLiveActivity.swift
//  WidgetDemo
//
//  Created by hulilei on 2023/7/20.
//

import ActivityKit
import WidgetKit
import SwiftUI
import FTMobileSDK
struct WidgetDemoAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WidgetDemoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WidgetDemoAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WidgetDemoAttributes {
    fileprivate static var preview: WidgetDemoAttributes {
        WidgetDemoAttributes(name: "World")
    }
}

extension WidgetDemoAttributes.ContentState {
    fileprivate static var smiley: WidgetDemoAttributes.ContentState {
        WidgetDemoAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WidgetDemoAttributes.ContentState {
         WidgetDemoAttributes.ContentState(emoji: "🤩")
     }
}


