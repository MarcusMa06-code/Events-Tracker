//
//  EventsView.swift
//  Events Tracker
//
//  Created by Eddie Gao on 31/3/25.
//

import SwiftUI

private enum EventsFilter: String, CaseIterable, Identifiable {
    case upcoming = "Upcoming"
    case missing = "Missing"

    var id: String { rawValue }
}

struct EventsView: View {
    @EnvironmentObject private var store: CanvasStore
    @State private var filter: EventsFilter = .upcoming

    private var selectedCourseBinding: Binding<Int?> {
        Binding(
            get: { store.selectedCourseID },
            set: { store.selectedCourseID = $0 }
        )
    }

    var body: some View {
        if !store.isConfigured {
            SetupPromptView(
                title: "Canvas Events Need a Connection",
                message: "Add your Canvas credentials in Settings to load assignments, calendar events, and missing work."
            )
        } else {
            HStack(spacing: 0) {
                List(selection: selectedCourseBinding) {
                    Text("All Courses")
                        .tag(nil as Int?)

                    ForEach(store.courses) { course in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.name)
                            if let termName = course.enrollmentTerm?.name, !termName.isEmpty {
                                Text(termName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(Optional(course.id))
                    }
                }
                .frame(minWidth: 250, idealWidth: 260, maxWidth: 280)

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(store.selectedCourseName ?? "All Courses")
                            .font(.largeTitle.weight(.semibold))

                        Spacer()

                        Picker("Filter", selection: $filter) {
                            ForEach(EventsFilter.allCases) { item in
                                Text(item.rawValue)
                                    .tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                    }

                    if filter == .upcoming {
                        let items = store.filteredUpcomingEvents(courseID: store.selectedCourseID)

                        if items.isEmpty {
                            SetupPromptView(
                                title: "No Upcoming Items",
                                message: "This course does not have upcoming assignments or events in Canvas right now."
                            )
                        } else {
                            List(items) { event in
                                UpcomingEventRow(
                                    event: event,
                                    courseName: store.courseName(for: event.courseID)
                                )
                            }
                            .listStyle(.inset)
                        }
                    } else {
                        let items = store.filteredMissingSubmissions(courseID: store.selectedCourseID)

                        if items.isEmpty {
                            SetupPromptView(
                                title: "No Missing Work",
                                message: "Canvas is not reporting any past-due missing submissions for this course."
                            )
                        } else {
                            List(items) { submission in
                                MissingSubmissionRow(
                                    submission: submission,
                                    courseName: store.courseName(for: submission.courseID)
                                )
                            }
                            .listStyle(.inset)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        EventsView()
            .environmentObject(CanvasStore())
    }
}
