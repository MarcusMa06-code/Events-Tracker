# Repository Guidelines

## Project Structure & Module Organization
`Events Tracker/` contains the macOS SwiftUI app. Keep app entry in `Events_TrackerApp.swift`, state and Canvas API logic in `Models/`, and screens plus shared UI in `Views/`. `CanvasStore.swift` is the app state hub, `NetworkManager.swift` owns Canvas REST calls, and `CoursesView.swift` is the main course workspace. Store assets in `Assets.xcassets/` and `Preview Content/`. Unit tests live in `Events TrackerTests/`; UI smoke tests live in `Events TrackerUITests/`. The Xcode project is `Events Tracker.xcodeproj`.

## Build, Test, and Development Commands
- `open 'Events Tracker.xcodeproj'`: open the project in Xcode.
- `xcodebuild -project 'Events Tracker.xcodeproj' -scheme 'Events Tracker' -destination 'platform=macOS' build`: build the app from the CLI.
- `xcodebuild -project 'Events Tracker.xcodeproj' -scheme 'Events Tracker' -destination 'platform=macOS' test`: run unit and UI tests.
- `xcodebuild -project 'Events Tracker.xcodeproj' -scheme 'Events Tracker' -destination 'platform=macOS' -only-testing:'Events TrackerTests' test`: run stable unit tests when UI runner issues are unrelated to your change.
- `xcrun swiftc -typecheck -module-cache-path /tmp/swift-module-cache -sdk $(xcrun --show-sdk-path --sdk macosx) -target arm64-apple-macos15.0 -module-name Events_Tracker 'Events Tracker/Events_TrackerApp.swift' 'Events Tracker/Models/'*.swift 'Events Tracker/Views/'*.swift`: quick source typecheck when you want compiler feedback without a full Xcode build.

## Student Canvas Roadmap
This repo is now a student-side Canvas replacement, not an instructor tool. Completed work includes dashboard sync, upcoming events, missing work, settings/profile, and a course workspace with `Overview`, `Modules`, `Assignments`, and `Grades`.

Next priority is course-level `Files`, `Syllabus`, and `Announcements`. After that, focus on polish and extensibility: better filters, saved course preferences, and lightweight local caching for per-course detail views. Prefer adding new course features as lazy-loaded course sections backed by `CanvasStore`, not ad hoc view-local networking.

## Coding Style & Naming Conventions
Use Swift 5 with 4-space indentation. Prefer `UpperCamelCase` for types, `lowerCamelCase` for properties and methods, and keep filenames aligned with the primary type (`CanvasStore.swift`, `HomeView.swift`). Follow the current split: networking and persistence in `Models/`, presentation in `Views/`. Keep SwiftUI views small and move reusable formatting or row components into shared view files.

## Testing Guidelines
Use the `Testing` framework for unit tests and `XCTest` for UI tests. Name tests after behavior, for example `configNormalizationTrimsWhitespace`. Add or update tests for parsing, filtering, status calculation, and Canvas data shaping when touching `Models/`. For UI changes, verify the affected screen manually in Xcode and run targeted unit tests even if macOS UI runner bootstrapping is flaky.

## Commit & Pull Request Guidelines
History is minimal and currently uses descriptive sentence-style commits. Prefer concise, imperative summaries such as `Add Canvas settings validation` or `Refactor dashboard event loading`. PRs should explain the user-visible change, note any Canvas API endpoints or local cache changes, and include screenshots for UI updates. Link the relevant issue or task when one exists.

## Security & Configuration Tips
Never commit real Canvas tokens or personal instance URLs. Configuration is stored locally in Application Support; treat it as user data, not source. Keep sample values generic, such as `https://school.instructure.com`. Do not stage `.DS_Store` or other local machine artifacts.
