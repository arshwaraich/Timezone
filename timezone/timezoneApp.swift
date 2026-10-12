//
//  timezoneApp.swift
//  timezone
//
//  Created by Arsh Waraich on 2026-02-24.
//

import SwiftUI

@main
struct timezoneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 640, minHeight: 480)
                .preferredColorScheme(.dark)
                .containerBackground(Color(red: 0.035, green: 0.035, blue: 0.043), for: .window)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1040, height: 640)
        .commands {
            TimezoneCommands()
        }
        #endif
    }
}
