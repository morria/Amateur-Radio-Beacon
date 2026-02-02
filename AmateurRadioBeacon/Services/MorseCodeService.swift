import AVFoundation
import Foundation

/// Errors that can occur during Morse code playback
enum MorseCodeError: Error {
    case emptyText
    case noMorseCharacters
    case bufferCreationFailed
    case audioFormatError
}

/// Converts text to Morse code audio
@Observable
final class MorseCodeService {
    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var playerNode: AVAudioPlayerNode?
    @ObservationIgnored private var audioBuffer: AVAudioPCMBuffer?

    private(set) var isPlaying = false

    /// Callback invoked when playback finishes
    @ObservationIgnored var onPlaybackComplete: (() -> Void)?

    /// Words per minute (5-40)
    var wpm: Double = 20.0 {
        didSet {
            let clamped = min(max(wpm, Self.minWPM), Self.maxWPM)
            if wpm != clamped {
                wpm = clamped
            }
        }
    }

    /// Tone frequency in Hz
    @ObservationIgnored var frequency: Double = 700.0

    /// Amplitude (0.0-1.0)
    @ObservationIgnored var amplitude: Double = 0.5

    static let minWPM: Double = 5.0
    static let maxWPM: Double = 40.0

    /// Morse code character mappings
    private static let morseCode: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".",
        "F": "..-.", "G": "--.", "H": "....", "I": "..", "J": ".---",
        "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---",
        "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-",
        "U": "..-", "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--",
        "Z": "--..",
        "0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
        "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.",
        "/": "-..-.", "?": "..--..", ".": ".-.-.-", ",": "--..--",
        "=": "-...-", "-": "-....-", "(": "-.--.", ")": "-.--.-",
        "@": ".--.-."
    ]

    /// Convert text to Morse code pattern string
    func textToMorse(_ text: String) -> String {
        var result: [String] = []

        for char in text.uppercased() {
            if char == " " {
                result.append(" ")
            } else if let morse = Self.morseCode[char] {
                result.append(morse)
            }
        }

        return result.joined(separator: " ")
    }

    /// Calculate dit duration in seconds based on WPM
    /// Standard: PARIS = 50 dits, so dit duration = 60 / (50 × WPM)
    private var ditDuration: Double {
        60.0 / (50.0 * wpm)
    }

    /// Generate audio buffer for the given text
    func generateAudio(for text: String, sampleRate: Double = 44100.0) -> AVAudioPCMBuffer? {
        let morse = textToMorse(text)
        guard !morse.isEmpty else { return nil }

        // Calculate total duration
        var totalDuration: Double = 0.0
        var previousWasElement = false

        for (index, char) in morse.enumerated() {
            // Add inter-element gap (1 dit) between elements within a character
            if previousWasElement && char != " " && index > 0 {
                let prevChar = morse[morse.index(morse.startIndex, offsetBy: index - 1)]
                if prevChar != " " {
                    totalDuration += ditDuration // Inter-element gap
                }
            }

            switch char {
            case ".":
                totalDuration += ditDuration
                previousWasElement = true
            case "-":
                totalDuration += ditDuration * 3
                previousWasElement = true
            case " ":
                // Check if this is a word space (double space in morse pattern)
                let nextIndex = morse.index(morse.startIndex, offsetBy: index + 1, limitedBy: morse.endIndex)
                if nextIndex != nil && index > 0 {
                    let prevChar = morse[morse.index(morse.startIndex, offsetBy: index - 1)]
                    if prevChar == " " {
                        totalDuration += ditDuration * 4 // Additional 4 dits for word space (total 7)
                    } else {
                        totalDuration += ditDuration * 3 // Inter-character gap
                    }
                } else {
                    totalDuration += ditDuration * 3
                }
                previousWasElement = false
            default:
                break
            }
        }

        let frameCount = AVAudioFrameCount(totalDuration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!,
            frameCapacity: frameCount
        ) else { return nil }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        // Fill buffer with silence
        for i in 0..<Int(frameCount) {
            channelData[i] = 0.0
        }

        // Generate tone segments
        var currentSample = 0
        let attackReleaseSamples = Int(0.005 * sampleRate) // 5ms attack/release
        previousWasElement = false

        for (index, char) in morse.enumerated() {
            // Add inter-element gap
            if previousWasElement && char != " " && index > 0 {
                let prevChar = morse[morse.index(morse.startIndex, offsetBy: index - 1)]
                if prevChar != " " {
                    currentSample += Int(ditDuration * sampleRate)
                }
            }

            switch char {
            case ".":
                let samples = Int(ditDuration * sampleRate)
                generateToneSegment(
                    into: channelData,
                    startSample: currentSample,
                    sampleCount: samples,
                    sampleRate: sampleRate,
                    attackReleaseSamples: attackReleaseSamples
                )
                currentSample += samples
                previousWasElement = true

            case "-":
                let samples = Int(ditDuration * 3 * sampleRate)
                generateToneSegment(
                    into: channelData,
                    startSample: currentSample,
                    sampleCount: samples,
                    sampleRate: sampleRate,
                    attackReleaseSamples: attackReleaseSamples
                )
                currentSample += samples
                previousWasElement = true

            case " ":
                let nextIndex = morse.index(morse.startIndex, offsetBy: index + 1, limitedBy: morse.endIndex)
                if nextIndex != nil && index > 0 {
                    let prevChar = morse[morse.index(morse.startIndex, offsetBy: index - 1)]
                    if prevChar == " " {
                        currentSample += Int(ditDuration * 4 * sampleRate)
                    } else {
                        currentSample += Int(ditDuration * 3 * sampleRate)
                    }
                } else {
                    currentSample += Int(ditDuration * 3 * sampleRate)
                }
                previousWasElement = false

            default:
                break
            }
        }

        return buffer
    }

    /// Generate a tone segment with envelope shaping
    private func generateToneSegment(
        into buffer: UnsafeMutablePointer<Float>,
        startSample: Int,
        sampleCount: Int,
        sampleRate: Double,
        attackReleaseSamples: Int
    ) {
        let phaseIncrement = (2.0 * Double.pi * frequency) / sampleRate

        for i in 0..<sampleCount {
            let sampleIndex = startSample + i
            let phase = phaseIncrement * Double(i)

            // Calculate envelope
            var envelope: Double = 1.0

            if i < attackReleaseSamples {
                // Attack phase - raised cosine
                envelope = 0.5 * (1.0 - cos(Double.pi * Double(i) / Double(attackReleaseSamples)))
            } else if i >= sampleCount - attackReleaseSamples {
                // Release phase - raised cosine
                let releaseIndex = i - (sampleCount - attackReleaseSamples)
                envelope = 0.5 * (1.0 + cos(Double.pi * Double(releaseIndex) / Double(attackReleaseSamples)))
            }

            let sample = Float(sin(phase) * amplitude * envelope)
            buffer[sampleIndex] = sample
        }
    }

    func play(text: String) throws {
        guard !isPlaying else {
            print("[MorseCodeService] Already playing, ignoring play request")
            return
        }
        guard !text.isEmpty else {
            print("[MorseCodeService] Empty text provided")
            throw MorseCodeError.emptyText
        }

        // Check if text produces any morse code
        let morse = textToMorse(text)
        guard !morse.isEmpty else {
            print("[MorseCodeService] No morse characters in text: \(text)")
            throw MorseCodeError.noMorseCharacters
        }

        print("[MorseCodeService] Starting playback for text: \(text)")
        print("[MorseCodeService] Morse pattern: \(morse)")

        try AudioSessionManager.shared.configureForPlayback()

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let mainMixer = engine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate

        print("[MorseCodeService] Sample rate: \(sampleRate)")

        guard let buffer = generateAudio(for: text, sampleRate: sampleRate) else {
            print("[MorseCodeService] Failed to generate audio buffer")
            throw MorseCodeError.bufferCreationFailed
        }

        print("[MorseCodeService] Generated buffer with \(buffer.frameLength) frames")

        // Use the buffer's format for connection
        let format = buffer.format
        engine.attach(player)
        engine.connect(player, to: mainMixer, format: format)

        try engine.start()
        print("[MorseCodeService] Audio engine started")

        self.audioEngine = engine
        self.playerNode = player
        self.audioBuffer = buffer
        isPlaying = true

        player.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.main.async {
                print("[MorseCodeService] Buffer playback completed")
                self?.isPlaying = false
                self?.onPlaybackComplete?()
            }
        }

        player.play()
        print("[MorseCodeService] Player started, isPlaying: \(player.isPlaying)")
        print("[MorseCodeService] Engine isRunning: \(engine.isRunning)")
    }

    func stop() {
        playerNode?.stop()
        audioEngine?.stop()
        if let player = playerNode {
            audioEngine?.detach(player)
        }
        audioEngine = nil
        playerNode = nil
        audioBuffer = nil
        isPlaying = false
    }

    /// Get the duration of the generated audio for given text
    func audioDuration(for text: String) -> TimeInterval {
        let morse = textToMorse(text)
        guard !morse.isEmpty else { return 0 }

        var totalDuration: Double = 0.0
        var previousWasElement = false

        for (index, char) in morse.enumerated() {
            if previousWasElement && char != " " && index > 0 {
                let prevChar = morse[morse.index(morse.startIndex, offsetBy: index - 1)]
                if prevChar != " " {
                    totalDuration += ditDuration
                }
            }

            switch char {
            case ".":
                totalDuration += ditDuration
                previousWasElement = true
            case "-":
                totalDuration += ditDuration * 3
                previousWasElement = true
            case " ":
                let nextIndex = morse.index(morse.startIndex, offsetBy: index + 1, limitedBy: morse.endIndex)
                if nextIndex != nil && index > 0 {
                    let prevChar = morse[morse.index(morse.startIndex, offsetBy: index - 1)]
                    if prevChar == " " {
                        totalDuration += ditDuration * 4
                    } else {
                        totalDuration += ditDuration * 3
                    }
                } else {
                    totalDuration += ditDuration * 3
                }
                previousWasElement = false
            default:
                break
            }
        }

        return totalDuration
    }
}
