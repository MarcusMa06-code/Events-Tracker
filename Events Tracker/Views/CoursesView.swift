//
//  CoursesView.swift
//  Events Tracker
//
//  Created by Codex on 13/4/26.
//

import SwiftUI

private enum CourseWorkspaceSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case modules = "Modules"
    case assignments = "Assignments"
    case grades = "Grades"

    var id: String { rawValue }
}

private enum CourseAssignmentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case upcoming = "Upcoming"
    case missing = "Missing"
    case completed = "Completed"

    var id: String { rawValue }

    func includes(_ assignment: CourseAssignment) -> Bool {
        switch self {
        case .all:
            return true
        case .upcoming:
            return assignment.isUpcoming
        case .missing:
            return assignment.status == .missing || assignment.status == .late
        case .completed:
            return assignment.isCompleted
        }
    }
}

struct CoursesView: View {
    @EnvironmentObject private var store: CanvasStore
    @State private var selectedSection: CourseWorkspaceSection = .overview
    @State private var assignmentFilter: CourseAssignmentFilter = .all

    private var selectedCourseBinding: Binding<Int?> {
        Binding(
            get: { store.selectedCourseID },
            set: { store.selectedCourseID = $0 }
        )
    }

    private var selectedCourseModules: [CourseModule] {
        store.modules(for: store.selectedCourseID)
    }

    private var selectedCourseAssignments: [CourseAssignment] {
        store.assignments(for: store.selectedCourseID)
    }

    private var isLoadingSelectedCourseModules: Bool {
        store.isLoadingModules(for: store.selectedCourseID)
    }

    private var isLoadingSelectedCourseAssignments: Bool {
        store.isLoadingAssignments(for: store.selectedCourseID)
    }

    private var hasLoadedSelectedCourseModules: Bool {
        store.hasLoadedModules(for: store.selectedCourseID)
    }

    private var hasLoadedSelectedCourseAssignments: Bool {
        store.hasLoadedAssignments(for: store.selectedCourseID)
    }

    private var selectedCourseUpcomingItems: [UpcomingEvent] {
        store.filteredUpcomingEvents(courseID: store.selectedCourseID)
    }

    private var selectedCourseMissingItems: [MissingSubmission] {
        store.filteredMissingSubmissions(courseID: store.selectedCourseID)
    }

    var body: some View {
        if !store.isConfigured {
            SetupPromptView(
                title: "Connect Canvas",
                message: "Save your Canvas credentials in Settings to open course workspaces and modules."
            )
        } else if store.courses.isEmpty {
            SetupPromptView(
                title: "No Courses Loaded",
                message: "Sync once to load the active courses available in your Canvas account."
            )
        } else {
            HStack(spacing: 0) {
                List(selection: selectedCourseBinding) {
                    ForEach(store.courses) { course in
                        CourseListRow(course: course)
                            .tag(Optional(course.id))
                    }
                }
                .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)

                Divider()

                if let selectedCourse = store.selectedCourse {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(selectedCourse.name)
                                        .font(.largeTitle.weight(.semibold))

                                    HStack(spacing: 12) {
                                        if let courseCode = selectedCourse.courseCode, !courseCode.isEmpty {
                                            Label(courseCode, systemImage: "number.square")
                                                .foregroundStyle(.secondary)
                                        }

                                        if let termName = selectedCourse.enrollmentTerm?.name, !termName.isEmpty {
                                            Label(termName, systemImage: "calendar")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .font(.subheadline)
                                }

                                Spacer()

                                if let htmlURL = selectedCourse.htmlURL {
                                    Link("Open in Canvas", destination: htmlURL)
                                }
                            }

                            Picker("Workspace", selection: $selectedSection) {
                                ForEach(CourseWorkspaceSection.allCases) { section in
                                    Text(section.rawValue)
                                        .tag(section)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 460)

                            switch selectedSection {
                            case .overview:
                                CourseOverviewContent(
                                    course: selectedCourse,
                                    hasLoadedAssignments: hasLoadedSelectedCourseAssignments,
                                    assignments: selectedCourseAssignments,
                                    hasLoadedModules: hasLoadedSelectedCourseModules,
                                    modules: selectedCourseModules,
                                    upcomingItems: selectedCourseUpcomingItems,
                                    missingItems: selectedCourseMissingItems
                                )
                            case .modules:
                                CourseModulesContent(
                                    course: selectedCourse,
                                    modules: selectedCourseModules,
                                    isLoading: isLoadingSelectedCourseModules
                                )
                            case .assignments:
                                CourseAssignmentsContent(
                                    course: selectedCourse,
                                    assignments: selectedCourseAssignments,
                                    isLoading: isLoadingSelectedCourseAssignments,
                                    filter: $assignmentFilter
                                )
                            case .grades:
                                CourseGradesContent(
                                    course: selectedCourse,
                                    assignments: selectedCourseAssignments,
                                    isLoading: isLoadingSelectedCourseAssignments
                                )
                            }
                        }
                        .padding(24)
                    }
                    .task(id: "\(selectedCourse.id)-\(selectedSection.rawValue)") {
                        switch selectedSection {
                        case .modules:
                            await store.loadModulesIfNeeded(for: selectedCourse.id)
                        case .assignments, .grades:
                            await store.loadAssignmentsIfNeeded(for: selectedCourse.id)
                        case .overview:
                            break
                        }
                    }
                } else {
                    SetupPromptView(
                        title: "Select a Course",
                        message: "Choose a course from the left to open its workspace."
                    )
                }
            }
        }
    }
}

