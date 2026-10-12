//
//  TimezoneHelpers.swift
//  timezone
//

import SwiftUI

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
