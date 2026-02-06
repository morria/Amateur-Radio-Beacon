import Foundation

/// The three operating modes of the beacon station
enum BeaconMode: String, CaseIterable, Identifiable, CustomStringConvertible {
    case tone = "Tone"
    case message = "Message"
    case cw = "CW"

    var id: String { rawValue }

    /// Localized display name for UI
    var displayName: LocalizedStringResource {
        switch self {
        case .tone:
            return "Tone"
        case .message:
            return "Message"
        case .cw:
            return "CW"
        }
    }

    /// Localized description for UI
    var localizedDescription: LocalizedStringResource {
        switch self {
        case .tone:
            return "Continuous tone at adjustable frequency"
        case .message:
            return "Recorded voice message"
        case .cw:
            return "Morse code transmission"
        }
    }

    var description: String {
        switch self {
        case .tone:
            return "Continuous tone at adjustable frequency"
        case .message:
            return "Recorded voice message"
        case .cw:
            return "Morse code transmission"
        }
    }
}
