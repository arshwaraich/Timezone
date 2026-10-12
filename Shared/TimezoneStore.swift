//
//  TimezoneStore.swift
//  timezone
//

import Foundation

// Persistence shared by the app and its widgets through the App Group container.
enum TimezoneStore {
    static let appGroup = "group.com.arshwaraich.timezone"

    private static let savedKey = "savedTimezones"
    private static let scrubHoursKey = "scrubOffsetHours"
    private static let scrubExpiryKey = "scrubOffsetExpiry"

    static let defaultTimezones = [
        SavedTimezone(name: "Toronto", zone: "America/Toronto", colorIndex: 0),
        SavedTimezone(name: "New Delhi", zone: "Asia/Kolkata", colorIndex: 1),
    ]

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func load() -> [SavedTimezone] {
        migrateIfNeeded()
        guard let data = defaults.data(forKey: savedKey),
              let saved = try? JSONDecoder().decode([SavedTimezone].self, from: data),
              !saved.isEmpty else {
            return defaultTimezones
        }
        return saved
    }

    static func save(_ timezones: [SavedTimezone]) {
        if let data = try? JSONEncoder().encode(timezones) {
            defaults.set(data, forKey: savedKey)
        }
    }

    // Versions before widgets kept the list in the app's own defaults
    private static func migrateIfNeeded() {
        guard defaults.data(forKey: savedKey) == nil,
              let legacy = UserDefaults.standard.data(forKey: savedKey) else { return }
        defaults.set(legacy, forKey: savedKey)
    }

    // MARK: - Widget time scrubbing

    // Hours the widgets are shifted by, and when that shift lapses back to live time
    static func scrub() -> (hours: Int, expiry: Date)? {
        guard let expiry = defaults.object(forKey: scrubExpiryKey) as? Date, expiry > Date() else { return nil }
        let hours = defaults.integer(forKey: scrubHoursKey)
        return hours == 0 ? nil : (hours, expiry)
    }

    static func setScrub(hours: Int, expiry: Date) {
        defaults.set(hours, forKey: scrubHoursKey)
        defaults.set(expiry, forKey: scrubExpiryKey)
    }

    static func clearScrub() {
        defaults.removeObject(forKey: scrubHoursKey)
        defaults.removeObject(forKey: scrubExpiryKey)
    }
}
