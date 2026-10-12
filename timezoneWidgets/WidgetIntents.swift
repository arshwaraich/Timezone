//
//  WidgetIntents.swift
//  timezoneWidgets
//

import AppIntents
import WidgetKit

// MARK: - City entity

struct CityEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "City"
    static let defaultQuery = CityQuery()

    let name: String
    let zone: String

    // Aliases share a zone, so the name is part of the identity
    var id: String { "\(zone)|\(name)" }

    var displayRepresentation: DisplayRepresentation {
        guard let tz = TimeZone(identifier: zone) else { return DisplayRepresentation(title: "\(name)") }
        let subtitle = [regionPath(for: zone), formatGMTOffset(tz)].filter { !$0.isEmpty }.joined(separator: " · ")
        return DisplayRepresentation(title: "\(name)", subtitle: "\(subtitle)")
    }

    init(name: String, zone: String) {
        self.name = name
        self.zone = zone
    }

    init?(id: String) {
        let parts = id.split(separator: "|", maxSplits: 1)
        guard parts.count == 2, TimeZone(identifier: String(parts[0])) != nil else { return nil }
        self.init(name: String(parts[1]), zone: String(parts[0]))
    }
}

struct CityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [CityEntity] {
        identifiers.compactMap { CityEntity(id: $0) }
    }

    func entities(matching string: String) async throws -> [CityEntity] {
        filterPickerItems(allPickerItems(), matching: string)
            .map { CityEntity(name: $0.displayName, zone: $0.identifier) }
    }

    // The app's own cities first, then everything else
    func suggestedEntities() async throws -> [CityEntity] {
        let saved = TimezoneStore.load().map { CityEntity(name: $0.name, zone: $0.zone) }
        let savedIDs = Set(saved.map(\.id))
        let rest = allPickerItems()
            .map { CityEntity(name: $0.displayName, zone: $0.identifier) }
            .filter { !savedIDs.contains($0.id) }
        return saved + rest
    }
}

// MARK: - Widget configuration

protocol CityListIntent: WidgetConfigurationIntent {
    var chosenCities: [CityEntity] { get }
}

struct CitiesConfigIntent: CityListIntent {
    static let title: LocalizedStringResource = "Cities"
    static let description = IntentDescription("Choose the cities to show. Leave empty to follow the list in the app.")

    @Parameter(title: "Cities")
    var cities: [CityEntity]?

    var chosenCities: [CityEntity] { cities ?? [] }
}

struct CityConfigIntent: CityListIntent {
    static let title: LocalizedStringResource = "City"
    static let description = IntentDescription("Choose the city to show. Leave empty to use the first city in the app.")

    @Parameter(title: "City")
    var city: CityEntity?

    var chosenCities: [CityEntity] { city.map { [$0] } ?? [] }
}

// MARK: - Time scrubbing

struct ShiftTimeIntent: AppIntent {
    static let title: LocalizedStringResource = "Shift Time"
    static let isDiscoverable = false

    // A shifted widget drifts back to live time after this long untouched
    static let holdDuration: TimeInterval = 15 * 60

    @Parameter(title: "Hours")
    var hours: Int

    init() {}

    init(hours: Int) {
        self.hours = hours
    }

    func perform() async throws -> some IntentResult {
        let shifted = (TimezoneStore.scrub()?.hours ?? 0) + hours
        if shifted == 0 {
            TimezoneStore.clearScrub()
        } else {
            TimezoneStore.setScrub(hours: shifted, expiry: Date().addingTimeInterval(Self.holdDuration))
        }
        WidgetCenter.shared.reloadTimelines(ofKind: SunArcWidget.kind)
        return .result()
    }
}

struct ResetTimeIntent: AppIntent {
    static let title: LocalizedStringResource = "Reset Time"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        TimezoneStore.clearScrub()
        WidgetCenter.shared.reloadTimelines(ofKind: SunArcWidget.kind)
        return .result()
    }
}
