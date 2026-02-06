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

/// Duration input control with text field for direct entry
private struct DurationControl: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 4) {
                TextField("", text: $textValue)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 50)
                    .focused($isFocused)
                    .onAppear {
                        textValue = "\(Int(value))"
                    }
                    .onChange(of: value) { _, newValue in
                        if !isFocused {
                            textValue = "\(Int(newValue))"
                        }
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            applyTextValue()
                        }
                    }

                Text("sec")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func applyTextValue() {
        if let seconds = Double(textValue) {
            value = min(max(seconds, range.lowerBound), range.upperBound)
        }
        textValue = "\(Int(value))"
    }
}

#Preview {
    CadenceControlsView(
        configuration: .constant(CadenceConfiguration())
    )
    .padding()
}
