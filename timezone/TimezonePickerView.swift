import SwiftUI

struct TimezonePickerView: View {
    let existingTimezones: [TimezoneEntry]
    let onAdd: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var pickerItems: [TimezonePickerItem] {
        var items: [TimezonePickerItem] = TimeZone.knownTimeZoneIdentifiers
            .filter { $0.contains("/") }
            .map { TimezonePickerItem(id: $0, displayName: displayName(for: $0), identifier: $0, isAlias: false) }

        for (alias, identifier) in CITY_ALIASES {
            if !items.contains(where: { $0.displayName == alias }) {
                items.append(TimezonePickerItem(id: "alias:\(alias)", displayName: alias, identifier: identifier, isAlias: true))
            }
        }

        items.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }

        if searchText.isEmpty { return items }
        return items.filter { item in
            if item.displayName.localizedCaseInsensitiveContains(searchText) { return true }
            let searchable = item.identifier.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "/", with: " ")
            if searchable.localizedCaseInsensitiveContains(searchText) { return true }
            if let tz = TimeZone(identifier: item.identifier) {
                if formatGMTOffset(tz).localizedCaseInsensitiveContains(searchText) { return true }
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            List(pickerItems) { item in
                let alreadyAdded = existingTimezones.contains { $0.zone == item.identifier }
                Button {
                    if !alreadyAdded {
                        onAdd(item.identifier, item.displayName)
                        dismiss()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName)
                                .font(.body)
                                .foregroundStyle(alreadyAdded ? .tertiary : .primary)
                            if let tz = TimeZone(identifier: item.identifier) {
                                Text([item.region, formatGMTOffset(tz)].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(alreadyAdded ? .quaternary : .secondary)
                            }
                        }
                        Spacer()
                        if alreadyAdded {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(alreadyAdded)
            }
            .navigationTitle("Add Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search city")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
