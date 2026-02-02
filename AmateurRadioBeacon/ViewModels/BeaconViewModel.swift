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
        print("[BeaconViewModel] Setting up cadence callbacks")
        cadenceService.onStartTransmitting = { [weak self] in
            print("[BeaconViewModel] onStartTransmitting callback triggered")
            self?.startCurrentModeOutput()
        }

        cadenceService.onStopTransmitting = { [weak self] in
            print("[BeaconViewModel] onStopTransmitting callback triggered")
            self?.stopCurrentModeOutput()
        }
        print("[BeaconViewModel] Cadence callbacks set up")
    }

    private func setupPlaybackCompletionCallbacks() {
        print("[BeaconViewModel] Setting up playback completion callbacks")
        // Setup completion handlers for CW and message modes
        // These notify the cadence service when content finishes
        morseCode.onPlaybackComplete = { [weak self] in
            print("[BeaconViewModel] Morse code playback completed")
            guard let self = self, self.isBeaconActive else {
                print("[BeaconViewModel] Beacon not active, ignoring morse completion")
                return
            }
            self.cadenceService.contentDidFinish()
        }

        recordingService.onPlaybackComplete = { [weak self] in
            print("[BeaconViewModel] Recording playback completed")
            guard let self = self, self.isBeaconActive else {
                print("[BeaconViewModel] Beacon not active, ignoring recording completion")
                return
            }
            self.cadenceService.contentDidFinish()
        }
        print("[BeaconViewModel] Playback completion callbacks set up")
    }

    // MARK: - Beacon Control

    func startBeacon(mode: BeaconMode) {
        print("[BeaconViewModel] startBeacon called for mode: \(mode)")
        activeMode = mode
        syncSettingsToServices()
        print("[BeaconViewModel] Settings synced, starting cadence service")
        cadenceService.start()
        print("[BeaconViewModel] Cadence service started")
    }

    func stopBeacon() {
        print("[BeaconViewModel] stopBeacon called")
        cadenceService.stop()
        stopCurrentModeOutput()
        activeMode = nil
        print("[BeaconViewModel] Beacon stopped")
    }

    func toggleBeacon(mode: BeaconMode) {
        print("[BeaconViewModel] toggleBeacon called, isBeaconActive: \(isBeaconActive)")
        if isBeaconActive {
            stopBeacon()
        } else {
            startBeacon(mode: mode)
        }
    }

    // MARK: - Mode Output Control

    private func syncSettingsToServices() {
        toneGenerator.frequency = toneFrequency
        morseCode.wpm = cwWPM
    }

    private func startCurrentModeOutput() {
        print("[BeaconViewModel] startCurrentModeOutput called")
        guard let mode = activeMode else {
            print("[BeaconViewModel] ERROR: activeMode is nil!")
            return
        }

        print("[BeaconViewModel] Starting output for mode: \(mode)")

        do {
            switch mode {
            case .tone:
                print("[BeaconViewModel] Tone mode - frequency: \(toneFrequency)")
                toneGenerator.frequency = toneFrequency
                try toneGenerator.start()
                print("[BeaconViewModel] Tone started successfully")
                // Tone plays continuously, completion handled by cadence timer

            case .cw:
                print("[BeaconViewModel] CW mode - text: \(cwText), wpm: \(cwWPM)")
                guard !cwText.isEmpty else {
                    print("[BeaconViewModel] ERROR: CW text is empty!")
                    return
                }
                morseCode.wpm = cwWPM
                try morseCode.play(text: cwText)
                print("[BeaconViewModel] CW playback started successfully")
                // Completion handled by onPlaybackComplete callback

            case .message:
                print("[BeaconViewModel] Message mode - recording: \(String(describing: selectedRecording))")
                guard let recording = selectedRecording else {
                    print("[BeaconViewModel] ERROR: No recording selected!")
                    return
                }
                try recordingService.play(recording: recording)
                print("[BeaconViewModel] Recording playback started successfully")
                // Completion handled by onPlaybackComplete callback
            }
            lastError = nil
        } catch {
            lastError = error
            print("[BeaconViewModel] ERROR starting output: \(error)")
        }
    }

    private func stopCurrentModeOutput() {
        guard let mode = activeMode else { return }

        switch mode {
        case .tone:
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
            print("Failed to start recording: \(error)")
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
        print("[BeaconViewModel] previewTone called, isPlaying: \(toneGenerator.isPlaying)")
        if toneGenerator.isPlaying {
            toneGenerator.stop()
        } else {
            toneGenerator.frequency = toneFrequency
            do {
                try toneGenerator.start()
                lastError = nil
                print("[BeaconViewModel] Tone preview started")

                // Stop after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    print("[BeaconViewModel] Stopping tone preview after timeout")
                    self?.toneGenerator.stop()
                }
            } catch {
                lastError = error
                print("[BeaconViewModel] Failed to preview tone: \(error)")
            }
        }
    }

    func previewCW() {
        print("[BeaconViewModel] previewCW called, isPlaying: \(morseCode.isPlaying)")
        if morseCode.isPlaying {
            morseCode.stop()
        } else {
            guard !cwText.isEmpty else {
                print("[BeaconViewModel] CW text is empty, cannot preview")
                return
            }
            morseCode.wpm = cwWPM
            do {
                try morseCode.play(text: cwText)
                lastError = nil
                print("[BeaconViewModel] CW preview started")
            } catch {
                lastError = error
                print("[BeaconViewModel] Failed to preview CW: \(error)")
            }
        }
    }

    func previewRecording() {
        print("[BeaconViewModel] previewRecording called, isPlaying: \(recordingService.isPlaying)")
        if recordingService.isPlaying {
            recordingService.stopPlayback()
        } else {
            guard let recording = selectedRecording else {
                print("[BeaconViewModel] No recording selected, cannot preview")
                return
            }
            do {
                try recordingService.play(recording: recording)
                lastError = nil
                print("[BeaconViewModel] Recording preview started")
            } catch {
                lastError = error
                print("[BeaconViewModel] Failed to preview recording: \(error)")
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
