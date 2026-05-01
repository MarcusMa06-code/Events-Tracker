//
//  EventsView.swift
//  Events Tracker
//
//  V3 Events Screen: 14-day strip + filter pills + date-grouped timeline
//

import SwiftUI

// MARK: - Filter

private enum EventsFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "Open"
    case missing = "Missing"
    case exam = "Exams"
    case assignment = "Assignments"
    case event = "Events"

    var id: String { rawValue }
}

// MARK: - Week Strip

private struct WeekStrip: View {
    let tasks: [UnifiedTask]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let et = ETColors(colorScheme: colorScheme)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(0..<14, id: \.self) { offset in
                    let day = cal.date(byAdding: .day, value: offset, to: today)!
                    let dayStart = cal.startOfDay(for: day)
                    let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
                    let dayTasks = tasks.filter { t in
                        guard let d = t.dueDate else { return false }
                        return d >= dayStart && d < dayEnd
                    }
                    let hasExam = dayTasks.contains { $0.kind == .exam }
                    let isToday = offset == 0

                    DayCell(
                        date: day, taskCount: dayTasks.count,
                        hasExam: hasExam, isToday: isToday, et: et
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .overlay(alignment: .bottom) {
            et.hairline.frame(height: 1)
        }
    }
}

private struct DayCell: View {
    let date: Date
    let taskCount: Int
    let hasExam: Bool
    let isToday: Bool
    let et: ETColors

