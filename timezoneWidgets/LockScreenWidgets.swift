//
//  LockScreenWidgets.swift
//  timezoneWidgets
//

#if os(iOS)
import SwiftUI
import WidgetKit

// MARK: - City list

struct CityTimesWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CityTimesWidget",
            intent: CitiesConfigIntent.self,
            provider: CityTimelineProvider<CitiesConfigIntent>()
        ) { entry in
            VStack(spacing: 2) {
                ForEach(entry.cities.prefix(3)) { city in
                    HStack(spacing: 4) {
                        Image(systemName: daySymbol(forHours: getHoursInTimezone(zone: city.zone, date: entry.date)))
                            .font(.system(size: 10))
                            .frame(width: 14)
                        Text(city.name)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(getTimeString(zone: city.zone, date: entry.date))
                            .font(.system(size: 13, weight: .bold).monospacedDigit())
                            .layoutPriority(1)
                    }
                }
            }
            .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("City Times")
        .description("The current time in up to three cities.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Single city

struct CityClockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CityClockWidget",
            intent: CityConfigIntent.self,
            provider: CityTimelineProvider<CityConfigIntent>()
        ) { entry in
            CityClockView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("City Clock")
        .description("One city's time and where it sits on the sun arc.")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

struct CityClockView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SunEntry

    var body: some View {
        if let city = entry.cities.first {
            let hours = getHoursInTimezone(zone: city.zone, date: entry.date)
            let time = getTimeString(zone: city.zone, date: entry.date)

            if family == .accessoryInline {
                Label("\(city.name) \(time)", systemImage: daySymbol(forHours: hours))
            } else {
                let parts = time.split(separator: " ")
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        MiniSunArc(hours: hours)
                            .frame(height: 15)
                            .padding(.horizontal, 12)
                        Text(parts.first ?? "")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.7)
                        Text("\(parts.last ?? "") \(city.name.prefix(3).uppercased())")
                            .font(.system(size: 8, weight: .semibold))
                            .opacity(0.7)
                    }
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

struct MiniSunArc: View {
    let hours: CGFloat

    var body: some View {
        Canvas { context, size in
            let r: CGFloat = 2.5
            let drawWidth = size.width - r * 2
            let cY = size.height / 2
            let amp = size.height / 2 - r

            func point(_ frac: CGFloat) -> CGPoint {
                CGPoint(x: r + frac * drawWidth, y: cY - sin(frac * 2 * .pi - .pi / 2) * amp)
            }

            let wavePath = Path { p in
                p.move(to: point(0))
                for i in 1...40 {
                    p.addLine(to: point(CGFloat(i) / 40))
                }
            }
            context.stroke(wavePath, with: .color(.white.opacity(0.45)), style: StrokeStyle(lineWidth: 1))

            let dot = point(hours / 24)
            context.fill(Path(ellipseIn: CGRect(x: dot.x - r, y: dot.y - r, width: r * 2, height: r * 2)), with: .color(.white))
        }
    }
}
#endif
