import Foundation

/// Configuration for beacon transmission cadence
struct CadenceConfiguration: Equatable {
    /// Duration of pause between transmissions in seconds
    var pauseDuration: Double = 5.0

    /// When true, loops continuously without pauses
    var isContinuous: Bool = true

    /// Minimum pause duration in seconds
    static let minPauseDuration: Double = 1.0

    /// Maximum pause duration in seconds
    static let maxPauseDuration: Double = 300.0
}

/// Current phase of the beacon cycle
enum CadencePhase: Equatable, CustomStringConvertible {
    case idle
    case transmitting
    case waiting

    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .transmitting:
            return "Transmitting"
        case .waiting:
            return "Waiting"
        }
    }
}
