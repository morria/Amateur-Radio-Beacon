import AVFoundation
import Foundation

/// Handles voice recording and playback for message mode
@Observable
final class RecordingService {
    @ObservationIgnored private var audioRecorder: AVAudioRecorder?
    @ObservationIgnored private var audioPlayer: AVAudioPlayer?
    @ObservationIgnored private var recordingTimer: Timer?
    @ObservationIgnored private var playbackDelegate: PlaybackDelegate?

    private(set) var isRecording = false
    private(set) var isPlaying = false
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var recordings: [Recording] = []

    /// Callback invoked when playback finishes
    @ObservationIgnored var onPlaybackComplete: (() -> Void)?

    private let recordingsKey = "SavedRecordings"

    init() {
        loadRecordings()
    }

    // MARK: - Recording

    func startRecording(name: String) async throws -> Recording? {
        guard await AudioSessionManager.shared.requestMicrophonePermission() else {
            return nil
        }

        try AudioSessionManager.shared.configureForRecording()

        let fileName = "\(UUID().uuidString).m4a"
        let fileURL = Recording.recordingsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.prepareToRecord()
        recorder.record()

        self.audioRecorder = recorder
        isRecording = true
        recordingDuration = 0

        // Start timer to track duration
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0
        }

        // Return a placeholder recording - actual duration will be set on stop
        return Recording(
            name: name,
            duration: 0,
            fileName: fileName
        )
    }

    func stopRecording() -> Recording? {
        guard isRecording, let recorder = audioRecorder else { return nil }

        let duration = recorder.currentTime
        recorder.stop()

        recordingTimer?.invalidate()
        recordingTimer = nil

        // Find the recording we started
        let fileName = recorder.url.lastPathComponent

        audioRecorder = nil
        isRecording = false

        // Create the final recording with actual duration
        let recording = Recording(
            name: "Recording \(recordings.count + 1)",
            duration: duration,
            fileName: fileName
        )

        recordings.append(recording)
        saveRecordings()

        return recording
    }

    func cancelRecording() {
        guard isRecording, let recorder = audioRecorder else { return }

        recorder.stop()
        try? FileManager.default.removeItem(at: recorder.url)

        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder = nil
        isRecording = false
        recordingDuration = 0
    }

    // MARK: - Playback

    func play(recording: Recording) throws {
        guard !isPlaying else {
            print("[RecordingService] Already playing, ignoring play request")
            return
        }

        print("[RecordingService] Starting playback for recording: \(recording.name)")
        print("[RecordingService] File URL: \(recording.fileURL)")

        // Validate file exists before attempting playback
        guard FileManager.default.fileExists(atPath: recording.fileURL.path) else {
            print("[RecordingService] ERROR: File not found at path: \(recording.fileURL.path)")
            throw RecordingError.fileNotFound
        }

        print("[RecordingService] File exists, configuring audio session")
        try AudioSessionManager.shared.configureForPlayback()

        print("[RecordingService] Creating audio player")
        let player = try AVAudioPlayer(contentsOf: recording.fileURL)

        // Store player and delegate BEFORE calling play
        let delegate = PlaybackDelegate { [weak self] in
            print("[RecordingService] Playback finished via delegate")
            self?.isPlaying = false
            self?.playbackDelegate = nil
            self?.onPlaybackComplete?()
        }
        self.playbackDelegate = delegate
        self.audioPlayer = player
        player.delegate = delegate

        // Prepare and verify playback
        player.prepareToPlay()
        player.volume = 1.0

        let success = player.play()
        print("[RecordingService] play() returned: \(success), duration: \(player.duration), isPlaying: \(player.isPlaying)")

        if success {
            isPlaying = true
        } else {
            print("[RecordingService] ERROR: play() returned false!")
            throw RecordingError.playbackFailed
        }
    }

    enum RecordingError: Error {
        case fileNotFound
        case playbackFailed
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    // MARK: - Management

    func deleteRecording(_ recording: Recording) {
        try? FileManager.default.removeItem(at: recording.fileURL)
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }

    func renameRecording(_ recording: Recording, to newName: String) {
        guard let index = recordings.firstIndex(where: { $0.id == recording.id }) else { return }

        let updated = Recording(
            id: recording.id,
            name: newName,
            duration: recording.duration,
            createdAt: recording.createdAt,
            fileName: recording.fileName
        )

        recordings[index] = updated
        saveRecordings()
    }

    // MARK: - Persistence

    private func loadRecordings() {
        guard let data = UserDefaults.standard.data(forKey: recordingsKey),
              let decoded = try? JSONDecoder().decode([Recording].self, from: data) else {
            return
        }

        // Filter out recordings whose files no longer exist
        recordings = decoded.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
    }

    private func saveRecordings() {
        guard let data = try? JSONEncoder().encode(recordings) else { return }
        UserDefaults.standard.set(data, forKey: recordingsKey)
    }
}

// MARK: - Playback Delegate

private class PlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.onFinish()
        }
    }
}
