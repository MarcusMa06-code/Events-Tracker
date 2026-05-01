//
//  HomeView.swift
//  Events Tracker
//
//  V2 Triage Board: 4-column kanban (Overdue · Today · This week · Later)
//

import SwiftUI

// MARK: - Stat Strip

private struct StatStrip: View {
    @EnvironmentObject private var store: CanvasStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let et = ETColors(colorScheme: colorScheme)
        let overdue = store.overdueCount
        let today = store.todayTaskCount
        let week = store.thisWeekTaskCount
        let exams = store.upcomingExamCount

        HStack(spacing: 0) {
            StatTile(value: "\(overdue)", label: "Overdue",
                     valueColor: overdue > 0 ? et.urgent : et.textMuted, et: et)
            Divider()
            StatTile(value: "\(today)", label: "Due today",
                     valueColor: today > 0 ? et.warn : et.textMuted, et: et)
            Divider()
            StatTile(value: "\(week)", label: "This week",
                     valueColor: Color.primary, et: et)
            Divider()
            StatTile(value: "\(exams)", label: "Exams ahead",
                     valueColor: Color.primary, et: et)
        }
        .frame(height: 72)
        .background(et.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(et.hairline, lineWidth: 1)
        )
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let valueColor: Color
    let et: ETColors

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .default))
                .foregroundStyle(valueColor)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(et.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Column Header

private struct ColumnHeader: View {
    let title: String
    let count: Int
    let tone: Color
    let subtitle: String?
    let et: ETColors

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tone)
                .kerning(0.5)
                .textCase(.uppercase)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(et.textFaint)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(et.pillBg)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(et.textFaint)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            et.hairline.frame(height: 1)
        }
    }
}

// MARK: - Board Card

private struct BoardCard: View {
    let task: UnifiedTask
    let course: Course?
    let et: ETColors
    let onPin: () -> Void

    @State private var isHovered = false

    var body: some View {
        let cColor = course.map { courseColor(for: $0) } ?? Color.secondary
        let overdue = task.bucket == .overdue
        let cdColor: Color = overdue ? et.urgent : (task.bucket == .today ? et.warn : et.textMuted)

        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(et.surface)
                .shadow(color: isHovered ? Color.black.opacity(0.07) : .clear, radius: 4, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(et.hairline, lineWidth: 1)
                )

            HStack(alignment: .top, spacing: 0) {
                // Course color rail
                cColor.opacity(0.85)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    // Top row: course chip + badges
                    HStack(spacing: 6) {
                        if let course {
                            CourseChipView(course: course)
                        }
                        if task.kind == .exam {
                            ExamBadge(et: et)
                        }
                        if task.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(et.warn)
                        }
                        Spacer()
                        TaskStatusPillView(status: task.status, et: et)
                    }

                    // Title
                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)