private struct CourseOverviewContent: View {
    let course: Course
    let hasLoadedAssignments: Bool
    let assignments: [CourseAssignment]
    let hasLoadedModules: Bool
    let modules: [CourseModule]
    let upcomingItems: [UpcomingEvent]
    let missingItems: [MissingSubmission]

    private let summaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var nextDeadline: UpcomingEvent? {
        upcomingItems.first(where: { event in
            guard let date = event.displayDate else {
                return false
            }

            return date >= Date()
        })
    }

    private var gradedAssignmentsCount: Int {
        assignments.filter { $0.submission?.isGraded == true }.count
    }

    private var gradeHeadline: String {
        if let displayGrade = course.studentEnrollment?.displayCurrentGrade {
            return displayGrade
        }

        if hasLoadedAssignments, let weightedAverage {
            return weightedAverage
        }

        return hasLoadedAssignments ? "Hidden" : "Load"
    }

    private var weightedAverage: String? {
        let totals = assignments.reduce(into: (earned: 0.0, possible: 0.0)) { partialResult, assignment in
            guard
                let score = assignment.submission?.score,
                let pointsPossible = assignment.pointsPossible,
                pointsPossible > 0
            else {
                return
            }

            partialResult.earned += score
            partialResult.possible += pointsPossible
        }

        guard totals.possible > 0 else {
            return nil
        }

        let percentage = (totals.earned / totals.possible) * 100

        if percentage.rounded() == percentage {
            return "\(Int(percentage))%"
        }

        return String(format: "%.1f%%", percentage)
    }

