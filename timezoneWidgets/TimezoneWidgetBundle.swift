//
//  TimezoneWidgetBundle.swift
//  timezoneWidgets
//

import SwiftUI
import WidgetKit

@main
struct TimezoneWidgetBundle: WidgetBundle {
    var body: some Widget {
        SunArcWidget()
        #if os(iOS)
        CityTimesWidget()
        CityClockWidget()
        #endif
    }
}
