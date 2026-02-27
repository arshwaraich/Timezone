//
//  TimezoneRow.swift
//  timezone
//

import SwiftUI

struct TimezoneRow: View {
    let entry: TimezoneEntry
    let data: TimezoneData

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(entry.color)
                Text(data.date)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.45))
            }
            Spacer()
            Text(data.time)
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundColor(Color(white: 0.93))
        }
        .padding(.horizontal, 16)
    }
}
