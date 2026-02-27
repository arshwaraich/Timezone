//
//  Models.swift
//  timezone
//

import SwiftUI

struct SavedTimezone: Codable {
    let name: String
    let zone: String
    let colorIndex: Int
}

struct TimezoneEntry: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let zone: String
    let color: Color
    let colorIndex: Int
}

struct TimezoneData {
    let time: String
    let date: String
    let positionX: CGFloat
    let positionY: CGFloat
    let hours: CGFloat
}

struct Star: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
}

struct TimezonePickerItem: Identifiable {
    let id: String  // unique key for the list
    let displayName: String
    let identifier: String
    let isAlias: Bool

    var region: String { regionPath(for: identifier) }
}
