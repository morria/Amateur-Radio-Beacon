import Foundation

/// A saved voice recording for message mode
struct Recording: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let duration: TimeInterval
    let createdAt: Date
    let fileName: String

    init(id: UUID = UUID(), name: String, duration: TimeInterval, createdAt: Date = Date(), fileName: String) {
        self.id = id
        self.name = name
        self.duration = duration
        self.createdAt = createdAt
        self.fileName = fileName
    }

    var fileURL: URL {
        Recording.recordingsDirectory.appendingPathComponent(fileName)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static var recordingsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsPath = documentsPath.appendingPathComponent("Recordings", isDirectory: true)

        if !FileManager.default.fileExists(atPath: recordingsPath.path) {
            try? FileManager.default.createDirectory(at: recordingsPath, withIntermediateDirectories: true)
        }

        return recordingsPath
    }
}
