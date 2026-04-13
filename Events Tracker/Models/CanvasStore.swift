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
    @Published private(set) var upcomingEvents: [UpcomingEvent]
    @Published private(set) var missingSubmissions: [MissingSubmission]
    @Published private(set) var profile: UserProfile?
    @Published private(set) var lastSyncedAt: Date?
    @Published var selectedCourseID: Int?
    @Published var isSyncing = false
    @Published var errorMessage: String?

    private let configManager: CanvasConfigManager
    private let databaseManager: DatabaseManager
    private let networkManager: NetworkManager
    private let relativeFormatter = RelativeDateTimeFormatter()

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

        if let snapshot = databaseManager.loadSnapshot() {
            courses = snapshot.courses
            upcomingEvents = snapshot.upcomingEvents
            missingSubmissions = snapshot.missingSubmissions
            profile = snapshot.profile
            lastSyncedAt = snapshot.syncedAt
        } else {
            courses = []
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
            try databaseManager.saveSnapshot(snapshot)
        } catch {
            errorMessage = error.localizedDescription
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