                    // Time row + countdown
                    HStack {
                        if let due = task.dueDate {
                            Label {
                                Text("\(shortDayName(due)) \(shortTime(due))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(et.textMuted)
                            } icon: {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                    .foregroundStyle(et.textMuted)
                            }
                        }
                        Spacer()
                        if task.status != .graded, let due = task.dueDate {
                            Text(overdue ? "overdue" : countdownText(to: due))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(cdColor)
                        }
                    }

                    // Action buttons (visible on hover)
                    if isHovered {
                        HStack(spacing: 4) {
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
                                        .background(et.rowHover)
                                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .padding(10)
            }
        }
        .padding(.bottom, 8)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}

// MARK: - Board Column

private struct BoardColumn: View {
    let title: String
    let subtitle: String?
    let tone: Color
    let tasks: [UnifiedTask]
    let emptyMessage: String
    let et: ETColors
    let courses: [Course]
    let onPin: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ColumnHeader(title: title, count: tasks.count, tone: tone,
                         subtitle: subtitle, et: et)
                .padding(.horizontal, 4)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    if tasks.isEmpty {
                        Text(emptyMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(et.textFaint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                            .padding(.horizontal, 4)
                            .multilineTextAlignment(.center)
                    } else {
                        ForEach(tasks) { task in
                            let course = courses.first { $0.id == task.courseID }
                            BoardCard(task: task, course: course, et: et) {
                                onPin(task.id)
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Focused Task View (Overdue / Today full-width)

enum FocusMode { case overdue, today }

struct FocusedTaskView: View {
    let mode: FocusMode
    @EnvironmentObject private var store: CanvasStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let et = ETColors(colorScheme: colorScheme)
        let allTasks = store.unifiedTasks(courseID: store.selectedCourseID)

        let tasks: [UnifiedTask]
        let title: String
        let tone: Color
        let emptyMsg: String

        switch mode {
        case .overdue:
            tasks = allTasks.filter { $0.bucket == .overdue }
            title = "Overdue"
            tone = et.urgent
            emptyMsg = "Nothing overdue. You're all caught up! 🎉"
        case .today:
            tasks = allTasks.filter { $0.bucket == .today }
            title = "Today"
            tone = et.warn
            emptyMsg = "Nothing due today. Enjoy your day!"
        }

        return VStack(spacing: 0) {
            // Header bar
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(tone)
                Text("\(tasks.count) item\(tasks.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundStyle(et.textMuted)
                if mode == .today {
                    Spacer()
                    Text(todayLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(et.textFaint)
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            et.hairline.frame(height: 1)

            if tasks.isEmpty {
                Spacer()
                Text(emptyMsg)
                    .font(.system(size: 14))
                    .foregroundStyle(et.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(40)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            let course = store.courses.first { $0.id == task.courseID }
                            FocusedTaskRow(task: task, course: course, et: et) {
                                store.togglePin(task.id)
                            }
                            et.hairline.frame(height: 1)
                                .padding(.leading, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }
}

private struct FocusedTaskRow: View {
    let task: UnifiedTask
    let course: Course?
    let et: ETColors
    let onPin: () -> Void
    @State private var isHovered = false

    var body: some View {
        let cColor = course.map { courseColor(for: $0) } ?? Color.secondary
        let overdue = task.bucket == .overdue
        let cdColor: Color = overdue ? et.urgent : et.warn

        HStack(alignment: .center, spacing: 0) {
            // Color rail
            cColor.opacity(0.85)
                .frame(width: 4)
                .padding(.vertical, 10)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if task.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(et.warn)
                    }
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    if task.kind == .exam { ExamBadge(et: et) }
                    TaskStatusPillView(status: task.status, et: et)
                }
                HStack(spacing: 10) {
                    if let course { CourseChipView(course: course) }
                    if let due = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                                .foregroundStyle(et.textMuted)
                            Text("\(shortDayName(due)) \(shortDate(due)) · \(shortTime(due))")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(et.textMuted)
                        }
                    }
                    if let pts = task.points {
                        Text("\(Int(pts)) pts")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(et.textFaint)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if let due = task.dueDate {
                    Text(overdue ? countdownText(to: due) + " ago" : countdownText(to: due))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(cdColor)
                }
                HStack(spacing: 4) {
                    ActionButton(
                        systemImage: task.isPinned ? "star.fill" : "star",
                        label: task.isPinned ? "Unpin" : "Pin",
                        active: task.isPinned, et: et, action: onPin
                    )
                    if let url = task.htmlURL {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 13))
                                .foregroundStyle(et.textMuted)
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(.plain)
                        .help("Open in Canvas")
                    }
                }
                .opacity(isHovered ? 1 : 0.45)
            }
            .padding(.trailing, 20)
        }
        .background(isHovered ? et.rowHover : Color.clear)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Home View (Triage Board)

struct HomeView: View {
    @EnvironmentObject private var store: CanvasStore

    var body: some View {
        if !store.isConfigured {
            SetupPromptView(
                title: "Connect Canvas",
                message: "Save your Canvas base URL and personal access token in Settings, then sync to build your dashboard."
            )
        } else {
            TriageBoardView()
        }
    }
}

private struct TriageBoardView: View {
    @EnvironmentObject private var store: CanvasStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let et = ETColors(colorScheme: colorScheme)
        let tasks = store.unifiedTasks(courseID: store.selectedCourseID)

        var overdueTasks: [UnifiedTask] = []
        var todayTasks: [UnifiedTask] = []
        var weekTasks: [UnifiedTask] = []
        var laterTasks: [UnifiedTask] = []

        for task in tasks {
            switch task.bucket {
            case .overdue:
                overdueTasks.append(task)
            case .today:
                todayTasks.append(task)
            case .tomorrow, .thisWeek:
                weekTasks.append(task)
            case .later:
                laterTasks.append(task)
            }
        }

        return VStack(spacing: 0) {
            StatStrip()
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            HStack(alignment: .top, spacing: 0) {
                BoardColumn(
                    title: "Overdue", subtitle: nil, tone: et.urgent,
                    tasks: overdueTasks, emptyMessage: "All caught up.",
                    et: et, courses: store.courses,
                    onPin: { store.togglePin($0) }
                )
                Divider()
                BoardColumn(
                    title: "Today", subtitle: todaySubtitle, tone: et.warn,
                    tasks: todayTasks, emptyMessage: "Nothing due today.",
                    et: et, courses: store.courses,
                    onPin: { store.togglePin($0) }
                )
                Divider()
                BoardColumn(
                    title: "This week", subtitle: nil, tone: Color.primary,
                    tasks: weekTasks, emptyMessage: "Quiet week.",
                    et: et, courses: store.courses,
                    onPin: { store.togglePin($0) }
                )
                Divider()
                BoardColumn(
                    title: "Later", subtitle: nil, tone: Color.primary,
                    tasks: laterTasks, emptyMessage: "No far-future items.",
                    et: et, courses: store.courses,
                    onPin: { store.togglePin($0) }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var todaySubtitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f.string(from: Date())
    }
}

// MARK: - Shared sub-components (also used by EventsView)

struct CourseChipView: View {
    let course: Course
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let et = ETColors(colorScheme: colorScheme)
        HStack(spacing: 5) {
            Circle()
                .fill(courseColor(for: course))
                .frame(width: 7, height: 7)
            Text(course.courseCode ?? course.name)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(et.pillBg)
        .clipShape(Capsule())
    }
}

struct TaskStatusPillView: View {
    let status: TaskStatus
    let et: ETColors

    var body: some View {
        switch status {
        case .missing:
            pill(text: "Missing", fg: et.urgent, bg: et.urgent.opacity(0.12))
        case .submitted:
            pill(text: "Submitted", fg: et.ok, bg: et.ok.opacity(0.12))
        case .graded:
            pill(text: "Graded", fg: et.textMuted, bg: et.pillBg)
        case .todo:
            EmptyView()
        }
    }

    @ViewBuilder
    private func pill(text: String, fg: Color, bg: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.3)
            .textCase(.uppercase)
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(bg)
            .clipShape(Capsule())
    }
}

struct ExamBadge: View {
    let et: ETColors
    var body: some View {
        Text("EXAM")
            .font(.system(size: 9.5, weight: .heavy))
            .tracking(0.5)
            .foregroundStyle(et.urgent)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(et.urgent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }
}

struct ActionButton: View {
    let systemImage: String
    let label: String
    let active: Bool
    let et: ETColors
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
                .foregroundStyle(active ? et.accent : et.textMuted)
                .frame(width: 22, height: 22)
                .background(isHovered ? et.rowHover : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(label)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(CanvasStore())
    }
}
