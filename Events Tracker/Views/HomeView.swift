//
//  HomeView.swift
//  Events Tracker
//
//  Created by Eddie Gao on 31/3/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: CanvasStore

    var body: some View {
        if !store.isConfigured {
            SetupPromptView(
                title: "Connect Canvas",
                message: "Save your Canvas base URL and personal access token in Settings, then sync to build your dashboard."
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // Title + inline stats
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dashboard")
                            .font(.largeTitle.weight(.semibold))

                        HStack(spacing: 0) {
                            HomeStatItem(value: "\(store.courses.count)", label: "courses")
                            homeDot
                            HomeStatItem(value: "\(store.eventsDueThisWeekCount)", label: "due this week")
                            homeDot
                            HomeStatItem(
                                value: "\(store.missingSubmissions.count)",
                                label: "missing",
                                valueColor: store.missingSubmissions.isEmpty ? Color.secondary : Color.red
                            )
                        }
                        .font(.subheadline)
                    }

                    // Needs Attention
                    if !store.missingSubmissions.isEmpty {
                        HomeSection(title: "Needs Attention") {
                            ForEach(Array(store.missingSubmissions.prefix(5))) { submission in
                                HomeMissingRow(
                                    submission: submission,
                                    courseName: store.courseName(for: submission.courseID)
                                )
                                if submission.id != store.missingSubmissions.prefix(5).last?.id {
                                    Divider().padding(.leading, 32)
                                }
                            }
                        }
                    }

                    // Coming Up
                    HomeSection(title: "Coming Up") {
                        if store.upcomingEvents.isEmpty {
                            Text("Nothing scheduled yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(store.upcomingEvents.prefix(8))) { event in
                                HomeEventRow(
                                    event: event,
                                    courseName: store.courseName(for: event.courseID)
                                )
                                if event.id != store.upcomingEvents.prefix(8).last?.id {
                                    Divider().padding(.leading, 32)
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    private var homeDot: some View {
        Text("·")
            .foregroundStyle(Color(white: 0.6))
            .padding(.horizontal, 6)
    }
}

private struct HomeStatItem: View {
    let value: String
    let label: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
            Text(label)
                .foregroundStyle(Color.secondary)
        }
    }
}

private struct HomeSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            content
        }
    }
}

private struct HomeMissingRow: View {
    let submission: MissingSubmission
    let courseName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .strokeBorder(Color.red, lineWidth: 1.5)
                .frame(width: 16, height: 16)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(submission.name)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    if let courseName {
                        Text(courseName)
                            .foregroundStyle(Color.secondary)
                    }
                    if let dueAt = submission.dueAt,
                       let relative = DisplayFormatters.relativeString(date: dueAt) {
                        if courseName != nil {
                            Text("·").foregroundStyle(Color(white: 0.6))
                        }
                        Text(relative).foregroundStyle(Color.red)
                    }
                }
                .font(.caption)
            }

            Spacer()

            if let url = submission.htmlURL {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 9)
    }
}

private struct HomeEventRow: View {
    let event: UpcomingEvent
    let courseName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .strokeBorder(event.isAssignment ? Color.orange : Color.green, lineWidth: 1.5)
                .frame(width: 16, height: 16)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    if let courseName {
                        Text(courseName)
                            .foregroundStyle(Color.secondary)
                    }
                    if let date = event.displayDate,
                       let relative = DisplayFormatters.relativeString(date: date) {
                        if courseName != nil {
                            Text("·").foregroundStyle(Color(white: 0.6))
                        }
                        Text(relative).foregroundStyle(Color.secondary)
                    }
                }
                .font(.caption)
            }

            Spacer()

            if let url = event.actionableURL {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.secondary.opacity(0.5))
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 9)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(CanvasStore())
    }
}
