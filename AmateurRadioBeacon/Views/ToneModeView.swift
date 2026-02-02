import SwiftUI

/// Controls for tone generator mode
struct ToneModeView: View {
    @Binding var frequency: Double
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

#Preview {
    ToneModeView(
        frequency: .constant(700),
        isPlaying: false,
        onPreview: {}
    )
    .padding()
}
