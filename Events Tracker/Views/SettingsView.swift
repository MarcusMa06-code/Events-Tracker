//
//  SettingsView.swift
//  Events Tracker
//
//  Created by Eddie Gao on 31/3/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CanvasStore

    @State private var baseURL = ""
    @State private var token = ""
    @State private var lookaheadDays = 14
    @State private var statusMessage: String?
    @State private var didPopulateFields = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.largeTitle.weight(.semibold))

                Form {
                    Section("Canvas Connection") {
                        TextField("https://school.instructure.com", text: $baseURL)
                            .textFieldStyle(.roundedBorder)

                        SecureField("Personal Access Token", text: $token)
                            .textFieldStyle(.roundedBorder)

                        Stepper(value: $lookaheadDays, in: 7...45) {
                            Text("Look ahead \(lookaheadDays) days for upcoming events")
                        }
                    }

                    Section("Connect") {
                        Text("Use your school's Canvas root domain. If you paste a URL that already includes `/api/v1`, the app will normalize it.")
                        Text("Generate a personal access token from your Canvas account settings, then save and sync.")
                    }

                    Section("Local Data") {
                        Text("Changing the Canvas URL or token clears the cached dashboard so data from different accounts never mixes together.")
                    }
                }
                .formStyle(.grouped)

                HStack(spacing: 12) {
                    Button("Save") {
                        _ = saveConfiguration()
                    }

                    Button("Save and Sync") {
                        guard saveConfiguration() else {
                            return
                        }

                        Task {
                            await store.refresh()
                        }
                    }
                    .disabled(store.isSyncing)

                    Button("Clear Cached Data", role: .destructive) {
                        store.clearLocalData()
                        statusMessage = "Cached dashboard cleared."
                    }

                    Spacer()
                }

                if let statusMessage {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .onAppear {
            populateFieldsIfNeeded()
        }
    }

    private func populateFieldsIfNeeded() {
        guard !didPopulateFields else {
            return
        }

        baseURL = store.config.normalizedBaseURL.isEmpty ? store.config.baseURL : store.config.normalizedBaseURL
        token = store.config.token
        lookaheadDays = store.config.lookaheadDays
        didPopulateFields = true
    }

    private func saveConfiguration() -> Bool {
        do {
            let credentialsChanged = try store.saveConfiguration(
                baseURL: baseURL,
                token: token,
                lookaheadDays: lookaheadDays
            )

            statusMessage = credentialsChanged
                ? "Configuration saved. Cached data was cleared for the new Canvas connection."
                : "Configuration saved."
            return true
        } catch {
            statusMessage = error.localizedDescription
            return false
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(CanvasStore())
    }
}