    var body: some View {
        VStack(spacing: 4) {
            Text(shortDayName(date).uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isToday ? et.accent : et.textFaint)
                .kerning(0.4)

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isToday ? et.accent : Color.primary)
                .monospacedDigit()

            // Bar indicators
            HStack(alignment: .bottom, spacing: 2) {
                if taskCount > 0 {
                    ForEach(0..<min(taskCount, 4), id: \.self) { k in
                        let barHeight = max(4.0, 14.0 * (1.0 - Double(k) * 0.15))
                        Rectangle()
                            .fill(hasExam && k == 0 ? et.urgent : et.accent)
                            .frame(width: 4, height: barHeight)
                            .opacity(0.5 + 0.5 * (1.0 - Double(k) / max(1.0, Double(taskCount))))
                            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    }
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 18)
        }
        .frame(width: 46)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isToday ? et.accent.opacity(0.1) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(isToday ? et.accent.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Filter Pills

private struct FilterPills: View {
    @Binding var selection: EventsFilter
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let et = ETColors(colorScheme: colorScheme)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(EventsFilter.allCases) { filter in
                    let active = selection == filter
                    Button(filter.rawValue) {
                        selection = filter
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(active ? Color.primary : et.textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(active ? et.pillBg.opacity(2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .overlay(alignment: .bottom) {
            et.hairline.frame(height: 1)
        }
    }
}

// MARK: - Task Row (for timeline)

private struct TimelineTaskRow: View {
    let task: UnifiedTask
    let course: Course?
    let et: ETColors
    let onPin: () -> Void

    @State private var isHovered = false

    var body: some View {
        let cColor = course.map { courseColor(for: $0) } ?? Color.secondary
        let overdue = task.bucket == .overdue
        let cdColor: Color = overdue ? et.urgent : (task.bucket == .today ? et.warn : et.textMuted)

        HStack(alignment: .center, spacing: 0) {
            // Color rail
            cColor.opacity(0.85)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                // Title row
                HStack(spacing: 6) {
                    if task.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(et.warn)
                    }
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    if task.kind == .exam {
                        ExamBadge(et: et)
                    }
                    TaskStatusPillView(status: task.status, et: et)
                    Spacer()
                }

                // Meta row
                HStack(spacing: 8) {
                    if let course {
                        CourseChipView(course: course)
                    }
                    if let due = task.dueDate {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundStyle(et.textMuted)
                            Text("\(shortDayName(due)) \(shortDate(due)) · \(shortTime(due))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(et.textMuted)
                        }
                    }
                    if let pts = task.points {
                        Text("\(Int(pts)) pts")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(et.textFaint)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Spacer()

            // Right: countdown + actions
            VStack(alignment: .trailing, spacing: 4) {
                if task.status != .graded, let due = task.dueDate {
                    Text(overdue ? "overdue" : countdownText(to: due))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(cdColor)
                }
                HStack(spacing: 2) {
                    ActionButton(
                        systemImage: task.isPinned ? "star.fill" : "star",
                        label: task.isPinned ? "Unpin" : "Pin",
                        active: task.isPinned, et: et, action: onPin
                    )
                    if let url = task.htmlURL {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 12))
                                .foregroundStyle(et.textMuted)
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                        .help("Open in Canvas")
                    }
                }
                .opacity(isHovered ? 1.0 : 0.5)
            }
            .padding(.trailing, 14)
        }
        .background(isHovered ? et.rowHover : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}

// MARK: - Date Group

private struct DateGroup {
    let date: Date
    var tasks: [UnifiedTask]
}

private func groupByDate(_ tasks: [UnifiedTask]) -> [DateGroup] {
    let cal = Calendar.current
    var groups: [DateGroup] = []
    var lastKey: Date?

    for task in tasks {
        let d = cal.startOfDay(for: task.dueDate ?? Date.distantFuture)
        if d != lastKey {
            groups.append(DateGroup(date: d, tasks: [task]))
            lastKey = d
        } else {
            groups[groups.count - 1].tasks.append(task)
        }
    }
    return groups
}

// MARK: - Events View

struct EventsView: View {
    @EnvironmentObject private var store: CanvasStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var filter: EventsFilter = .open

    var body: some View {
        if !store.isConfigured {
            SetupPromptView(
                title: "Canvas Events Need a Connection",
                message: "Add your Canvas credentials in Settings to load assignments, calendar events, and missing work."
            )
        } else {
            EventsContentView(filter: $filter)
        }
    }
}

private struct EventsContentView: View {
    @EnvironmentObject private var store: CanvasStore
    @Environment(\.colorScheme) private var colorScheme
    @Binding var filter: EventsFilter

    var body: some View {
        let et = ETColors(colorScheme: colorScheme)
        let allTasks = store.unifiedTasks(courseID: store.selectedCourseID)

        let filtered = allTasks.filter { task in
            switch filter {
            case .all: return true
            case .open: return task.status != .graded
            case .missing: return task.status == .missing || task.bucket == .overdue
            case .exam: return task.kind == .exam || task.kind == .quiz
            case .assignment: return task.kind == .assignment
            case .event: return task.kind == .event
            }
        }

        let groups = groupByDate(filtered)

        VStack(spacing: 0) {
            WeekStrip(tasks: allTasks.filter { $0.status != .graded })
            FilterPills(selection: $filter)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    if groups.isEmpty {
                        Text("No items match this filter.")
                            .font(.system(size: 13))
                            .foregroundStyle(et.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(groups.enumerated()), id: \.element.date) { idx, group in
                            let dDays: Int = {
                                let cal = Calendar.current
                                let today = cal.startOfDay(for: Date())
                                return cal.dateComponents([.day], from: today, to: group.date).day ?? 0
                            }()
                            let sub: String = {
                                if dDays < 0 { return "\(-dDays)d ago" }
                                if dDays == 0 { return "today" }
                                if dDays == 1 { return "tomorrow" }
                                return "in \(dDays)d"
                            }()
                            let tone: Color = dDays < 0 ? et.urgent : (dDays == 0 ? et.warn : Color.primary)

                            HStack(alignment: .top, spacing: 16) {
                                // Date label column
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(longDayDate(group.date))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(tone)
                                    Text("\(sub) · \(group.tasks.count) item\(group.tasks.count == 1 ? "" : "s")")
                                        .font(.system(size: 11))
                                        .foregroundStyle(et.textMuted)
                                }
                                .frame(width: 120, alignment: .leading)
                                .padding(.top, 4)

                                // Task card
                                VStack(spacing: 0) {
                                    ForEach(group.tasks) { task in
                                        let course = store.courses.first { $0.id == task.courseID }
                                        TimelineTaskRow(task: task, course: course, et: et) {
                                            store.togglePin(task.id)
                                        }
                                        if task.id != group.tasks.last?.id {
                                            et.hairline.frame(height: 1)
                                                .padding(.leading, 15)
                                        }
                                    }
                                }
                                .background(et.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(et.hairline, lineWidth: 1)
                                )
                            }
                            .padding(.top, idx == 0 ? 16 : 22)
                            .padding(.horizontal, 18)
                        }
                        Spacer().frame(height: 32)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        EventsView()
            .environmentObject(CanvasStore())
    }
}
