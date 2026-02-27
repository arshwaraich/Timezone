//
//  ContentView.swift
//  timezone
//
//  Created by Arsh Waraich on 2026-02-24.
//

import SwiftUI

// MARK: - Models

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

// MARK: - Constants

let COLORS: [Color] = [
    Color(red: 0.957, green: 0.247, blue: 0.369), // rose-500
    Color(red: 0.078, green: 0.722, blue: 0.651), // teal-500
    Color(red: 0.545, green: 0.361, blue: 0.965), // purple-500
    Color(red: 0.961, green: 0.620, blue: 0.043), // amber-500
    Color(red: 0.231, green: 0.510, blue: 0.965), // blue-500
    Color(red: 0.925, green: 0.306, blue: 0.600), // pink-500
    Color(red: 0.063, green: 0.725, blue: 0.506), // emerald-500
    Color(red: 0.976, green: 0.451, blue: 0.086), // orange-500
]

func displayName(for identifier: String) -> String {
    let component = identifier.split(separator: "/").last ?? Substring(identifier)
    return component.replacingOccurrences(of: "_", with: " ")
}

func regionPath(for identifier: String) -> String {
    let parts = identifier.split(separator: "/")
    if parts.count > 1 {
        return parts.dropLast().joined(separator: " / ").replacingOccurrences(of: "_", with: " ")
    }
    return ""
}

func formatGMTOffset(_ tz: TimeZone) -> String {
    let seconds = tz.secondsFromGMT()
    let hours = seconds / 3600
    let minutes = abs(seconds % 3600) / 60
    if minutes == 0 {
        return String(format: "GMT%+d", hours)
    }
    return String(format: "GMT%+d:%02d", hours, minutes)
}

// Alias name → timezone identifier for popular cities not in IANA
let CITY_ALIASES: [String: String] = [
    // India
    "New Delhi": "Asia/Kolkata",
    "Mumbai": "Asia/Kolkata",
    "Bangalore": "Asia/Kolkata",
    "Chennai": "Asia/Kolkata",
    "Hyderabad": "Asia/Kolkata",
    "Pune": "Asia/Kolkata",
    // China
    "Beijing": "Asia/Shanghai",
    "Shenzhen": "Asia/Shanghai",
    "Guangzhou": "Asia/Shanghai",
    "Chengdu": "Asia/Shanghai",
    // Japan
    "Osaka": "Asia/Tokyo",
    "Kyoto": "Asia/Tokyo",
    // South Korea
    "Busan": "Asia/Seoul",
    // USA
    "San Francisco": "America/Los_Angeles",
    "Seattle": "America/Los_Angeles",
    "Boston": "America/New_York",
    "Washington DC": "America/New_York",
    "Miami": "America/New_York",
    "Atlanta": "America/New_York",
    "Dallas": "America/Chicago",
    "Houston": "America/Chicago",
    // Canada
    "Vancouver": "America/Vancouver",
    "Montreal": "America/Toronto",
    "Ottawa": "America/Toronto",
    "Calgary": "America/Edmonton",
    // Europe
    "Milan": "Europe/Rome",
    "Barcelona": "Europe/Madrid",
    "Munich": "Europe/Berlin",
    "Frankfurt": "Europe/Berlin",
    "Edinburgh": "Europe/London",
    "Manchester": "Europe/London",
    // Middle East
    "Abu Dhabi": "Asia/Dubai",
    "Riyadh": "Asia/Riyadh",
    "Tel Aviv": "Asia/Jerusalem",
    // Australia
    "Brisbane": "Australia/Brisbane",
    "Perth": "Australia/Perth",
    // South America
    "Buenos Aires": "America/Argentina/Buenos_Aires",
    "Rio de Janeiro": "America/Sao_Paulo",
    "Bogota": "America/Bogota",
    "Lima": "America/Lima",
    // Africa
    "Cape Town": "Africa/Johannesburg",
    "Lagos": "Africa/Lagos",
    "Nairobi": "Africa/Nairobi",
    "Cairo": "Africa/Cairo",
]

struct TimezonePickerItem: Identifiable {
    let id: String  // unique key for the list
    let displayName: String
    let identifier: String
    let isAlias: Bool

    var region: String { regionPath(for: identifier) }
}

// MARK: - Timezone Helpers

func getAdjustedDate(timeOffset: Double) -> Date {
    Date().addingTimeInterval(timeOffset * 3600)
}

func getTimeString(zone: String, date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: zone)
    formatter.amSymbol = "AM"
    formatter.pmSymbol = "PM"
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
}

func getDateString(zone: String, date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: zone)
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
}

