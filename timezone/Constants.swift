//
//  Constants.swift
//  timezone
//

import SwiftUI

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
