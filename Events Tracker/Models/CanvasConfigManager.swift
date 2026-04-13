//
//  CanvasConfigManager.swift
//  Events Tracker
//
//  Created by Eddie Gao on 1/4/25.
//

import Foundation

final class CanvasConfigManager {
    static let shared = CanvasConfigManager()

    private let configURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let fileManager = FileManager.default
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser
        let appDirectory = baseDirectory.appendingPathComponent("EventsTracker", isDirectory: true)

        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        configURL = appDirectory.appendingPathComponent("canvas-config.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder = JSONDecoder()
    }

    func saveConfig(_ config: CanvasConfig) throws {
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }

    func loadConfig() -> CanvasConfig {
        guard let data = try? Data(contentsOf: configURL) else {
            return CanvasConfig()
        }

        return (try? decoder.decode(CanvasConfig.self, from: data)) ?? CanvasConfig()
    }
}