func getHoursInTimezone(zone: String, date: Date) -> CGFloat {
    let tz = TimeZone(identifier: zone) ?? .current
    let formatter = DateFormatter()
    formatter.timeZone = tz
    formatter.dateFormat = "HH"
    let hours = CGFloat(Int(formatter.string(from: date)) ?? 0)
    formatter.dateFormat = "mm"
    let minutes = CGFloat(Int(formatter.string(from: date)) ?? 0)
    return hours + minutes / 60.0
}

func calculatePosition(hours: CGFloat, width: CGFloat, height: CGFloat) -> (x: CGFloat, y: CGFloat) {
    let centerY = height / 2
    let amplitude = height / 2.5
    let x = (hours / 24) * width
    let angle = (hours / 24) * 2 * .pi - .pi / 2
    let y = centerY - sin(angle) * amplitude
    return (x, y)
}

func computeTimezoneData(timezones: [TimezoneEntry], timeOffset: Double, width: CGFloat, height: CGFloat) -> [String: TimezoneData] {
    let adjustedDate = getAdjustedDate(timeOffset: timeOffset)
    var result: [String: TimezoneData] = [:]
    for tz in timezones {
        let hours = getHoursInTimezone(zone: tz.zone, date: adjustedDate)
        let pos = calculatePosition(hours: hours, width: width, height: height)
        result[tz.zone] = TimezoneData(
            time: getTimeString(zone: tz.zone, date: adjustedDate),
            date: getDateString(zone: tz.zone, date: adjustedDate),
            positionX: pos.x,
            positionY: pos.y,
            hours: hours
        )
    }
    return result
}

// MARK: - Sky Gradient View

struct SkyGradientView: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.035, green: 0.035, blue: 0.043), location: 0),
                .init(color: Color(red: 0.094, green: 0.094, blue: 0.106), location: 0.125),
                .init(color: Color(red: 0.153, green: 0.153, blue: 0.165), location: 0.167),
                .init(color: Color(red: 0.247, green: 0.247, blue: 0.275), location: 0.20),
                .init(color: Color(red: 0.918, green: 0.345, blue: 0.047), location: 0.208),
                .init(color: Color(red: 0.976, green: 0.451, blue: 0.086), location: 0.23),
                .init(color: Color(red: 0.984, green: 0.573, blue: 0.235), location: 0.25),
                .init(color: Color(red: 0.984, green: 0.749, blue: 0.141), location: 0.292),
                .init(color: Color(red: 0.024, green: 0.714, blue: 0.831), location: 0.333),
                .init(color: Color(red: 0.024, green: 0.714, blue: 0.831), location: 0.50),
                .init(color: Color(red: 0.024, green: 0.714, blue: 0.831), location: 0.667),
                .init(color: Color(red: 0.984, green: 0.749, blue: 0.141), location: 0.708),
                .init(color: Color(red: 0.984, green: 0.573, blue: 0.235), location: 0.75),
                .init(color: Color(red: 0.976, green: 0.451, blue: 0.086), location: 0.77),
                .init(color: Color(red: 0.918, green: 0.345, blue: 0.047), location: 0.792),
                .init(color: Color(red: 0.247, green: 0.247, blue: 0.275), location: 0.80),
                .init(color: Color(red: 0.153, green: 0.153, blue: 0.165), location: 0.833),
                .init(color: Color(red: 0.094, green: 0.094, blue: 0.106), location: 0.875),
                .init(color: Color(red: 0.035, green: 0.035, blue: 0.043), location: 1.0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Twinkling Star View

struct TwinklingStarView: View {
    let star: Star
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: star.size, height: star.size)
            .shadow(color: .white.opacity(0.8), radius: 2)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(star.delay)
                ) {
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Stars Overlay

struct StarsOverlay: View {
    let stars: [Star]

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                let isInNightZone = star.x < 19 || star.x > 81
                if isInNightZone {
                    TwinklingStarView(star: star)
                        .position(
                            x: star.x / 100 * geo.size.width,
                            y: star.y / 100 * geo.size.height
                        )
                }
            }
        }
    }
}

// MARK: - Sun Path Chart

struct SunPathChart: View {
    let width: CGFloat
    let height: CGFloat
    let timezones: [TimezoneEntry]
    let timezoneData: [String: TimezoneData]

    var centerY: CGFloat { height / 2 }
    var amplitude: CGFloat { height / 2.5 }

    private let hPadding: CGFloat = 16

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let drawLeft = hPadding
            let drawWidth = w - hPadding * 2
            let cY = h / 2
            let amp = h / 2.5

            // Horizon line
            let horizonPath = Path { p in
                p.move(to: CGPoint(x: 0, y: cY))
                p.addLine(to: CGPoint(x: w, y: cY))
            }
            context.stroke(
                horizonPath,
                with: .color(.white.opacity(0.15)),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )

            // Sine wave
            let wavePath = Path { p in
                for i in 0...200 {
                    let frac = CGFloat(i) / 200
                    let x = drawLeft + frac * drawWidth
                    let angle = frac * 2 * .pi - .pi / 2
                    let y = cY - sin(angle) * amp
                    if i == 0 {
                        p.move(to: CGPoint(x: x, y: y))
                    } else {
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            context.stroke(
                wavePath,
                with: .color(Color(red: 0.984, green: 0.749, blue: 0.141).opacity(0.85)),
                style: StrokeStyle(lineWidth: 3)
            )

            // Timezone markers
            for tz in timezones {
                guard let data = timezoneData[tz.zone] else { continue }
                let cx = drawLeft + (data.positionX / width) * drawWidth
                let cy = data.positionY / height * h

                // Circle
                let circle = Path(ellipseIn: CGRect(x: cx - 8, y: cy - 8, width: 16, height: 16))
                context.fill(circle, with: .color(tz.color))
                context.stroke(circle, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 2))

                // Label
                context.draw(
                    Text(tz.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white),
                    at: CGPoint(x: cx, y: cy - 18),
                    anchor: .center
                )
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Dial View

struct DialView: View {
    @Binding var dialOffset: CGFloat
    @Binding var timeOffset: Double
    @GestureState private var dragOffset: CGFloat = 0
    private let pixelsPerHour: CGFloat = 20
    private let markSpacing: CGFloat = 4
    @State private var lastMajorMarkIndex: Int = 0
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let majorMarkSpacing: CGFloat = 40 // markSpacing * 10

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dial marks
                Canvas { context, size in
                    let totalOffset = dialOffset + dragOffset
                    let wrappedOffset = totalOffset.truncatingRemainder(dividingBy: 200)
                    let startMark = -20
                    let endMark = Int(size.width / 4) + 20

                    for i in startMark...endMark + 150 {
                        let isMajor = i % 10 == 0
                        let isMinor = i % 5 == 0
                        let x = CGFloat(i) * 4 + wrappedOffset - 200
                        let markHeight: CGFloat
                        let markWidth: CGFloat
                        let markColor: Color

                        if isMajor {
                            markHeight = 36
                            markWidth = 2
                            markColor = Color(white: 0.75)
                        } else if isMinor {
                            markHeight = 22
                            markWidth = 2
                            markColor = Color(white: 0.45)
                        } else {
                            markHeight = 14
                            markWidth = 1
                            markColor = Color(white: 0.35)
                        }

                        let rect = CGRect(
                            x: x - markWidth / 2,
                            y: (size.height - markHeight) / 2,
                            width: markWidth,
                            height: markHeight
                        )
                        context.fill(Path(rect), with: .color(markColor))
                    }
                }

                // Center indicator
                Rectangle()
                    .fill(Color(red: 0.957, green: 0.247, blue: 0.369)) // rose-500
                    .frame(width: 2)
            }
        }
        .frame(height: 70)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    dialOffset += value.translation.width
                    timeOffset = Double(-(dialOffset / pixelsPerHour))
                }
        )
        .onChange(of: dragOffset) {
            let currentTotal = dialOffset + dragOffset
            timeOffset = Double(-(currentTotal / pixelsPerHour))

            let majorMark = Int(round(currentTotal / majorMarkSpacing))
            if majorMark != lastMajorMarkIndex {
                lightImpact.impactOccurred()
                lastMajorMarkIndex = majorMark
            }
        }
        .onAppear {
            lightImpact.prepare()
        }
    }
}

// MARK: - Timezone Row

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

// MARK: - Main View

struct ContentView: View {
    @State private var timezones: [TimezoneEntry] = ContentView.loadTimezones()
    @State private var timezoneData: [String: TimezoneData] = [:]
    @State private var dialOffset: CGFloat = 0
    @State private var timeOffset: Double = 0
    @State private var stars: [Star] = []
    @State private var showingTimezonePicker = false

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width < 600

