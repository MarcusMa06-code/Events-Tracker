//
//  UnifiedTask.swift
//  Events Tracker
//
//  A unified task model merging UpcomingEvent + MissingSubmission
//  for use in the triage board and events screen.
//

import Foundation

enum TaskKind: String {
    case assignment, event, exam, quiz, missing
}

enum TaskStatus: String {
    case todo, missing, submitted, graded
}

struct UnifiedTask: Identifiable, Hashable {
    let id: String
    let title: String
    let dueDate: Date?
    let courseID: Int?
    let kind: TaskKind
    var status: TaskStatus
    let points: Double?
    var isPinned: Bool
    let htmlURL: URL?

    var bucket: TaskBucket {
        guard let dueDate else { return .later }
        if status == .missing { return .overdue }
        return taskBucket(for: dueDate)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: UnifiedTask, rhs: UnifiedTask) -> Bool { lhs.id == rhs.id }
}

// MARK: - Factory

extension UnifiedTask {
    init(from event: UpcomingEvent) {
        self.id = "evt-\(event.id)"
        self.title = event.title
        self.dueDate = event.displayDate
        self.courseID = event.courseID
        self.kind = UnifiedTask.inferKind(title: event.title, isAssignment: event.isAssignment)
        self.status = .todo
        self.points = event.assignment?.pointsPossible
        self.isPinned = false
        self.htmlURL = event.actionableURL
    }

    init(from missing: MissingSubmission) {
        self.id = "mis-\(missing.id)"
        self.title = missing.name
        self.dueDate = missing.dueAt
        self.courseID = missing.courseID
        self.kind = UnifiedTask.inferKind(title: missing.name, isAssignment: true)
        self.status = .missing
        self.points = missing.pointsPossible
        self.isPinned = false
        self.htmlURL = missing.htmlURL
    }

    private static func inferKind(title: String, isAssignment: Bool) -> TaskKind {
        let lower = title.lowercased()
        if lower.contains("exam") || lower.contains("final") || lower.contains("midterm") { return .exam }
        if lower.contains("quiz") { return .quiz }
        if isAssignment { return .assignment }
        return .event
    }
}
