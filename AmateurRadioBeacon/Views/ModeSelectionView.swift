import SwiftUI

/// Initial screen for selecting beacon mode
struct ModeSelectionView: View {
    @Binding var selectedMode: BeaconMode?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text("Select Mode")
                        .font(.largeTitle.bold())

                    Text("Choose a beacon type to configure")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                // Mode Cards
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ModeCard(
                            mode: .tone,
                            icon: "waveform",
                            iconColor: .blue,
                            subtitle: "Continuous",
                            description: "Pure sine wave tone at adjustable frequency."
                        ) {
                            selectedMode = .tone
                        }

                        ModeCard(
                            mode: .cw,
                            icon: "ellipsis.message",
                            iconColor: .purple,
                            badge: "CW",
                            subtitle: "Morse Code",
                            description: "Text converted to Morse code with adjustable speed."
                        ) {
                            selectedMode = .cw
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    ModeCard(
                        mode: .message,
                        icon: "mic.fill",
                        iconColor: .orange,
                        subtitle: "Voice",
                        description: "Record and loop a voice message."
                    ) {
                        selectedMode = .message
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// Card for a single beacon mode
private struct ModeCard: View {
    let mode: BeaconMode
    let icon: String
    let iconColor: Color
    var badge: String? = nil
    let subtitle: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(iconColor)
                    }

                    Spacer()

                    if let badge = badge {
                        Text(badge)
                            .font(.caption.bold())
                            .foregroundStyle(iconColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(iconColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModeSelectionView(selectedMode: .constant(nil))
}
