//
//  DataStructure.swift
//  Events Tracker
//
//  Created by Eddie Gao on 1/4/25.
//

import Foundation

struct CanvasConfig: Codable, Equatable {
    var baseURL: String = ""
    var token: String = ""
    var lookaheadDays: Int = 14

    var normalizedBaseURL: String {
        baseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
    }

    var trimmedToken: String {
        token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isComplete: Bool {
        !normalizedBaseURL.isEmpty && !trimmedToken.isEmpty
    }
}

struct EnrollmentTerm: Codable, Hashable {
    let name: String?
}

struct Course: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let courseCode: String?
    let workflowState: String?
    let htmlURL: URL?
    let enrollmentTerm: EnrollmentTerm?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case courseCode = "course_code"
        case workflowState = "workflow_state"
        case htmlURL = "html_url"
        case enrollmentTerm = "term"
    }
}

struct CanvasAssignment: Codable, Hashable {
    let id: Int
    let name: String
    let dueAt: Date?
    let courseID: Int?
    let htmlURL: URL?
    let pointsPossible: Double?

    init(
        id: Int,
        name: String,
        dueAt: Date?,
        courseID: Int?,
        htmlURL: URL?,
        pointsPossible: Double?
    ) {
        self.id = id
        self.name = name
        self.dueAt = dueAt
        self.courseID = courseID
        self.htmlURL = htmlURL
        self.pointsPossible = pointsPossible
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case dueAt = "due_at"
        case courseID = "course_id"
        case htmlURL = "html_url"
        case pointsPossible = "points_possible"
    }
}

struct UpcomingEvent: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let details: String?
    let startAt: Date?
    let endAt: Date?
    let allDay: Bool
    let contextCode: String?
    let htmlURL: URL?
    let workflowState: String?
    let assignment: CanvasAssignment?

    init(
        id: String,
        title: String,
        details: String?,
        startAt: Date?,
        endAt: Date?,
        allDay: Bool,
        contextCode: String?,
        htmlURL: URL?,
        workflowState: String?,
        assignment: CanvasAssignment?
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.startAt = startAt
        self.endAt = endAt
        self.allDay = allDay
        self.contextCode = contextCode
        self.htmlURL = htmlURL
        self.workflowState = workflowState
        self.assignment = assignment
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case details = "description"
        case startAt = "start_at"
        case endAt = "end_at"
        case allDay = "all_day"
        case contextCode = "context_code"
        case htmlURL = "html_url"
        case workflowState = "workflow_state"
        case assignment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(FlexibleIdentifier.self, forKey: .id).stringValue
        title = try container.decode(String.self, forKey: .title)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        startAt = try container.decodeIfPresent(Date.self, forKey: .startAt)
        endAt = try container.decodeIfPresent(Date.self, forKey: .endAt)
        allDay = try container.decodeIfPresent(Bool.self, forKey: .allDay) ?? false
        contextCode = try container.decodeIfPresent(String.self, forKey: .contextCode)
        htmlURL = try container.decodeIfPresent(URL.self, forKey: .htmlURL)
        workflowState = try container.decodeIfPresent(String.self, forKey: .workflowState)
        assignment = try container.decodeIfPresent(CanvasAssignment.self, forKey: .assignment)
    }

    var courseID: Int? {
        if let courseID = assignment?.courseID {
            return courseID
        }

        guard let contextCode, contextCode.hasPrefix("course_") else {
            return nil
        }

        return Int(contextCode.replacingOccurrences(of: "course_", with: ""))
    }

    var actionableURL: URL? {
        assignment?.htmlURL ?? htmlURL
    }

    var displayDate: Date? {
        assignment?.dueAt ?? endAt ?? startAt
    }

    var isAssignment: Bool {
        assignment != nil
    }

    var kindLabel: String {
        isAssignment ? "Assignment" : "Event"
    }
}

struct MissingSubmission: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let dueAt: Date?
    let courseID: Int?
    let htmlURL: URL?
    let pointsPossible: Double?

    init(
        id: Int,
        name: String,
        dueAt: Date?,
        courseID: Int?,
        htmlURL: URL?,
        pointsPossible: Double?
    ) {
        self.id = id
        self.name = name
        self.dueAt = dueAt
        self.courseID = courseID
        self.htmlURL = htmlURL
        self.pointsPossible = pointsPossible
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case dueAt = "due_at"
        case courseID = "course_id"
        case htmlURL = "html_url"
        case pointsPossible = "points_possible"
    }
}

struct UserProfile: Codable, Hashable {
    let id: Int
    let name: String
    let shortName: String?
    let primaryEmail: String?
    let loginID: String?
    let avatarURL: URL?
    let title: String?
    let bio: String?
    let timeZone: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
        case primaryEmail = "primary_email"
        case loginID = "login_id"
        case avatarURL = "avatar_url"
        case title
        case bio
        case timeZone = "time_zone"
    }
}

struct CanvasSnapshot: Codable {
    let courses: [Course]
    let upcomingEvents: [UpcomingEvent]
    let missingSubmissions: [MissingSubmission]
    let profile: UserProfile?
    let syncedAt: Date
}

private struct FlexibleIdentifier: Decodable {
    let stringValue: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            stringValue = String(intValue)
            return
        }

        stringValue = try container.decode(String.self)
    }
}
