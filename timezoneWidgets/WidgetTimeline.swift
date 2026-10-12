//
//  WidgetTimeline.swift
//  timezoneWidgets
//

import SwiftUI
import WidgetKit

struct WidgetCity: Identifiable, Hashable {
    let name: String
    let zone: String
    let colorIndex: Int

    var id: String { "\(zone)|\(name)" }
    var color: Color { COLORS[colorIndex % COLORS.count] }
}

struct SunEntry: TimelineEntry {
    let date: Date
    let cities: [WidgetCity]
    let offsetHours: Int

    // The moment the widget depicts, which differs from `date` while scrubbed
    var shownDate: Date { date.addingTimeInterval(Double(offsetHours) * 3600) }
}

struct CityTimelineProvider<Intent: CityListIntent>: AppIntentTimelineProvider {
    // Only widgets that carry the scrub buttons follow the shared offset
    var scrubbable = false

    func placeholder(in context: Context) -> SunEntry {
        SunEntry(date: Date(), cities: cities(for: []), offsetHours: 0)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> SunEntry {
        SunEntry(date: Date(), cities: cities(for: configuration.chosenCities), offsetHours: 0)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<SunEntry> {
        let cities = cities(for: configuration.chosenCities)
        let scrub = scrubbable ? TimezoneStore.scrub() : nil
        let now = Date()

        // One entry per minute so the clocks stay exact
        var dates = [now]
        let firstMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(60)
        dates += (0..<60).map { firstMinute.addingTimeInterval(Double($0) * 60) }
        if let scrub {
            dates.append(scrub.expiry)
            dates.sort()
        }

        let entries = dates.map { date in
            let hours = scrub.map { date < $0.expiry ? $0.hours : 0 } ?? 0
            return SunEntry(date: date, cities: cities, offsetHours: hours)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func cities(for chosen: [CityEntity]) -> [WidgetCity] {
        if chosen.isEmpty {
            return TimezoneStore.load().map { WidgetCity(name: $0.name, zone: $0.zone, colorIndex: $0.colorIndex) }
        }
        return chosen.enumerated().map { index, city in
            WidgetCity(name: city.name, zone: city.zone, colorIndex: index)
        }
    }
}

func daySymbol(forHours hours: CGFloat) -> String {
    switch hours {
    case 5.5..<6.5: "sunrise.fill"
    case 6.5..<17.5: "sun.max.fill"
    case 17.5..<18.5: "sunset.fill"
    default: "moon.fill"
    }
}
