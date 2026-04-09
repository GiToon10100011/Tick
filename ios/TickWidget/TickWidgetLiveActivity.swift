//
//  TickWidgetLiveActivity.swift
//  TickWidget
//
//  Created by 전진우 on 4/9/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TickWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TickWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TickWidgetAttributes.self) { context in
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

extension TickWidgetAttributes {
    fileprivate static var preview: TickWidgetAttributes {
        TickWidgetAttributes(name: "World")
    }
}

extension TickWidgetAttributes.ContentState {
    fileprivate static var smiley: TickWidgetAttributes.ContentState {
        TickWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TickWidgetAttributes.ContentState {
         TickWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TickWidgetAttributes.preview) {
   TickWidgetLiveActivity()
} contentStates: {
    TickWidgetAttributes.ContentState.smiley
    TickWidgetAttributes.ContentState.starEyes
}
