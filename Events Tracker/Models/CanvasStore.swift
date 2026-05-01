//
//  CanvasStore.swift
//  Events Tracker
//
//  Created by Codex on 13/4/26.
//

import Combine
import Foundation

@MainActor
final class CanvasStore: ObservableObject {
    @Published var config: CanvasConfig
    @Published private(set) var courses: [Course]
    @Published private(set) var courseAssignmentsByCourseID: [Int: [CourseAssignment]]
    @Published private(set) var loadingCourseAssignmentIDs: Set<Int>
    @Published private(set) var courseModulesByCourseID: [Int: [CourseModule]]
    @Published private(set) var loadingCourseModuleIDs: Set<Int>
    @Published private(set) var upcomingEvents: [UpcomingEvent]
    @Published private(set) var missingSubmissions: [MissingSubmission]
    @Published private(set) var profile: UserProfile?
    @Published private(set) var lastSyncedAt: Date?
    @Published var selectedCourseID: Int?
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var pinnedTaskIDs: Set<String>
    @Published var hiddenCourseIDs: Set<Int>

    private let configManager: CanvasConfigManager
    private let databaseManager: DatabaseManager
    private let networkManager: NetworkManager
    private let relativeFormatter = RelativeDateTimeFormatter()
    private let pinnedKey = "pinnedTaskIDs"
    private let hiddenCoursesKey = "hiddenCourseIDs"

    init(
        configManager: CanvasConfigManager = .shared,
        databaseManager: DatabaseManager = .shared,
        networkManager: NetworkManager = .shared
    ) {
        self.configManager = configManager
        self.databaseManager = databaseManager
        self.networkManager = networkManager

        let savedConfig = configManager.loadConfig()
        config = savedConfig

        // Initialize pinned IDs before snapshot loading
        if let saved = UserDefaults.standard.array(forKey: "pinnedTaskIDs") as? [String] {
            pinnedTaskIDs = Set(saved)
        } else {
            pinnedTaskIDs = []
        }
        if let saved = UserDefaults.standard.array(forKey: "hiddenCourseIDs") as? [Int] {
            hiddenCourseIDs = Set(saved)
        } else {
            hiddenCourseIDs = []
        }

        if let snapshot = databaseManager.loadSnapshot() {
            courses = snapshot.courses
            courseAssignmentsByCourseID = [:]
            loadingCourseAssignmentIDs = []
            courseModulesByCourseID = [:]
            loadingCourseModuleIDs = []
            upcomingEvents = snapshot.upcomingEvents
            missingSubmissions = snapshot.missingSubmissions
            profile = snapshot.profile
            lastSyncedAt = snapshot.syncedAt
        } else {
            courses = []
            courseAssignmentsByCourseID = [:]
            loadingCourseAssignmentIDs = []
            courseModulesByCourseID = [:]
            loadingCourseModuleIDs = []
            upcomingEvents = []
            missingSubmissions = []
            profile = nil
            lastSyncedAt = nil
        }

        selectedCourseID = courses.first?.id
        relativeFormatter.unitsStyle = .full
    }

    var isConfigured: Bool {
        config.isComplete
    }

    var nextUpcomingEvent: UpcomingEvent? {
        upcomingEvents.first(where: { event in
            guard let date = event.displayDate else {
                return false
            }

            return date >= Date()
        })
    }

    var eventsDueThisWeekCount: Int {
        let now = Date()
        guard let endOfWindow = Calendar.current.date(byAdding: .day, value: 7, to: now) else {
            return 0
        }

        return upcomingEvents.filter { event in
            guard let date = event.displayDate else {
                return false
            }

            return date >= now && date <= endOfWindow
        }.count
    }

    var selectedCourseName: String? {
        courseName(for: selectedCourseID)
    }

    var selectedCourse: Course? {
        guard let selectedCourseID else {
            return nil
        }

        return courses.first(where: { $0.id == selectedCourseID })
    }

    var hostLabel: String {
        URL(string: config.normalizedBaseURL)?.host ?? config.normalizedBaseURL
    }

    var lastSyncDescription: String? {
        guard let lastSyncedAt else {
            return nil
        }

        return relativeFormatter.localizedString(for: lastSyncedAt, relativeTo: Date())
    }

    func refreshIfNeeded() async {
        guard isConfigured, courses.isEmpty, upcomingEvents.isEmpty, missingSubmissions.isEmpty else {
            return
        }

        await refresh()
    }

