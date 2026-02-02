import SwiftUI

/// Controls for beacon transmission cadence
struct CadenceControlsView: View {
    @Binding var configuration: CadenceConfiguration

    var body: some View {
        VStack(spacing: 16) {
            // Continuous Toggle
            Toggle("Loop Continuously", isOn: $configuration.isContinuous)
                .tint(.blue)

            // Pause Duration (hidden when continuous)
            if !configuration.isContinuous {
                DurationControl(
                    label: "Pause Between Loops",
                    value: $configuration.pauseDuration,
                    range: CadenceConfiguration.minPauseDuration...CadenceConfiguration.maxPauseDuration
                )
            }
        }
    }
}

/// Duration input control with stepper and text display
private struct DurationControl: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
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
    CadenceControlsView(
        configuration: .constant(CadenceConfiguration())
    )
    .padding()
}
