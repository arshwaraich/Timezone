//
//  ContentView.swift
//  timezone
//
//  Created by Arsh Waraich on 2026-02-24.
//

import Combine
import SwiftUI
import WidgetKit

// MARK: - Main View

struct ContentView: View {
    @State private var timezones: [TimezoneEntry] = ContentView.loadTimezones()
    @State private var timezoneData: [String: TimezoneData] = [:]
    @State private var dialOffset: CGFloat = 0
    @State private var timeOffset: Double = 0
    @State private var stars: [Star] = []
    @State private var showingTimezonePicker = false
    #if os(macOS)
    @State private var selection: TimezoneEntry.ID?
    @State private var searchText = ""
    @State private var isSearching = false
    #endif

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width < 600

            ZStack {
                Color(red: 0.035, green: 0.035, blue: 0.043)
                    .ignoresSafeArea()

                #if os(macOS)
                macLayout
                #else
                if isCompact {
                    compactLayout
                } else {
                    regularLayout
                }
                #endif
            }
        }
        #if os(macOS)
        .navigationTitle(offsetDescription)
        .focusedSceneValue(\.timezoneActions, TimezoneActions(
            addCity: { isSearching = true },
            resetTime: resetTime,
            isShifted: timeOffset != 0
        ))
        .toolbar {
            if timeOffset != 0 {
                ToolbarItem {
                    Button("Now", systemImage: "arrow.uturn.backward", action: resetTime)
                        .help("Return to the current time")
                }
            }
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        #endif
        .onAppear {
            generateStars()
            updateTimezoneData()
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
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

    // MARK: - Mac Layout

    #if os(macOS)
    private var macLayout: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if searchText.isEmpty {
                    ForEach(timezones) { tz in
                        if let data = timezoneData[tz.zone] {
                            TimezoneRow(entry: tz, data: data)
                                .contextMenu {
                                    Button("Remove", systemImage: "trash", role: .destructive) {
                                        removeTimezone(tz)
                                    }
                                    .disabled(timezones.count <= 1)
                                }
                        }
                    }
                    .onDelete(perform: removeTimezone)
                } else {
                    // Typing in the sidebar search finds cities to add
                    ForEach(filterPickerItems(allPickerItems(), matching: searchText)) { item in
                        searchResult(for: item)
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, isPresented: $isSearching, placement: .sidebar, prompt: "Add a city")
            .onDeleteCommand {
                if let entry = timezones.first(where: { $0.id == selection }) {
                    removeTimezone(entry)
                }
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 380)
        } detail: {
            // Chart grows with the window instead of holding 4:3
            VStack(spacing: 16) {
                chart
                DialView(dialOffset: $dialOffset, timeOffset: $timeOffset)
            }
            .padding([.horizontal, .bottom], 16)
            .padding(.top, 4)
        }
    }

    private func searchResult(for item: TimezonePickerItem) -> some View {
        let alreadyAdded = timezones.contains { $0.zone == item.identifier }
        return Button {
            addTimezone(item.identifier, name: item.displayName)
            searchText = ""
            isSearching = false
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                    if let tz = TimeZone(identifier: item.identifier) {
                        Text([item.region, formatGMTOffset(tz)].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: alreadyAdded ? "checkmark" : "plus")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(alreadyAdded)
    }

    private var offsetDescription: String {
        let minutes = Int((timeOffset * 60).rounded())
        guard minutes != 0 else { return "Now" }
        let span = "\(abs(minutes) / 60)h \(abs(minutes) % 60)m"
        return minutes > 0 ? "\(span) from now" : "\(span) ago"
    }

    private func resetTime() {
        withAnimation(.snappy) {
            dialOffset = 0
            timeOffset = 0
        }
    }
    #endif

    // MARK: - Chart

    private var chartView: some View {
        chart
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
    }

    private var chart: some View {
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

    #if os(macOS)
    private func removeTimezone(_ entry: TimezoneEntry) {
        guard timezones.count > 1 else { return }
        timezones.removeAll { $0.id == entry.id }
        saveTimezones()
    }
    #endif

    private func saveTimezones() {
        TimezoneStore.save(timezones.map { SavedTimezone(name: $0.name, zone: $0.zone, colorIndex: $0.colorIndex) })
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func loadTimezones() -> [TimezoneEntry] {
        TimezoneStore.load().map { s in
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