    func refresh() async {
        guard config.isComplete else {
            errorMessage = CanvasServiceError.incompleteConfiguration.localizedDescription
            return
        }

        isSyncing = true
        errorMessage = nil

        do {
            let snapshot = try await networkManager.fetchDashboardSnapshot(using: config)
            applySnapshot(snapshot)
            courseAssignmentsByCourseID = [:]
            loadingCourseAssignmentIDs = []
            courseModulesByCourseID = [:]
            loadingCourseModuleIDs = []
            try databaseManager.saveSnapshot(snapshot)
        } catch {
            if !isCancellation(error) { errorMessage = error.localizedDescription }
        }

        isSyncing = false
    }

    @discardableResult
    func saveConfiguration(baseURL: String, token: String, lookaheadDays: Int) throws -> Bool {
        let updatedConfig = CanvasConfig(
            baseURL: baseURL,
            token: token,
            lookaheadDays: lookaheadDays
        )

        let credentialsChanged = updatedConfig.normalizedBaseURL != config.normalizedBaseURL
            || updatedConfig.trimmedToken != config.trimmedToken

        try configManager.saveConfig(updatedConfig)
        config = updatedConfig
        errorMessage = nil

        if credentialsChanged {
            clearLocalData()
        }

        return credentialsChanged
    }