            ZStack {
                Color(red: 0.035, green: 0.035, blue: 0.043)
                    .ignoresSafeArea()

                if isCompact {
                    compactLayout
                } else {
                    regularLayout
                }
            }
        }
        .onAppear {
            generateStars()
            updateTimezoneData()
        }
        .onChange(of: timeOffset) { updateTimezoneData() }
        .onChange(of: timezones) { updateTimezoneData() }
    }

    // MARK: - Compact (iPhone) Layout

    private var compactLayout: some View {
        VStack(spacing: 0) {
            // Chart pinned to top
            chartView
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

            // Timezone list - scrollable middle section
            timezoneList
                .frame(maxHeight: .infinity)

            // Dial pinned to bottom
            DialView(dialOffset: $dialOffset, timeOffset: $timeOffset)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Regular (iPad) Layout

    private var regularLayout: some View {
        HStack(alignment: .center, spacing: 16) {
            // Left panel: chart + dial
            VStack(spacing: 16) {
                chartView
                DialView(dialOffset: $dialOffset, timeOffset: $timeOffset)
            }
            .frame(maxWidth: .infinity)

            // Right panel: time list
            timezoneList
                .frame(width: 300)
        }
        .padding(32)
        .frame(maxWidth: 1200)
    }

    // MARK: - Chart

    private var chartView: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Sky gradient
                SkyGradientView()

                // Stars
                StarsOverlay(stars: stars)

                // Sun path chart with markers
                SunPathChart(
                    width: w,
                    height: h,
                    timezones: timezones,
                    timezoneData: computeTimezoneData(
                        timezones: timezones,
                        timeOffset: timeOffset,
                        width: w,
                        height: h
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .bottom) {
                HStack {
                    ForEach(["0h", "3h", "6h", "9h", "12h", "15h", "18h", "21h", "24h"], id: \.self) { label in
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                        if label != "24h" { Spacer() }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .glassEffect(
                    .regular,
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 16,
                        bottomTrailingRadius: 16,
                        topTrailingRadius: 0
                    )
                )
            }
            .shadow(color: .black.opacity(0.4), radius: 20)
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
    }

    // MARK: - Timezone List

    private var timezoneList: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(timezones) { tz in
                    if let data = timezoneData[tz.zone] {
                        TimezoneRow(entry: tz, data: data)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                }
                .onDelete(perform: removeTimezone)

                // Spacer row so last item isn't hidden behind the floating button
                Color.clear
                    .frame(height: 48)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            // Floating add timezone button
            Button {
                showingTimezonePicker = true
            } label: {
                Label("Add Timezone", systemImage: "plus")
                    .font(.system(size: 14))
            }
            .buttonStyle(.glass)
            .padding(.bottom, 12)
        }
        .sheet(isPresented: $showingTimezonePicker) {
            TimezonePickerView(existingTimezones: timezones) { identifier, name in
                addTimezone(identifier, name: name)
            }
        }
    }

    // MARK: - Actions

    private func generateStars() {
        stars = (0..<80).map { _ in
            Star(
                x: CGFloat.random(in: 0...100),
                y: CGFloat.random(in: 0...100),
                size: CGFloat.random(in: 0.5...2.0),
                delay: Double.random(in: 0...3)
            )
        }
    }

    private func addTimezone(_ identifier: String, name: String? = nil) {
        guard !timezones.contains(where: { $0.zone == identifier }) else { return }
        let colorIndex = timezones.count % COLORS.count
        let displayLabel = name ?? displayName(for: identifier)
        timezones.append(TimezoneEntry(name: displayLabel, zone: identifier, color: COLORS[colorIndex], colorIndex: colorIndex))
        saveTimezones()
    }

    private func removeTimezone(at offsets: IndexSet) {
        guard timezones.count > 1 else { return }
        timezones.remove(atOffsets: offsets)
        saveTimezones()
    }

    private func saveTimezones() {
        let saved = timezones.map { SavedTimezone(name: $0.name, zone: $0.zone, colorIndex: $0.colorIndex) }
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: "savedTimezones")
        }
    }

    static func loadTimezones() -> [TimezoneEntry] {
        guard let data = UserDefaults.standard.data(forKey: "savedTimezones"),
              let saved = try? JSONDecoder().decode([SavedTimezone].self, from: data),
              !saved.isEmpty else {
            return [
                TimezoneEntry(name: "Toronto", zone: "America/Toronto", color: COLORS[0], colorIndex: 0),
                TimezoneEntry(name: "New Delhi", zone: "Asia/Kolkata", color: COLORS[1], colorIndex: 1),
            ]
        }
        return saved.map { s in
            let idx = s.colorIndex % COLORS.count
            return TimezoneEntry(name: s.name, zone: s.zone, color: COLORS[idx], colorIndex: idx)
        }
    }

    private func updateTimezoneData() {
        let adjustedDate = getAdjustedDate(timeOffset: timeOffset)
        var result: [String: TimezoneData] = [:]
        for tz in timezones {
            let hours = getHoursInTimezone(zone: tz.zone, date: adjustedDate)
            // Use a nominal size for the data stored in state; the chart recalculates with its own geometry
            result[tz.zone] = TimezoneData(
                time: getTimeString(zone: tz.zone, date: adjustedDate),
                date: getDateString(zone: tz.zone, date: adjustedDate),
                positionX: 0,
                positionY: 0,
                hours: hours
            )
        }
        timezoneData = result
    }
}

#Preview {
    ContentView()
}
