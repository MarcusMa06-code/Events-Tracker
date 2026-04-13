# Repository Guidelines

## Project Structure & Module Organization
`Events Tracker/` contains the macOS SwiftUI app. Keep app entry in `Events_TrackerApp.swift`, state and API logic in `Models/`, and screens plus shared UI in `Views/`. Store image colors, icons, and preview assets in `Assets.xcassets/` and `Preview Content/`. Unit tests live in `Events TrackerTests/`; UI smoke tests live in `Events TrackerUITests/`. The Xcode project is `Events Tracker.xcodeproj`.

## Build, Test, and Development Commands
- `open 'Events Tracker.xcodeproj'`: open the project in Xcode.
- `xcodebuild -project 'Events Tracker.xcodeproj' -scheme 'Events Tracker' -destination 'platform=macOS' build`: build the app from the CLI.
- `xcodebuild -project 'Events Tracker.xcodeproj' -scheme 'Events Tracker' -destination 'platform=macOS' test`: run unit and UI tests.
- `xcrun swiftc -typecheck -module-cache-path /tmp/swift-module-cache -sdk $(xcrun --show-sdk-path --sdk macosx) -target arm64-apple-macos15.0 -module-name Events_Tracker 'Events Tracker/Events_TrackerApp.swift' 'Events Tracker/Models/'*.swift 'Events Tracker/Views/'*.swift`: quick source typecheck when you want compiler feedback without a full Xcode build.

## Coding Style & Naming Conventions
Use Swift 5 with 4-space indentation. Prefer `UpperCamelCase` for types, `lowerCamelCase` for properties and methods, and keep filenames aligned with the primary type (`CanvasStore.swift`, `HomeView.swift`). Follow the current split: networking and persistence in `Models/`, presentation in `Views/`. Keep SwiftUI views small and move reusable formatting or row components into shared view files.

## Testing Guidelines
Use the `Testing` framework for unit tests and `XCTest` for UI tests. Name tests after behavior, for example `configNormalizationTrimsWhitespace`. Add or update tests for parsing, filtering, and Canvas data shaping when touching `Models/`. For UI changes, at minimum keep launch tests passing and verify the affected screen manually in Xcode.

## Commit & Pull Request Guidelines
History is minimal and currently uses descriptive sentence-style commits. Prefer concise, imperative summaries such as `Add Canvas settings validation` or `Refactor dashboard event loading`. PRs should explain the user-visible change, note any Canvas API endpoints or local cache changes, and include screenshots for UI updates. Link the relevant issue or task when one exists.

## Security & Configuration Tips
Never commit real Canvas tokens or personal instance URLs. Configuration is stored locally in Application Support; treat it as user data, not source. Keep sample values generic, such as `https://school.instructure.com`.
