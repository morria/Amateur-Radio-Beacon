import AVFoundation
import Foundation
import SwiftUI

/// Main view model coordinating all beacon functionality
@Observable
final class BeaconViewModel {
    // MARK: - Services

    let toneGenerator = ToneGeneratorService()
    let morseCode = MorseCodeService()
    let recordingService = RecordingService()
    let cadenceService = CadenceService()

    // MARK: - Active Mode

    private var activeMode: BeaconMode?

    // MARK: - Error State

    private(set) var lastError: Error?

    // MARK: - Tone Mode State

    var toneFrequency: Double = 700.0
    var toneDuration: Double = 5.0  // Duration in seconds per iteration

    static let minToneDuration: Double = 1.0
    static let maxToneDuration: Double = 60.0

    @ObservationIgnored private var toneDurationTimer: Timer?

    // MARK: - CW Mode State

    var cwText: String = ""
    var cwWPM: Double = 20.0

    var morsePreview: String {
        morseCode.textToMorse(cwText)
    }

    // MARK: - Message Mode State

    var selectedRecording: Recording?
    var isRecordingNew = false
    var newRecordingName = "New Recording"

    // MARK: - Cadence State

    var cadenceConfiguration: CadenceConfiguration {
        get { cadenceService.configuration }
        set { cadenceService.configuration = newValue }
    }

    // MARK: - Beacon State

    var isBeaconActive: Bool {
        cadenceService.isRunning
    }

    var currentPhase: CadencePhase {
        cadenceService.phase
    }

    // MARK: - Initialization

    init() {
        setupCadenceCallbacks()
        setupPlaybackCompletionCallbacks()
    }

    private func setupCadenceCallbacks() {
        Log.beacon.debug("[BeaconViewModel] Setting up cadence callbacks")
        cadenceService.onStartTransmitting = { [weak self] in
            Log.beacon.debug("[BeaconViewModel] onStartTransmitting callback triggered")
            self?.startCurrentModeOutput()
        }

        cadenceService.onStopTransmitting = { [weak self] in
            Log.beacon.debug("[BeaconViewModel] onStopTransmitting callback triggered")
            self?.stopCurrentModeOutput()
        }
        Log.beacon.debug("[BeaconViewModel] Cadence callbacks set up")
    }

    private func setupPlaybackCompletionCallbacks() {
        Log.beacon.debug("[BeaconViewModel] Setting up playback completion callbacks")
        // Setup completion handlers for CW and message modes
        // These notify the cadence service when content finishes
        morseCode.onPlaybackComplete = { [weak self] in
            Log.beacon.debug("[BeaconViewModel] Morse code playback completed")
            guard let self = self, self.isBeaconActive else {
                Log.beacon.debug("[BeaconViewModel] Beacon not active, ignoring morse completion")
                return
            }
            self.cadenceService.contentDidFinish()
        }

        recordingService.onPlaybackComplete = { [weak self] in
            Log.beacon.debug("[BeaconViewModel] Recording playback completed")
            guard let self = self, self.isBeaconActive else {
                Log.beacon.debug("[BeaconViewModel] Beacon not active, ignoring recording completion")
                return
            }
            self.cadenceService.contentDidFinish()
        }
        Log.beacon.debug("[BeaconViewModel] Playback completion callbacks set up")
    }

    // MARK: - Beacon Control

    func startBeacon(mode: BeaconMode) {
        Log.beacon.debug("[BeaconViewModel] startBeacon called for mode: \(mode)")
        activeMode = mode
        syncSettingsToServices()
        Log.beacon.debug("[BeaconViewModel] Settings synced, starting cadence service")
        cadenceService.start()
        Log.beacon.debug("[BeaconViewModel] Cadence service started")
    }

    func stopBeacon() {
        Log.beacon.debug("[BeaconViewModel] stopBeacon called")
        cadenceService.stop()
        stopCurrentModeOutput()
        activeMode = nil
        Log.beacon.debug("[BeaconViewModel] Beacon stopped")
    }

    func toggleBeacon(mode: BeaconMode) {
        Log.beacon.debug("[BeaconViewModel] toggleBeacon called, isBeaconActive: \(self.isBeaconActive)")
        if isBeaconActive {
            stopBeacon()
        } else {
            startBeacon(mode: mode)
        }
    }

    // MARK: - Mode Output Control

    private func syncSettingsToServices() {
        guard let mode = activeMode else { return }

        switch mode {
        case .tone:
            toneGenerator.frequency = toneFrequency
        case .cw:
            morseCode.wpm = cwWPM
        case .message:
            break // No settings to sync for message mode
        }
    }