    func clearLocalData() {
        courses = []
        courseAssignmentsByCourseID = [:]
        loadingCourseAssignmentIDs = []
        courseModulesByCourseID = [:]
        loadingCourseModuleIDs = []
        upcomingEvents = []
        missingSubmissions = []
        profile = nil
        lastSyncedAt = nil
        selectedCourseID = nil

        do {
            try databaseManager.clearSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func courseName(for courseID: Int?) -> String? {
        guard let courseID else {
            return nil
        }

        return courses.first(where: { $0.id == courseID })?.name
    }

    func filteredUpcomingEvents(courseID: Int?) -> [UpcomingEvent] {
        guard let courseID else {
            return upcomingEvents
        }

        return upcomingEvents.filter { $0.courseID == courseID }
    }

    func filteredMissingSubmissions(courseID: Int?) -> [MissingSubmission] {
        guard let courseID else {
            return missingSubmissions
        }

        return missingSubmissions.filter { $0.courseID == courseID }
    }

    // MARK: - Unified Tasks (for redesigned Dashboard + Events views)

    func unifiedTasks(courseID: Int? = nil) -> [UnifiedTask] {
        var tasks: [UnifiedTask] = []

        for event in upcomingEvents {
            if let cid = courseID, event.courseID != cid { continue }
            var task = UnifiedTask(from: event)
            task.isPinned = pinnedTaskIDs.contains(task.id)
            tasks.append(task)
        }

        for missing in missingSubmissions {
            if let cid = courseID, missing.courseID != cid { continue }
            let evtID = "evt-\(missing.id)"
            if tasks.contains(where: { $0.id == evtID }) { continue }
            var task = UnifiedTask(from: missing)
            task.isPinned = pinnedTaskIDs.contains(task.id)
            tasks.append(task)
        }

        tasks.sort { a, b in
            let da = a.dueDate ?? .distantFuture
            let db = b.dueDate ?? .distantFuture
            return da < db
        }

        return tasks
    }

    func togglePin(_ taskID: String) {
        if pinnedTaskIDs.contains(taskID) {
            pinnedTaskIDs.remove(taskID)
        } else {
            pinnedTaskIDs.insert(taskID)
        }
        UserDefaults.standard.set(Array(pinnedTaskIDs), forKey: pinnedKey)
    }

    var visibleCourses: [Course] {
        courses.filter { !hiddenCourseIDs.contains($0.id) }
    }

    func toggleCourseVisibility(_ courseID: Int) {
        if hiddenCourseIDs.contains(courseID) {
            hiddenCourseIDs.remove(courseID)
        } else {
            hiddenCourseIDs.insert(courseID)
        }
        UserDefaults.standard.set(Array(hiddenCourseIDs), forKey: hiddenCoursesKey)
    }

    var overdueCount: Int {
        let now = Date()
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: now)
        let overdueMissing = missingSubmissions.count
        let overdueEvents = upcomingEvents.filter { event in
            guard let d = event.displayDate else { return false }
            return cal.startOfDay(for: d) < todayStart
        }.count
        return overdueMissing + overdueEvents
    }

    var todayTaskCount: Int {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        guard let todayEnd = cal.date(byAdding: .day, value: 1, to: todayStart) else { return 0 }
        return upcomingEvents.filter { event in
            guard let d = event.displayDate else { return false }
            return d >= todayStart && d < todayEnd
        }.count
    }

    var thisWeekTaskCount: Int {
        let cal = Calendar.current
        let now = Date()
        guard let weekEnd = cal.date(byAdding: .day, value: 7, to: now) else { return 0 }
        let events = upcomingEvents.filter { event in
            guard let d = event.displayDate else { return false }
            return d >= now && d <= weekEnd
        }.count
        return events + missingSubmissions.count
    }

    var upcomingExamCount: Int {
        upcomingEvents.filter { event in
            let lower = event.title.lowercased()
            guard let d = event.displayDate, d >= Date() else { return false }
            return lower.contains("exam") || lower.contains("final") || lower.contains("midterm")
        }.count
    }

    func taskCount(for courseID: Int) -> Int {
        let events = upcomingEvents.filter { $0.courseID == courseID }.count
        let missing = missingSubmissions.filter { $0.courseID == courseID }.count
        return events + missing
    }

    func modules(for courseID: Int?) -> [CourseModule] {
        guard let courseID else {
            return []
        }

        return courseModulesByCourseID[courseID] ?? []
    }

    func assignments(for courseID: Int?) -> [CourseAssignment] {
        guard let courseID else {
            return []
        }

        return courseAssignmentsByCourseID[courseID] ?? []
    }

    func hasLoadedAssignments(for courseID: Int?) -> Bool {
        guard let courseID else {
            return false
        }

        return courseAssignmentsByCourseID[courseID] != nil
    }

    func isLoadingAssignments(for courseID: Int?) -> Bool {
        guard let courseID else {
            return false
        }

        return loadingCourseAssignmentIDs.contains(courseID)
    }

    func loadAssignmentsIfNeeded(for courseID: Int?) async {
        guard
            let courseID,
            courseAssignmentsByCourseID[courseID] == nil,
            !loadingCourseAssignmentIDs.contains(courseID)
        else {
            return
        }

        await loadAssignments(for: courseID)
    }

    func loadAssignments(for courseID: Int) async {
        guard config.isComplete else {
            errorMessage = CanvasServiceError.incompleteConfiguration.localizedDescription
            return
        }

        loadingCourseAssignmentIDs.insert(courseID)

        do {
            let assignments = try await networkManager.fetchAssignments(courseID: courseID, using: config)
            courseAssignmentsByCourseID[courseID] = assignments
        } catch {
            if !isCancellation(error) { errorMessage = error.localizedDescription }
        }

        loadingCourseAssignmentIDs.remove(courseID)
    }

    func hasLoadedModules(for courseID: Int?) -> Bool {
        guard let courseID else {
            return false
        }

        return courseModulesByCourseID[courseID] != nil
    }

    func isLoadingModules(for courseID: Int?) -> Bool {
        guard let courseID else {
            return false
        }

        return loadingCourseModuleIDs.contains(courseID)
    }

    func loadModulesIfNeeded(for courseID: Int?) async {
        guard
            let courseID,
            courseModulesByCourseID[courseID] == nil,
            !loadingCourseModuleIDs.contains(courseID)
        else {
            return
        }

        await loadModules(for: courseID)
    }

    func loadModules(for courseID: Int) async {
        guard config.isComplete else {
            errorMessage = CanvasServiceError.incompleteConfiguration.localizedDescription
            return
        }

        loadingCourseModuleIDs.insert(courseID)

        do {
            let modules = try await networkManager.fetchModules(courseID: courseID, using: config)
            courseModulesByCourseID[courseID] = modules
        } catch {
            if !isCancellation(error) { errorMessage = error.localizedDescription }
        }

        loadingCourseModuleIDs.remove(courseID)
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled
            || (error as NSError).code == NSURLErrorCancelled
            || error is CancellationError
    }

    private func applySnapshot(_ snapshot: CanvasSnapshot) {
        courses = snapshot.courses
        upcomingEvents = snapshot.upcomingEvents
        missingSubmissions = snapshot.missingSubmissions
        profile = snapshot.profile
        lastSyncedAt = snapshot.syncedAt

        if let selectedCourseID, courses.contains(where: { $0.id == selectedCourseID }) {
            return
        }

        self.selectedCourseID = courses.first?.id
    }
}
