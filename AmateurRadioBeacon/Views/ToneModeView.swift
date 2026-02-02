import SwiftUI

/// Controls for tone generator mode
struct ToneModeView: View {
    @Binding var frequency: Double
    @Binding var duration: Double
    let durationRange: ClosedRange<Double>
    let isPlaying: Bool
    let onPreview: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Frequency Display
            VStack(spacing: 4) {
                Text("Frequency")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(Int(frequency)) Hz")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            // Frequency Slider
            VStack(spacing: 8) {
                Slider(
                    value: $frequency,
                    in: ToneGeneratorService.minFrequency...ToneGeneratorService.maxFrequency,
                    step: 10
                )
                .tint(.blue)

                HStack {
                    Text("\(Int(ToneGeneratorService.minFrequency)) Hz")
                    Spacer()
                    Text("\(Int(ToneGeneratorService.maxFrequency)) Hz")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Preset Buttons
            HStack(spacing: 12) {
                ForEach(ToneGeneratorService.presetFrequencies, id: \.frequency) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            frequency = preset.frequency
                        }
                    } label: {
                        Text(preset.name)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                frequency == preset.frequency
                                    ? Color.blue
                                    : Color(.systemGray5)
                            )
                            .foregroundStyle(
                                frequency == preset.frequency
                                    ? .white
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Tone Duration Control
            ToneDurationControl(
                value: $duration,
                range: durationRange
            )

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
        }
    }
}

/// Duration control for tone length
private struct ToneDurationControl: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 12) {
            Text("Tone Duration")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    adjustValue(by: -1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)

                Text(formatDuration(value))
                    .font(.system(.body, design: .monospaced))
                    .monospacedDigit()
                    .frame(minWidth: 50)

                Button {
                    adjustValue(by: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func adjustValue(by delta: Double) {
        let newValue = value + delta
        value = min(max(newValue, range.lowerBound), range.upperBound)
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds >= 60 {
            let minutes = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(minutes)m \(secs)s"
        } else {
            return "\(Int(seconds))s"
        }
    }
}

#Preview {
    ToneModeView(
        frequency: .constant(700),
        duration: .constant(5),
        durationRange: 1...60,
        isPlaying: false,
        onPreview: {}
    )
    .padding()
}
