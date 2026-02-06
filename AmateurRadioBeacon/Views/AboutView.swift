import SwiftUI

/// Legal disclaimers and app information
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Info
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)

                        Text("Amateur Radio Beacon")
                            .font(.title2.bold())

                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)

                    Divider()

                    // What This App Does
                    DisclaimerSection(
                        title: "What This App Does",
                        icon: "antenna.radiowaves.left.and.right",
                        iconColor: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connect your device to your radio's audio input to:")
                            BulletPoint("Play a continuous tone while tuning your antenna or testing your setup")
                            BulletPoint("Transmit Morse code (CW) beacons from text you enter")
                            BulletPoint("Loop a recorded voice message for ID or beacon operation")
                            Text("Set the cadence to control how often transmissions repeat, with configurable on-air and off-air intervals.")
                                .padding(.top, 4)
                        }
                    }

                    // VOX Recommendation
                    DisclaimerSection(
                        title: "VOX Recommendation",
                        icon: "mic.fill",
                        iconColor: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For best results, enable VOX (voice-operated transmit) on your transceiver.")
                            Text("This app outputs audio only (tone, CW, or voice). It does not control PTT or key your transmitter directly. Your transceiver must be configured to key from the audio input.")
                        }
                    }

                    // License Requirements
                    DisclaimerSection(
                        title: "License Requirements",
                        icon: "person.text.rectangle.fill",
                        iconColor: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Before using this app with a transmitter:")
                            BulletPoint("Obtain a valid amateur radio license")
                            BulletPoint("Ensure your license class permits beacon operation")
                            BulletPoint("Operate only on authorized frequencies")
                            BulletPoint("Follow proper station identification procedures")
                        }
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct DisclaimerSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
            }

            content()
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
            Text(text)
        }
    }
}

#Preview {
    AboutView()
}
