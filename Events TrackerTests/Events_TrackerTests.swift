//
//  Events_TrackerTests.swift
//  Events TrackerTests
//
//  Created by Eddie Gao on 24/3/25.
//

import Foundation
import Testing
@testable import Events_Tracker

struct Events_TrackerTests {
    @Test func configNormalizationTrimsWhitespace() async throws {
        let config = CanvasConfig(
            baseURL: " https://canvas.example.edu/ ",
            token: " abc123 ",
            lookaheadDays: 21
        )

        #expect(config.normalizedBaseURL == "https://canvas.example.edu")
        #expect(config.trimmedToken == "abc123")
        #expect(config.isComplete)
    }

    @Test func upcomingEventPrefersAssignmentDueDate() async throws {
        let dueDate = Date(timeIntervalSince1970: 1_710_000_000)
        let startDate = Date(timeIntervalSince1970: 1_709_000_000)

        let event = UpcomingEvent(
            id: "assignment_42",
            title: "Lab Report",
            details: nil,
            startAt: startDate,
            endAt: startDate,
            allDay: false,
            contextCode: "course_99",
            htmlURL: nil,
            workflowState: "published",
            assignment: CanvasAssignment(
                id: 42,
                name: "Lab Report",
                dueAt: dueDate,
                courseID: 99,
                htmlURL: nil,
                pointsPossible: 100
            )
        )

        #expect(event.displayDate == dueDate)
        #expect(event.courseID == 99)
        #expect(event.kindLabel == "Assignment")
    }

    @Test func moduleItemPrefersContentDetailURLAndMapsTypeIcon() async throws {
        let moduleItem = CourseModuleItem(
            id: 12,
            moduleID: 4,
            position: 1,
            title: "Week 1 Quiz",
            indent: 0,
            type: "Quiz",
            contentID: 77,
            htmlURL: URL(string: "https://canvas.example.edu/modules/items/12"),
            apiURL: nil,
            pageURL: nil,
            published: true,
            contentDetails: ModuleItemContentDetails(
                pointsPossible: 25,
                dueAt: nil,
                unlockAt: nil,
                lockAt: nil,
                lockedForUser: false,
                lockExplanation: nil,
                htmlURL: URL(string: "https://canvas.example.edu/courses/1/quizzes/77")
            )
        )

        #expect(moduleItem.actionableURL?.absoluteString == "https://canvas.example.edu/courses/1/quizzes/77")
        #expect(moduleItem.systemImageName == "checklist")
        #expect(moduleItem.pointsDescription == "25 pts")
    }

    @Test func courseStudentEnrollmentPrefersStudentScores() async throws {
        let course = Course(
            id: 14,
            name: "Biology",
            courseCode: "BIO-101",
            workflowState: "available",
            htmlURL: nil,
            enrollmentTerm: EnrollmentTerm(name: "Spring"),
            enrollments: [
                CourseEnrollment(
                    type: "TeacherEnrollment",
                    role: "TeacherEnrollment",
                    enrollmentState: "active",
                    computedCurrentScore: nil,
                    computedCurrentGrade: nil,
                    computedFinalScore: nil,
                    computedFinalGrade: nil,
                    currentGradingPeriodTitle: nil,
                    hasGradingPeriods: nil,
                    currentPeriodComputedCurrentScore: nil,
                    currentPeriodComputedCurrentGrade: nil,
                    currentPeriodComputedFinalScore: nil,
                    currentPeriodComputedFinalGrade: nil
                ),
                CourseEnrollment(
                    type: "StudentEnrollment",
                    role: "StudentEnrollment",
                    enrollmentState: "active",
                    computedCurrentScore: 94.5,
                    computedCurrentGrade: "A",
                    computedFinalScore: 93.8,
                    computedFinalGrade: "A",
                    currentGradingPeriodTitle: "Unit 2",
                    hasGradingPeriods: true,
                    currentPeriodComputedCurrentScore: 96,
                    currentPeriodComputedCurrentGrade: "A",
                    currentPeriodComputedFinalScore: 96,
                    currentPeriodComputedFinalGrade: "A"
                )
            ]
        )

        #expect(course.studentEnrollment?.isStudentEnrollment == true)
        #expect(course.studentEnrollment?.displayCurrentGrade == "A")
        #expect(course.studentEnrollment?.displayCurrentScore == "94.5%")
        #expect(course.studentEnrollment?.displayCurrentPeriodScore == "96%")
    }

    @Test func courseAssignmentBuildsSubmissionSummaryAndStatus() async throws {
        let assignment = CourseAssignment(
            id: 77,
            name: "Essay Draft",
            details: "<p>Upload a <strong>draft</strong> before peer review.</p>",
            dueAt: Date(timeIntervalSinceNow: 3_600),
            unlockAt: nil,
            lockAt: nil,
            htmlURL: URL(string: "https://canvas.example.edu/courses/1/assignments/77"),
            courseID: 1,
            pointsPossible: 50,
            submissionTypes: ["online_upload"],
            hasSubmittedSubmissions: true,
            published: true,
            gradingType: "points",
            submission: AssignmentSubmission(
                submittedAt: Date(),
                gradedAt: Date(),
                score: 47.5,
                grade: "95%",
                workflowState: "graded",
                late: false,
                missing: false,
                excused: false,
                submissionType: "online_upload",
                attempt: 1
            )
        )

        #expect(assignment.status == CourseAssignmentStatus.graded)
        #expect(assignment.isCompleted)
        #expect(assignment.summaryText == "Upload a draft before peer review.")
        #expect(assignment.scoreDescription == "47.5 / 50")
        #expect(assignment.gradeDescription == "95%")
    }
}
