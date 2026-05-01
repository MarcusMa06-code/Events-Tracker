//
//  ETDesignTokens.swift
//  Events Tracker
//
//  Design tokens, color helpers, date utilities for the redesigned UI.
//

import SwiftUI

// MARK: - Color helpers

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: UInt64
        switch h.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Theme-adaptive colors

struct ETColors {
    let colorScheme: ColorScheme

    var accent: Color    { colorScheme == .dark ? Color(hex: "0a84ff") : Color(hex: "0066cc") }
    var urgent: Color    { colorScheme == .dark ? Color(hex: "ff453a") : Color(hex: "d70015") }
    var warn: Color      { colorScheme == .dark ? Color(hex: "ff9f0a") : Color(hex: "c93400") }
    var ok: Color        { colorScheme == .dark ? Color(hex: "30d158") : Color(hex: "248a3d") }
    var surface: Color   { colorScheme == .dark ? Color(hex: "28282a") : Color.white }
    var hairline: Color  { colorScheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.09) }
    var textMuted: Color { colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.5) }
    var textFaint: Color { colorScheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.35) }
    var pillBg: Color    { colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05) }
    var rowHover: Color  { colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04) }
    var sidebarBg: Color { colorScheme == .dark ? Color(hex: "2d2d2f").opacity(0.85) : Color(hex: "e8ebf2").opacity(0.75) }
}

// MARK: - Course color palette

private let courseColorHexes = [
    "7c8ba1", "3a5a9b", "3d5a55", "b88560",
    "5a7a3a", "b04a6f", "4a7a4a", "3d4a55",
]

func courseColor(for course: Course) -> Color {
    let idx = abs(course.id) % courseColorHexes.count
    return Color(hex: courseColorHexes[idx])
}

func courseColorHex(for course: Course) -> String {
    let idx = abs(course.id) % courseColorHexes.count
    return courseColorHexes[idx]
}

// MARK: - Task bucketing

enum TaskBucket: String {
    case overdue, today, tomorrow, thisWeek, later
}

func taskBucket(for date: Date) -> TaskBucket {
    let cal = Calendar.current
    let now = Date()
    let startOfToday = cal.startOfDay(for: now)
    let startOfDate = cal.startOfDay(for: date)
    let days = cal.dateComponents([.day], from: startOfToday, to: startOfDate).day ?? 0
    if days < 0 { return .overdue }
    if days == 0 { return .today }
    if days == 1 { return .tomorrow }
    if days <= 7 { return .thisWeek }
    return .later
}

// MARK: - Date formatting helpers

func countdownText(to date: Date) -> String {
    let ms = date.timeIntervalSince(Date())
    let abs = Swift.abs(ms)
    let days = Int(abs / 86400)
    let hours = Int((abs.truncatingRemainder(dividingBy: 86400)) / 3600)
    let mins = Int((abs.truncatingRemainder(dividingBy: 3600)) / 60)
    if days > 0 { return "\(days)d \(hours)h" }
    if hours > 0 { return "\(hours)h \(mins)m" }
    return "\(max(1, mins))m"
}

func relativeText(for date: Date) -> String {
    let cal = Calendar.current
    let now = Date()
    let startOfToday = cal.startOfDay(for: now)
    let startOfDate = cal.startOfDay(for: date)
    let days = cal.dateComponents([.day], from: startOfToday, to: startOfDate).day ?? 0
    if days < -1 { return "\(-days)d ago" }
    if days == -1 { return "yesterday" }
    if days == 0 {
        let secs = date.timeIntervalSince(now)
        if secs < 0 { return "earlier today" }
        let hrs = Int(secs / 3600)
        if hrs < 1 { return "in \(max(1, Int(secs / 60)))m" }
        return "in \(hrs)h"
    }
    if days == 1 { return "tomorrow" }
    if days <= 7 { return "in \(days)d" }
    return shortDate(date)
}

func shortDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "MMM d"
    return f.string(from: date)
}

func shortTime(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}

func shortDayName(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "EEE"
    return f.string(from: date)
}

func longDayDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "EEE, MMM d"
    return f.string(from: date)
}
