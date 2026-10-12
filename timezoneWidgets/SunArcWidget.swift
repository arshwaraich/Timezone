//
//  SunArcWidget.swift
//  timezoneWidgets
//

import AppIntents
import SwiftUI
import WidgetKit

struct SunArcWidget: Widget {
    nonisolated static let kind = "SunArcWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: CitiesConfigIntent.self,
            provider: CityTimelineProvider<CitiesConfigIntent>(scrubbable: true)
        ) { entry in
            SunArcWidgetView(entry: entry)
                .environment(\.colorScheme, .dark)
                .containerBackground(Color(red: 0.035, green: 0.035, blue: 0.043), for: .widget)
        }
        .configurationDisplayName("Sun Arc")
        .description("See where each city sits in its day, and step time forward or back.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct SunArcWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SunEntry

    var body: some View {
        GeometryReader { geo in
            switch family {
            case .systemSmall:
                VStack(spacing: 0) {
                    chart
                    VStack(spacing: 4) {
                        ForEach(entry.cities.prefix(2)) { city in
                            WidgetCityRow(city: city, date: entry.shownDate, timeSize: 13)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            case .systemMedium:
                HStack(spacing: 0) {
                    chart
                        .frame(width: geo.size.width * 0.46)
                    VStack(spacing: 6) {
                        ForEach(entry.cities.prefix(3)) { city in
                            WidgetCityRow(city: city, date: entry.shownDate, timeSize: 15)
                        }
                        Spacer(minLength: 0)
                        ScrubControls(offsetHours: entry.offsetHours)
                    }
                    .padding(12)
                }
            default:
                VStack(spacing: 0) {
                    chart
                        .frame(height: geo.size.height * 0.36)
                    VStack(spacing: 6) {
                        ForEach(entry.cities.prefix(4)) { city in
                            WidgetCityRow(city: city, date: entry.shownDate, timeSize: 20, showsDate: true)
                        }
                        Spacer(minLength: 0)
                        ScrubControls(offsetHours: entry.offsetHours)
                    }
                    .padding(14)
                }
            }
        }
    }

    private var chart: some View {
        WidgetSunChart(cities: entry.cities, date: entry.shownDate, markerRadius: family == .systemSmall ? 5 : 6)
    }
}

// MARK: - Chart

struct WidgetSunChart: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let cities: [WidgetCity]
    let date: Date
    var markerRadius: CGFloat = 6

    var body: some View {
        ZStack {
            // Tinted and clear home screens flatten colour, so the sky only draws in full colour
            if renderingMode == .fullColor {
                SkyGradientView()
            }

            Canvas { context, size in
                let hPadding = markerRadius + 6
                let drawWidth = size.width - hPadding * 2
                let cY = size.height / 2
                let amp = size.height / 3

                // Stars over the night ends of the sky
                if renderingMode == .fullColor {
                    var seed: UInt64 = 0x5DEECE66D
                    func next() -> CGFloat {
                        seed = seed &* 6364136223846793005 &+ 1442695040888963407
                        return CGFloat(seed >> 40) / CGFloat(1 << 24)
                    }
                    for _ in 0..<28 {
                        let night = next() * 0.38
                        let x = (night < 0.19 ? night : 0.62 + night) * size.width
                        let y = next() * size.height
                        let r = 0.4 + next() * 0.7
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                            with: .color(.white.opacity(0.35 + next() * 0.5))
                        )
                    }
                }

                // Horizon line
                let horizonPath = Path { p in
                    p.move(to: CGPoint(x: 0, y: cY))
                    p.addLine(to: CGPoint(x: size.width, y: cY))
                }
                context.stroke(
                    horizonPath,
                    with: .color(.white.opacity(0.15)),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )

                // Sine wave
                let wavePath = Path { p in
                    for i in 0...120 {
                        let frac = CGFloat(i) / 120
                        let point = CGPoint(x: hPadding + frac * drawWidth, y: cY - sin(frac * 2 * .pi - .pi / 2) * amp)
                        if i == 0 {
                            p.move(to: point)
                        } else {
                            p.addLine(to: point)
                        }
                    }
                }
                context.stroke(
                    wavePath,
                    with: .color(Color(red: 0.984, green: 0.749, blue: 0.141).opacity(0.85)),
                    style: StrokeStyle(lineWidth: 2)
                )

                // Timezone markers
                for city in cities {
                    let frac = getHoursInTimezone(zone: city.zone, date: date) / 24
                    let cx = hPadding + frac * drawWidth
                    let cy = cY - sin(frac * 2 * .pi - .pi / 2) * amp
                    let circle = Path(ellipseIn: CGRect(x: cx - markerRadius, y: cy - markerRadius, width: markerRadius * 2, height: markerRadius * 2))
                    context.fill(circle, with: .color(city.color))
                    context.stroke(circle, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5))
                }
            }
        }
    }
}

// MARK: - Rows

struct WidgetCityRow: View {
    let city: WidgetCity
    let date: Date
    let timeSize: CGFloat
    var showsDate = false

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(city.name)
                    .font(.system(size: showsDate ? 14 : 12, weight: .semibold))
                    .foregroundStyle(city.color)
                    .lineLimit(1)
                if showsDate {
                    Text(getDateString(zone: city.zone, date: date))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(white: 0.45))
                }
            }
            Spacer(minLength: 0)
            Text(getTimeString(zone: city.zone, date: date))
                .font(.system(size: timeSize, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(white: 0.93))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
        }
    }
}

// MARK: - Scrub controls

struct ScrubControls: View {
    let offsetHours: Int

    var body: some View {
        HStack(spacing: 6) {
            Button(intent: ShiftTimeIntent(hours: -1)) {
                pill { Image(systemName: "minus") }
            }
            Button(intent: ResetTimeIntent()) {
                pill {
                    Text(offsetHours == 0 ? "Now" : String(format: "%+dh", offsetHours))
                        .foregroundStyle(offsetHours == 0 ? Color(white: 0.6) : Color(red: 0.957, green: 0.247, blue: 0.369))
                }
            }
            Button(intent: ShiftTimeIntent(hours: 1)) {
                pill { Image(systemName: "plus") }
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Color(white: 0.93))
    }

    private func pill(@ViewBuilder _ label: () -> some View) -> some View {
        label()
            .frame(maxWidth: .infinity)
            .frame(height: 26)
            .background(.white.opacity(0.1), in: Capsule())
    }
}
