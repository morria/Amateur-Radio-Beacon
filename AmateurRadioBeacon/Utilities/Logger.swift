import Foundation
import os

/// Centralized logging for the beacon app
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.amateurradio.beacon"

    static let audio = Logger(subsystem: subsystem, category: "Audio")
    static let beacon = Logger(subsystem: subsystem, category: "Beacon")
    static let recording = Logger(subsystem: subsystem, category: "Recording")
    static let cadence = Logger(subsystem: subsystem, category: "Cadence")
}
