import Foundation
import UIKit

class BackupService: ObservableObject {

    static let shared = BackupService()

    private let baseFolder: URL

    @Published var savedEntries: [String] = []

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        baseFolder = documents.appendingPathComponent("StreamBackup")

        if !FileManager.default.fileExists(atPath: baseFolder.path) {
            try? FileManager.default.createDirectory(at: baseFolder, withIntermediateDirectories: true)
        }

        loadEntries()
        autoCleanupOldFiles()
    }

    // MARK: - Save frame + metadata
    func saveFrame(frame: Data, lat: Double, lon: Double, timestamp: String) {

        let cleanTimestamp = timestamp.replacingOccurrences(of: ":", with: "-")

        let folder = baseFolder.appendingPathComponent(cleanTimestamp)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let imagePath = folder.appendingPathComponent("frame.jpg")
        try? frame.write(to: imagePath)

        let metadata: [String: Any] = [
            "timestamp": timestamp,
            "lat": lat,
            "lon": lon
        ]

        let jsonPath = folder.appendingPathComponent("metadata.json")
        let jsonData = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        try? jsonData?.write(to: jsonPath)

        loadEntries()
    }

    // MARK: - Load saved entries
    func loadEntries() {
        let folders = (try? FileManager.default.contentsOfDirectory(at: baseFolder, includingPropertiesForKeys: nil)) ?? []

        savedEntries = folders.map { $0.lastPathComponent }.sorted(by: >)
    }

    // MARK: - Auto delete backups older than 7 days
    func autoCleanupOldFiles() {
        let fm = FileManager.default
        let folders = (try? fm.contentsOfDirectory(at: baseFolder, includingPropertiesForKeys: [.creationDateKey])) ?? []

        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)

        for folder in folders {
            if let attrs = try? fm.attributesOfItem(atPath: folder.path),
               let created = attrs[.creationDate] as? Date {
                if created < sevenDaysAgo {
                    try? fm.removeItem(at: folder)
                }
            }
        }

        loadEntries()
    }

    // MARK: - Get backup folder URL
    func getBackupFolderURL() -> URL {
        return baseFolder
    }
}