    var body: some View {
        LazyVGrid(columns: summaryColumns, spacing: 12) {
            SummaryCard(
                title: "Upcoming",
                value: "\(upcomingItems.count)",
                detail: "Assignments and events attached to this course.",
                systemImage: "calendar.badge.clock",
                tint: .blue
            )

            SummaryCard(
                title: "Missing",
                value: "\(missingItems.count)",
                detail: "Past-due items that still need attention.",
                systemImage: "exclamationmark.circle",
                tint: .red
            )

            SummaryCard(
                title: "Modules",
                value: hasLoadedModules ? "\(modules.count)" : "Load",
                detail: hasLoadedModules ? "Canvas modules available in this course." : "Open the Modules tab to load the course structure.",
                systemImage: "square.grid.2x2",
                tint: .green
            )

            SummaryCard(
                title: "Assignments",
                value: hasLoadedAssignments ? "\(assignments.count)" : "Load",
                detail: hasLoadedAssignments ? "\(gradedAssignmentsCount) graded items are ready to review." : "Open Assignments or Grades to load coursework.",
                systemImage: "checklist",
                tint: .mint
            )

            SummaryCard(
                title: "Current Grade",
                value: gradeHeadline,
                detail: course.studentEnrollment?.displayCurrentScore.map { "Current score \($0)." } ?? "Uses Canvas totals when available.",
                systemImage: "chart.bar.doc.horizontal",
                tint: .orange
            )

            SummaryCard(
                title: "Next Deadline",
                value: nextDeadline.flatMap { DisplayFormatters.relativeString(date: $0.displayDate) } ?? "Clear",
                detail: nextDeadline?.title ?? "No upcoming deadlines found for this course.",
                systemImage: "flag",
                tint: .teal
            )
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming In This Course")
                .font(.title2.weight(.semibold))

            if upcomingItems.isEmpty {
                Text("No upcoming assignments or events are scheduled right now.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(upcomingItems.prefix(6))) { event in
                    UpcomingEventRow(event: event, courseName: course.name)

                    if event.id != upcomingItems.prefix(6).last?.id {
                        Divider()
                    }
                }
            }
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Missing In This Course")
                .font(.title2.weight(.semibold))

            if missingItems.isEmpty {
                Text("Nothing overdue in this course.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(missingItems.prefix(5))) { item in
                    MissingSubmissionRow(submission: item, courseName: course.name)

                    if item.id != missingItems.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct CourseModulesContent: View {
    @EnvironmentObject private var store: CanvasStore

    let course: Course
    let modules: [CourseModule]
    let isLoading: Bool

    var body: some View {
        HStack {
            Text("Modules")
                .font(.title2.weight(.semibold))

            Spacer()

            Button("Refresh Modules") {
                Task {
                    await store.loadModules(for: course.id)
                }
            }
        }

        if isLoading {
            ProgressView("Loading modules...")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
        } else if modules.isEmpty {
            SetupPromptView(
                title: "No Modules Yet",
                message: "If this course uses Canvas Modules, they will appear here after loading."
            )
        } else {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(modules) { module in
                    CourseModuleCard(module: module)
                }
            }
        }
    }
}

private struct CourseAssignmentsContent: View {
    @EnvironmentObject private var store: CanvasStore

    let course: Course
    let assignments: [CourseAssignment]
    let isLoading: Bool
    @Binding var filter: CourseAssignmentFilter

    private let summaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredAssignments: [CourseAssignment] {
        assignments.filter { filter.includes($0) }
    }

    private var completedCount: Int {
        assignments.filter { $0.isCompleted }.count
    }

    private var missingCount: Int {
        assignments.filter { $0.status == .missing || $0.status == .late }.count
    }

    private var upcomingCount: Int {
        assignments.filter { $0.isUpcoming }.count
    }

    var body: some View {
        HStack {
            Text("Assignments")
                .font(.title2.weight(.semibold))

            Spacer()

            Button("Refresh Assignments") {
                Task {
                    await store.loadAssignments(for: course.id)
                }
            }
        }

        LazyVGrid(columns: summaryColumns, spacing: 12) {
            SummaryCard(
                title: "All Work",
                value: "\(assignments.count)",
                detail: "Assignments currently published in this course.",
                systemImage: "doc.text",
                tint: .blue
            )

            SummaryCard(
                title: "Upcoming",
                value: "\(upcomingCount)",
                detail: "Assignments still open and not yet submitted.",
                systemImage: "calendar",
                tint: .orange
            )

            SummaryCard(
                title: "Missing",
                value: "\(missingCount)",
                detail: "Items that Canvas marks as overdue or late.",
                systemImage: "exclamationmark.circle",
                tint: .red
            )

            SummaryCard(
                title: "Completed",
                value: "\(completedCount)",
                detail: "Submitted, graded, or excused work.",
                systemImage: "checkmark.circle",
                tint: .green
            )
        }

        Picker("Filter", selection: $filter) {
            ForEach(CourseAssignmentFilter.allCases) { option in
                Text(option.rawValue)
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 420)

        if isLoading && assignments.isEmpty {
            ProgressView("Loading assignments...")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
        } else if assignments.isEmpty {
            SetupPromptView(
                title: "No Assignments Yet",
                message: "Canvas has not returned any assignments for this course."
            )
        } else if filteredAssignments.isEmpty {
            SetupPromptView(
                title: "No Matching Work",
                message: "Change the filter to review a different slice of this course."
            )
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(filteredAssignments) { assignment in
                    CourseAssignmentRow(assignment: assignment, courseName: course.name)

                    if assignment.id != filteredAssignments.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct CourseGradesContent: View {
    @EnvironmentObject private var store: CanvasStore

    let course: Course
    let assignments: [CourseAssignment]
    let isLoading: Bool

    private let summaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var enrollment: CourseEnrollment? {
        course.studentEnrollment
    }

    private var gradedAssignments: [CourseAssignment] {
        assignments
            .filter { $0.submission?.isGraded == true }
            .sorted { lhs, rhs in
                switch (lhs.recentActivityDate, rhs.recentActivityDate) {
                case let (left?, right?):
                    if left != right {
                        return left > right
                    }
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    break
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private var outstandingCount: Int {
        assignments.filter { $0.status == .missing || $0.status == .late || $0.isUpcoming }.count
    }

    private var gradedTotals: (earned: Double, possible: Double) {
        assignments.reduce(into: (earned: 0.0, possible: 0.0)) { partialResult, assignment in
            guard
                let score = assignment.submission?.score,
                let pointsPossible = assignment.pointsPossible,
                pointsPossible > 0
            else {
                return
            }

            partialResult.earned += score
            partialResult.possible += pointsPossible
        }
    }

    private var weightedScoreLabel: String? {
        guard gradedTotals.possible > 0 else {
            return nil
        }

        let percentage = (gradedTotals.earned / gradedTotals.possible) * 100

        if percentage.rounded() == percentage {
            return "\(Int(percentage))%"
        }

        return String(format: "%.1f%%", percentage)
    }

    private var totalEarnedPointsLabel: String? {
        guard gradedTotals.possible > 0 else {
            return nil
        }

        let earned = DisplayFormatters.formattedPoints(gradedTotals.earned) ?? "\(gradedTotals.earned)"
        let possible = DisplayFormatters.formattedPoints(gradedTotals.possible) ?? "\(gradedTotals.possible)"
        return "\(earned) / \(possible)"
    }

    var body: some View {
        HStack {
            Text("Grades")
                .font(.title2.weight(.semibold))

            Spacer()

            Button("Refresh Grades") {
                Task {
                    await store.loadAssignments(for: course.id)
                }
            }
        }

        LazyVGrid(columns: summaryColumns, spacing: 12) {
            SummaryCard(
                title: "Current Grade",
                value: enrollment?.displayCurrentGrade ?? weightedScoreLabel ?? "Hidden",
                detail: enrollment?.displayFinalGrade.map { "Final grade \($0)." } ?? "Falls back to graded assignments when Canvas hides totals.",
                systemImage: "graduationcap",
                tint: .green
            )

            SummaryCard(
                title: "Current Score",
                value: enrollment?.displayCurrentScore ?? totalEarnedPointsLabel ?? "Pending",
                detail: totalEarnedPointsLabel.map { "\($0) graded points recorded." } ?? "Scores will appear after graded work is returned.",
                systemImage: "number.square",
                tint: .blue
            )

            SummaryCard(
                title: "Graded Items",
                value: "\(gradedAssignments.count)",
                detail: "Assignments with posted scores or grades.",
                systemImage: "checkmark.circle",
                tint: .orange
            )

            SummaryCard(
                title: "Need Attention",
                value: "\(outstandingCount)",
                detail: "Missing, late, or still-upcoming coursework.",
                systemImage: "flag",
                tint: .red
            )
        }

        if let gradingPeriodTitle = enrollment?.currentGradingPeriodTitle,
           let gradingPeriodGrade = enrollment?.displayCurrentPeriodGrade {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Grading Period")
                    .font(.headline)

                Text("\(gradingPeriodTitle): \(gradingPeriodGrade)\(enrollment?.displayCurrentPeriodScore.map { " (\($0))" } ?? "")")
                    .foregroundStyle(.secondary)
            }
        }

        if isLoading && assignments.isEmpty {
            ProgressView("Loading grades...")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
        } else if gradedAssignments.isEmpty {
            SetupPromptView(
                title: "No Grades Posted",
                message: "Canvas has not returned any graded assignments for this course yet."
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Scores")
                    .font(.title2.weight(.semibold))

                ForEach(gradedAssignments.prefix(10)) { assignment in
                    CourseAssignmentRow(assignment: assignment, courseName: course.name)

                    if assignment.id != gradedAssignments.prefix(10).last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

struct CoursesView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesView()
            .environmentObject(CanvasStore())
    }
}
