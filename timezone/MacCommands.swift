//
//  MacCommands.swift
//  timezone
//

#if os(macOS)
import SwiftUI

// What the frontmost window exposes to the menu bar
struct TimezoneActions {
    var addCity: () -> Void
    var resetTime: () -> Void
    var isShifted: Bool
}

extension FocusedValues {
    @Entry var timezoneActions: TimezoneActions?
}

// Menu bar equivalents for everything in the toolbar
struct TimezoneCommands: Commands {
    @FocusedValue(\.timezoneActions) private var actions

    var body: some Commands {
        SidebarCommands()

        CommandGroup(replacing: .newItem) {
            Button("Add City…") { actions?.addCity() }
                .keyboardShortcut("n")
                .disabled(actions == nil)
        }

        CommandGroup(after: .toolbar) {
            Button("Return to Now") { actions?.resetTime() }
                .keyboardShortcut("0")
                .disabled(actions?.isShifted != true)
        }
    }
}
#endif
