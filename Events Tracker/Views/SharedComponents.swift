//
//  SharedComponents.swift
//  Events Tracker
//
//  Created by Codex on 13/4/26.
//

import SwiftUI

enum DisplayFormatters {
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    static func formatted(date: Date?, allDay: Bool = false) -> String {
        guard let date else {
            return "No scheduled date"
        }

        if allDay {
            return dateOnly.string(from: date)
        }

        return dateTime.string(from: date)
    }

    static func relativeString(date: Date?) -> String? {
        guard let date else {
            return nil
        }

        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SetupPromptView: View {
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "link.badge.plus",
            description: Text(message)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct PillBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}

struct UpcomingEventRow: View {
    let event: UpcomingEvent
    let courseName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)

                    if let courseName {
                        Text(courseName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let details = event.details, !details.isEmpty {
                        Text(details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                PillBadge(
                    text: event.kindLabel,
                    tint: event.isAssignment ? .blue : .green
                )
            }

            HStack(spacing: 12) {
                Label(
                    DisplayFormatters.formatted(date: event.displayDate, allDay: event.allDay),
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if let relative = DisplayFormatters.relativeString(date: event.displayDate) {
                    Text(relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let url = event.actionableURL {
                    Link("Open in Canvas", destination: url)
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct MissingSubmissionRow: View {
    let submission: MissingSubmission
    let courseName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(submission.name)
                        .font(.headline)

                    if let courseName {
                        Text(courseName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                PillBadge(text: "Missing", tint: .red)
            }

            HStack(spacing: 12) {
                Label(
                    DisplayFormatters.formatted(date: submission.dueAt),
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if let relative = DisplayFormatters.relativeString(date: submission.dueAt) {
                    Text(relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let url = submission.htmlURL {
                    Link("Open in Canvas", destination: url)
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.vertical, 8)
    }
}
