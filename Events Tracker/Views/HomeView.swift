//
//  HomeView.swift
//  Events Tracker
//
//  Created by Eddie Gao on 31/3/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: CanvasStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        if !store.isConfigured {
            SetupPromptView(
                title: "Connect Canvas",
                message: "Save your Canvas base URL and personal access token in Settings, then sync to build your dashboard."
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Dashboard")
                        .font(.largeTitle.weight(.semibold))

                    LazyVGrid(columns: columns, spacing: 12) {
                        SummaryCard(
                            title: "Courses",
                            value: "\(store.courses.count)",
                            detail: store.hostLabel.isEmpty ? "Connected Canvas workspace" : store.hostLabel,
                            systemImage: "books.vertical",
                            tint: .blue
                        )

                        SummaryCard(
                            title: "Due This Week",
                            value: "\(store.eventsDueThisWeekCount)",
                            detail: "Upcoming assignments and course events in the next 7 days.",
                            systemImage: "calendar.badge.clock",
                            tint: .green
                        )

                        SummaryCard(
                            title: "Missing Work",
                            value: "\(store.missingSubmissions.count)",
                            detail: "Past-due assignments with no submission recorded.",
                            systemImage: "exclamationmark.circle",
                            tint: .red
                        )

                        SummaryCard(
                            title: "Next Deadline",
                            value: store.nextUpcomingEvent.flatMap { DisplayFormatters.relativeString(date: $0.displayDate) } ?? "Clear",
                            detail: store.nextUpcomingEvent?.title ?? "No upcoming deadlines found.",
                            systemImage: "flag",
                            tint: .orange
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Needs Attention")
                            .font(.title2.weight(.semibold))

                        if store.missingSubmissions.isEmpty {
                            Text("Nothing overdue right now.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(store.missingSubmissions.prefix(5))) { submission in
                                MissingSubmissionRow(
                                    submission: submission,
                                    courseName: store.courseName(for: submission.courseID)
                                )

                                if submission.id != store.missingSubmissions.prefix(5).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Coming Up")
                            .font(.title2.weight(.semibold))

                        if store.upcomingEvents.isEmpty {
                            Text("No upcoming items yet. Sync again after Canvas has upcoming work scheduled.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(store.upcomingEvents.prefix(8))) { event in
                                UpcomingEventRow(
                                    event: event,
                                    courseName: store.courseName(for: event.courseID)
                                )

                                if event.id != store.upcomingEvents.prefix(8).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(CanvasStore())
    }
}
