//
//  ProfileView.swift
//  Events Tracker
//
//  Created by Eddie Gao on 31/3/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: CanvasStore

    var body: some View {
        if !store.isConfigured {
            SetupPromptView(
                title: "No Connected Profile",
                message: "Connect Canvas in Settings and sync to load your account details."
            )
        } else if let profile = store.profile {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Profile")
                        .font(.largeTitle.weight(.semibold))

                    HStack(alignment: .top, spacing: 20) {
                        AsyncImage(url: profile.avatarURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(.gray.opacity(0.15))
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 10) {
                            Text(profile.name)
                                .font(.title.weight(.semibold))

                            if let title = profile.title, !title.isEmpty {
                                Text(title)
                                    .foregroundStyle(.secondary)
                            }

                            if let email = profile.primaryEmail ?? profile.loginID {
                                Label(email, systemImage: "envelope")
                                    .foregroundStyle(.secondary)
                            }

                            if let timeZone = profile.timeZone, !timeZone.isEmpty {
                                Label(timeZone, systemImage: "globe")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workspace")
                            .font(.title2.weight(.semibold))

                        Label(store.hostLabel, systemImage: "link")
                            .foregroundStyle(.secondary)

                        if let lastSyncDescription = store.lastSyncDescription {
                            Label("Last synced \(lastSyncDescription)", systemImage: "arrow.clockwise")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let bio = profile.bio, !bio.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bio")
                                .font(.title2.weight(.semibold))

                            Text(bio)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(24)
            }
        } else {
            SetupPromptView(
                title: "Profile Not Loaded Yet",
                message: "Sync once after connecting Canvas to load your profile information."
            )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(CanvasStore())
    }
}
