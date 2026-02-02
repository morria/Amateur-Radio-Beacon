import AVFoundation
import Foundation
import os

/// Generates a real-time sine wave tone using AVAudioEngine
@Observable
final class ToneGeneratorService {
    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var sourceNode: AVAudioSourceNode?

    private(set) var isPlaying = false

    // Thread-safe state container for audio parameters accessed from audio thread
    private struct AudioState: Sendable {
        var frequency: Double = 700.0
        var amplitude: Double = 0.5
        var phase: Double = 0.0
    }

    @ObservationIgnored private let audioState = OSAllocatedUnfairLock(initialState: AudioState())

    /// Current frequency in Hz (200-2000)
    var frequency: Double = 700.0 {
        didSet {
            let clampedFrequency = min(max(frequency, Self.minFrequency), Self.maxFrequency)
            if frequency != clampedFrequency {
                frequency = clampedFrequency
            }
            audioState.withLock { state in
                state.frequency = clampedFrequency
            }
        }
    }

    /// Amplitude (0.0-1.0)
    var amplitude: Double = 0.5 {
        didSet {
            audioState.withLock { state in
                state.amplitude = amplitude
            }
        }
    }

    static let minFrequency: Double = 200.0
    static let maxFrequency: Double = 2000.0

    /// Common preset frequencies
    static let presetFrequencies: [(name: String, frequency: Double)] = [
        ("400 Hz", 400.0),
        ("700 Hz", 700.0),
        ("1000 Hz", 1000.0)
    ]

    @ObservationIgnored private var phaseIncrement: Double = 0.0

    func start() throws {
        guard !isPlaying else {
            print("[ToneGeneratorService] Already playing, ignoring start request")
            return
        }

        print("[ToneGeneratorService] Starting tone at \(frequency) Hz")

        try AudioSessionManager.shared.configureForPlayback()
        print("[ToneGeneratorService] Audio session configured for playback")

        // Capture current values for the audio thread
        let currentFrequency = frequency
        let currentAmplitude = amplitude

        // Initialize thread-safe parameters
        audioState.withLock { state in
            state.frequency = currentFrequency
            state.amplitude = currentAmplitude
            state.phase = 0.0
        }

        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate

        print("[ToneGeneratorService] Sample rate: \(sampleRate), channels: \(outputFormat.channelCount)")

        // Capture the lock for the audio callback - no self reference needed
        let stateLock = audioState

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            // Read and write parameters atomically under lock
            stateLock.withLock { state in
                let currentPhaseIncrement = (2.0 * Double.pi * state.frequency) / sampleRate

                for frame in 0..<Int(frameCount) {
                    let sample = Float(sin(state.phase) * state.amplitude)
                    state.phase += currentPhaseIncrement

                    // Keep phase in reasonable range to avoid floating point issues
                    if state.phase >= 2.0 * Double.pi {
                        state.phase -= 2.0 * Double.pi
                    }

                    for buffer in ablPointer {
                        let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                        buf?[frame] = sample
                    }
                }
            }

            return noErr
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: format)

        // Ensure mixer volume is up
        mainMixer.outputVolume = 1.0

        try engine.start()
        print("[ToneGeneratorService] Audio engine started successfully")
        print("[ToneGeneratorService] Engine isRunning: \(engine.isRunning)")
        print("[ToneGeneratorService] MainMixer outputVolume: \(mainMixer.outputVolume)")

        self.audioEngine = engine
        self.sourceNode = sourceNode
        isPlaying = true
        print("[ToneGeneratorService] Tone playback active, isPlaying: \(isPlaying)")
    }

    func stop() {
        audioEngine?.stop()
        if let sourceNode = sourceNode {
            audioEngine?.detach(sourceNode)
        }
        audioEngine = nil
        sourceNode = nil
        audioState.withLock { state in
            state.phase = 0.0
        }
        isPlaying = false
    }
}
