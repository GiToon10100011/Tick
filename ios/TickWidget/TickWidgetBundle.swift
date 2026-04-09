//
//  TickWidgetBundle.swift
//  TickWidget
//
//  Created by 전진우 on 4/9/26.
//

import WidgetKit
import SwiftUI

@main
struct TickWidgetBundle: WidgetBundle {
    var body: some Widget {
        TickWidget()
        TickWidgetControl()
        TickWidgetLiveActivity()
    }
}
