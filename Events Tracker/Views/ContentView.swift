//
//  ContentView.swift
//  Events Tracker
//
//  Redesigned sidebar: Inbox section (Dashboard/Overdue/Today/Events) +
//  Courses section with color dots, plus existing nav items.
//

import SwiftUI

private enum AppSection: Hashable {
    case dashboard
    case overdue
    case today
    case events
    case assignments
    case courses
    case profile
    case settings
    case courseFilter(Int)   // course-specific filtered dashboard
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
                if let msg = store.errorMessage {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.10))
                }

                Group {
                    switch selectedSection {
                    case .dashboard, .courseFilter, nil:
                        HomeView()
                    case .overdue:
                        FocusedTaskView(mode: .overdue)
                    case .today:
                        FocusedTaskView(mode: .today)
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
        // Sync selectedCourseID with sidebar course selection
        .onChange(of: selectedSection) { _, newSection in
            switch newSection {
            case .courseFilter(let id):
                store.selectedCourseID = id
            case .dashboard, .overdue, .today, .events:
                store.selectedCourseID = nil
            default:
                break
            }
        }
    }
}

// MARK: - Sidebar

private struct DesignedSidebar: View {
    @Binding var selectedSection: AppSection?
    let et: ETColors
    @EnvironmentObject private var store: CanvasStore
    @State private var showCourseVisibility = false

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
                sectionHeader("Inbox")
            }

            // Courses
            Section {
                // "All Courses" row — tap opens visibility sheet
                Button {
                    showCourseVisibility = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 13))
                            .foregroundStyle(et.accent)
                            .frame(width: 16)
                        Text("All Courses")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if !store.hiddenCourseIDs.isEmpty {
                            Text("\(store.hiddenCourseIDs.count) hidden")
                                .font(.system(size: 11))
                                .foregroundStyle(et.textFaint)
                        }
                    }
                }
                .buttonStyle(.plain)
                .tag(AppSection.courses)

                ForEach(store.visibleCourses) { course in
                    CourseRow(course: course, et: et)
                        .tag(AppSection.courseFilter(course.id))
                }
            } header: {
                sectionHeader("Courses")
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
                sectionHeader("More")
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
        .sheet(isPresented: $showCourseVisibility) {
            CourseVisibilitySheet(et: et)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(et.textFaint)
            .kerning(0.5)
            .textCase(.uppercase)
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

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(courseColor(for: course))
                .frame(width: 9, height: 9)
            Text(course.courseCode ?? course.name)
                .font(.system(size: 12.5, weight: .medium))
                .lineLimit(1)
            Spacer()
        }
    }
}

// MARK: - Course Visibility Sheet

private struct CourseVisibilitySheet: View {
    let et: ETColors
    @EnvironmentObject private var store: CanvasStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sidebar Courses")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Choose which courses appear in the sidebar")
                        .font(.system(size: 12))
                        .foregroundStyle(et.textMuted)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(store.courses) { course in
                        let isHidden = store.hiddenCourseIDs.contains(course.id)
                        Button {
                            store.toggleCourseVisibility(course.id)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(courseColor(for: course))
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(course.courseCode ?? course.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(isHidden ? et.textMuted : Color.primary)
                                    Text(course.name)
                                        .font(.system(size: 11))
                                        .foregroundStyle(et.textMuted)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: isHidden ? "eye.slash" : "eye")
                                    .font(.system(size: 13))
                                    .foregroundStyle(isHidden ? et.textFaint : et.accent)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(isHidden ? et.pillBg : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if course.id != store.courses.last?.id {
                            Divider().padding(.leading, 42)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 360, height: min(CGFloat(store.courses.count) * 56 + 120, 500))
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CanvasStore())
    }
}