    private func startCurrentModeOutput() {
        Log.beacon.debug("[BeaconViewModel] startCurrentModeOutput called")
        guard let mode = activeMode else {
            Log.beacon.debug("[BeaconViewModel] ERROR: activeMode is nil!")
            return
        }

        Log.beacon.debug("[BeaconViewModel] Starting output for mode: \(mode)")

        do {
            switch mode {
            case .tone:
                Log.beacon.debug("[BeaconViewModel] Tone mode - frequency: \(self.toneFrequency), duration: \(self.toneDuration)s")
                toneGenerator.frequency = toneFrequency
                try toneGenerator.start()
                Log.beacon.debug("[BeaconViewModel] Tone started successfully")

                // Set timer to signal completion after tone duration
                toneDurationTimer?.invalidate()
                toneDurationTimer = Timer.scheduledTimer(withTimeInterval: toneDuration, repeats: false) { [weak self] _ in
                    guard let self = self, self.isBeaconActive, self.activeMode == .tone else { return }
                    Log.beacon.debug("[BeaconViewModel] Tone duration elapsed, signaling completion")
                    self.toneGenerator.stop()
                    self.cadenceService.contentDidFinish()
                }

            case .cw:
                Log.beacon.debug("[BeaconViewModel] CW mode - text: \(self.cwText), wpm: \(self.cwWPM)")
                guard !cwText.isEmpty else {
                    Log.beacon.debug("[BeaconViewModel] ERROR: CW text is empty!")
                    return
                }
                morseCode.wpm = cwWPM
                try morseCode.play(text: cwText)
                Log.beacon.debug("[BeaconViewModel] CW playback started successfully")
                // Completion handled by onPlaybackComplete callback

            case .message:
                Log.beacon.debug("[BeaconViewModel] Message mode - recording: \(String(describing: self.selectedRecording))")
                guard let recording = selectedRecording else {
                    Log.beacon.debug("[BeaconViewModel] ERROR: No recording selected!")
                    return
                }
                try recordingService.play(recording: recording)
                Log.beacon.debug("[BeaconViewModel] Recording playback started successfully")
                // Completion handled by onPlaybackComplete callback
            }
            lastError = nil
        } catch {
            lastError = error
            Log.beacon.debug("[BeaconViewModel] ERROR starting output: \(error)")
        }
    }

    private func stopCurrentModeOutput() {
        guard let mode = activeMode else { return }

        switch mode {
        case .tone:
            toneDurationTimer?.invalidate()
            toneDurationTimer = nil
            toneGenerator.stop()
        case .cw:
            morseCode.stop()
        case .message:
            recordingService.stopPlayback()
        }
    }

    // MARK: - Recording Management

    func startNewRecording() async {
        isRecordingNew = true
        do {
            _ = try await recordingService.startRecording(name: newRecordingName)
            lastError = nil
        } catch {
            lastError = error
            isRecordingNew = false
            Log.recording.error("Failed to start recording: \(error)")
        }
    }

    func stopNewRecording() {
        if let recording = recordingService.stopRecording() {
            selectedRecording = recording
        }
        isRecordingNew = false
        newRecordingName = "New Recording"
    }

    func cancelNewRecording() {
        recordingService.cancelRecording()
        isRecordingNew = false
        newRecordingName = "New Recording"
    }

    func deleteRecording(_ recording: Recording) {
        if selectedRecording?.id == recording.id {
            selectedRecording = nil
        }
        recordingService.deleteRecording(recording)
    }

    // MARK: - Preview Playback

    func previewTone() {
        Log.beacon.debug("[BeaconViewModel] previewTone called, isPlaying: \(self.toneGenerator.isPlaying)")
        if toneGenerator.isPlaying {
            toneGenerator.stop()
        } else {
            toneGenerator.frequency = toneFrequency
            do {
                try toneGenerator.start()
                lastError = nil
                Log.beacon.debug("[BeaconViewModel] Tone preview started")

                // Stop after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    Log.beacon.debug("[BeaconViewModel] Stopping tone preview after timeout")
                    self?.toneGenerator.stop()
                }
            } catch {
                lastError = error
                Log.beacon.debug("[BeaconViewModel] Failed to preview tone: \(error)")
            }
        }
    }

    func previewCW() {
        Log.beacon.debug("[BeaconViewModel] previewCW called, isPlaying: \(self.morseCode.isPlaying)")
        if morseCode.isPlaying {
            morseCode.stop()
        } else {
            guard !cwText.isEmpty else {
                Log.beacon.debug("[BeaconViewModel] CW text is empty, cannot preview")
                return
            }
            morseCode.wpm = cwWPM
            do {
                try morseCode.play(text: cwText)
                lastError = nil
                Log.beacon.debug("[BeaconViewModel] CW preview started")
            } catch {
                lastError = error
                Log.beacon.debug("[BeaconViewModel] Failed to preview CW: \(error)")
            }
        }
    }

    func previewRecording() {
        Log.beacon.debug("[BeaconViewModel] previewRecording called, isPlaying: \(self.recordingService.isPlaying)")
        if recordingService.isPlaying {
            recordingService.stopPlayback()
        } else {
            guard let recording = selectedRecording else {
                Log.beacon.debug("[BeaconViewModel] No recording selected, cannot preview")
                return
            }
            do {
                try recordingService.play(recording: recording)
                lastError = nil
                Log.beacon.debug("[BeaconViewModel] Recording preview started")
            } catch {
                lastError = error
                Log.beacon.debug("[BeaconViewModel] Failed to preview recording: \(error)")
            }
        }
    }

    // MARK: - Computed Properties

    var cwDuration: TimeInterval {
        morseCode.audioDuration(for: cwText)
    }

    var cwDurationText: String {
        let duration = cwDuration
        if duration < 1 {
            return ""
        }
        return String(format: "%.1fs", duration)
    }
}
