//
//  ContentView.swift
//  Events Tracker
//
//  Redesigned sidebar: Inbox section (Dashboard/Overdue/Today/Events) +
//  Courses section with color dots, plus existing nav items.
//

import SwiftUI

private enum AppSection: String, Hashable {
    case dashboard = "Dashboard"
    case overdue = "Overdue"
    case today = "Today"
    case events = "All Events"
    case assignments = "Assignments"
    case courses = "Courses"
    case profile = "Profile"
    case settings = "Settings"
}

struct ContentView: View {
    @EnvironmentObject private var store: CanvasStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSection: AppSection? = .dashboard

    var body: some View {
        let et = ETColors(colorScheme: colorScheme)

        NavigationSplitView {
            DesignedSidebar(selectedSection: $selectedSection, et: et)
                .navigationTitle("")
        } detail: {
            VStack(spacing: 0) {
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.10))
                }

                Group {
                    switch selectedSection {
                    case .dashboard, .overdue, .today, nil:
                        HomeView()
                    case .events:
                        EventsView()
                    case .assignments:
                        AssignmentsView()
                    case .courses:
                        CoursesView()
                    case .profile:
                        ProfileView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        if store.isSyncing {
                            ProgressView()
                        } else {
                            Label("Sync", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(!store.isConfigured || store.isSyncing)
                }
            }
        }
    }
}

// MARK: - Sidebar

private struct DesignedSidebar: View {
    @Binding var selectedSection: AppSection?
    let et: ETColors
    @EnvironmentObject private var store: CanvasStore

    var body: some View {
        List(selection: $selectedSection) {
            // Inbox
            Section {
                SidebarRow(label: "Dashboard", systemImage: "rectangle.3.group",
                           badge: store.thisWeekTaskCount > 0 ? "\(store.thisWeekTaskCount)" : nil,
                           badgeColor: nil, et: et)
                    .tag(AppSection.dashboard)

                SidebarRow(label: "Overdue", systemImage: "exclamationmark.circle",
                           badge: store.overdueCount > 0 ? "\(store.overdueCount)" : nil,
                           badgeColor: et.urgent, et: et)
                    .tag(AppSection.overdue)

                SidebarRow(label: "Today", systemImage: "sun.horizon",
                           badge: store.todayTaskCount > 0 ? "\(store.todayTaskCount)" : nil,
                           badgeColor: nil, et: et)
                    .tag(AppSection.today)

                SidebarRow(label: "All Events", systemImage: "calendar",
                           badge: nil, badgeColor: nil, et: et)
                    .tag(AppSection.events)
            } header: {
                Text("Inbox")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(et.textFaint)
                    .kerning(0.5)
                    .textCase(.uppercase)
            }

            // Courses
            Section {
                SidebarRow(label: "All Courses", systemImage: "circle",
                           badge: nil, badgeColor: nil, et: et, courseColor: nil)
                    .tag(AppSection.courses)
                    .simultaneousGesture(TapGesture().onEnded {
                        store.selectedCourseID = nil
                    })

                ForEach(store.courses) { course in
                    CourseRow(course: course, et: et,
                              isSelected: store.selectedCourseID == course.id)
                        .tag(AppSection.dashboard)
                        .onTapGesture {
                            store.selectedCourseID = course.id
                            selectedSection = .dashboard
                        }
                }
            } header: {
                Text("Courses")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(et.textFaint)
                    .kerning(0.5)
                    .textCase(.uppercase)
            }

            // More
            Section {
                SidebarRow(label: "Assignments", systemImage: "checklist",
                           badge: nil, badgeColor: nil, et: et)
                    .tag(AppSection.assignments)
                SidebarRow(label: "Profile", systemImage: "person.crop.circle",
                           badge: nil, badgeColor: nil, et: et)
                    .tag(AppSection.profile)
                SidebarRow(label: "Settings", systemImage: "gearshape",
                           badge: nil, badgeColor: nil, et: et)
                    .tag(AppSection.settings)
            } header: {
                Text("More")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(et.textFaint)
                    .kerning(0.5)
                    .textCase(.uppercase)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220, idealWidth: 230, maxWidth: 260)
        .safeAreaInset(edge: .bottom) {
            if let desc = store.lastSyncDescription {
                Text("Last synced \(desc)")
                    .font(.system(size: 11))
                    .foregroundStyle(et.textFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
    }
}

private struct SidebarRow: View {
    let label: String
    let systemImage: String
    let badge: String?
    let badgeColor: Color?
    let et: ETColors
    var courseColor: Color? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(badgeColor ?? et.accent)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            if let badge {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(badgeColor ?? et.textMuted)
            }
        }
    }
}

private struct CourseRow: View {
    let course: Course
    let et: ETColors
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(courseColor(for: course))
                .frame(width: 9, height: 9)
            Text(course.courseCode ?? course.name)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                .lineLimit(1)
            Spacer()
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CanvasStore())
    }
}
