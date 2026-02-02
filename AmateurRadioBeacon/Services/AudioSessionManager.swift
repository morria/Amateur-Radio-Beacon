import AVFoundation

/// Manages AVAudioSession configuration for the beacon app
@Observable
final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private(set) var isSessionActive = false
    private(set) var hasMicrophonePermission = false

    private enum SessionMode: CustomStringConvertible {
        case none, playback, recording

        var description: String {
            switch self {
            case .none: return "none"
            case .playback: return "playback"
            case .recording: return "recording"
            }
        }
    }
    private var currentMode: SessionMode = .none

    private init() {}

    /// Configure audio session for playback (tone/CW modes)
    func configureForPlayback() throws {
        Log.audio.debug("[AudioSessionManager] Configuring for playback, current mode: \(self.currentMode)")
        let session = AVAudioSession.sharedInstance()

        // Deactivate if switching from recording mode
        if currentMode == .recording {
            Log.audio.debug("[AudioSessionManager] Switching from recording - deactivating session")
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            // Brief delay to allow audio system to settle
            Thread.sleep(forTimeInterval: 0.05)
        }

        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        isSessionActive = true
        currentMode = .playback
        Log.audio.debug("[AudioSessionManager] Playback mode configured successfully")
    }

    /// Configure audio session for recording (message mode)
    func configureForRecording() throws {
        Log.audio.debug("[AudioSessionManager] Configuring for recording, current mode: \(self.currentMode)")
        let session = AVAudioSession.sharedInstance()

        // Deactivate if switching from playback mode
        if currentMode == .playback {
            Log.audio.debug("[AudioSessionManager] Switching from playback - deactivating session")
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            // Brief delay to allow audio system to settle
            Thread.sleep(forTimeInterval: 0.05)
        }

        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        isSessionActive = true
        currentMode = .recording
        Log.audio.debug("[AudioSessionManager] Recording mode configured successfully")
    }

    /// Deactivate audio session
    func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
            currentMode = .none
        } catch {
            Log.audio.error("Failed to deactivate audio session: \(error)")
        }
    }

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        let status = AVAudioApplication.shared.recordPermission

        switch status {
        case .granted:
            hasMicrophonePermission = true
            return true
        case .denied:
            hasMicrophonePermission = false
            return false
        case .undetermined:
            let granted = await AVAudioApplication.requestRecordPermission()
            hasMicrophonePermission = granted
            return granted
        @unknown default:
            hasMicrophonePermission = false
            return false
        }
    }

    /// Check current microphone permission status
    func checkMicrophonePermission() -> Bool {
        let status = AVAudioApplication.shared.recordPermission
        hasMicrophonePermission = status == .granted
        return hasMicrophonePermission
    }
}
