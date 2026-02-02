import Foundation

/// The three operating modes of the beacon station
enum BeaconMode: String, CaseIterable, Identifiable {
    case tone = "Tone"
    case message = "Message"
    case cw = "CW"

    var id: String { rawValue }

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
