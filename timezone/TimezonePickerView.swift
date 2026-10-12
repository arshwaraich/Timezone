import SwiftUI

struct TimezonePickerView: View {
    let existingTimezones: [TimezoneEntry]
    let onAdd: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var pickerItems: [TimezonePickerItem] {
        filterPickerItems(allPickerItems(), matching: searchText)
    }

    var body: some View {
        NavigationStack {
            List(pickerItems) { item in
                row(for: item)
            }
            .navigationTitle("Add Timezone")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search city")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func row(for item: TimezonePickerItem) -> some View {
        let alreadyAdded = existingTimezones.contains { $0.zone == item.identifier }
        return Button {
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
}
