import SwiftUI

/// Controls for CW (Morse code) mode
struct CWModeView: View {
    @Binding var text: String
    @Binding var wpm: Double
    let morsePreview: String
    let durationText: String
    let isPlaying: Bool
    let onPreview: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Text Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Enter text to transmit", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            // Morse Preview
            if !morsePreview.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Morse Code")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if !durationText.isEmpty {
                            Text(durationText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(morsePreview)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // WPM Slider
            VStack(spacing: 8) {
                HStack {
                    Text("Speed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(wpm)) WPM")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                }

                Slider(
                    value: $wpm,
                    in: MorseCodeService.minWPM...MorseCodeService.maxWPM,
                    step: 1
                )
                .tint(.blue)

                HStack {
                    Text("\(Int(MorseCodeService.minWPM)) WPM")
                    Spacer()
                    Text("\(Int(MorseCodeService.maxWPM)) WPM")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Preview Button
            Button {
                onPreview()
            } label: {
                Label(
                    isPlaying ? "Stop Preview" : "Preview",
                    systemImage: isPlaying ? "stop.fill" : "play.fill"
                )
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
        }
    }
}

#Preview {
    CWModeView(
        text: .constant("CQ CQ DE W1AW"),
        wpm: .constant(20),
        morsePreview: "-.-. --.- / -.-. --.- / -.. . / .-- .---- .- .--",
        durationText: "3.2s",
        isPlaying: false,
        onPreview: {}
    )
    .padding()
}
