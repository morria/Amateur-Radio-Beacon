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

                    // Important Notice
                    DisclaimerSection(
                        title: "Important Notice",
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange
                    ) {
                        Text("This app generates audio tones for use with amateur radio transmitters. It does not transmit radio signals directly.")
                    }

                    // Regulatory Compliance
                    DisclaimerSection(
                        title: "Regulatory Compliance",
                        icon: "checkmark.shield.fill",
                        iconColor: .green
                    ) {
                        Text("Operating a radio transmitter requires appropriate licensing. In the United States, beacon stations must comply with FCC Part 97 regulations. Users are responsible for ensuring compliance with all applicable laws and regulations in their jurisdiction.")
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

                    // Audio Simulator
                    DisclaimerSection(
                        title: "Audio Simulator",
                        icon: "speaker.wave.2.fill",
                        iconColor: .purple
                    ) {
                        Text("This app is an audio generator only. Connect the audio output to your transmitter's audio input. The app does not control RF transmission or provide any RF functionality.")
                    }

                    // Disclaimer
                    DisclaimerSection(
                        title: "Disclaimer",
                        icon: "doc.text.fill",
                        iconColor: .gray
                    ) {
                        Text("This software is provided as-is without warranty. The developer is not responsible for any misuse, regulatory violations, or interference caused by improper operation. Use at your own risk and responsibility.")
                    }

                    // Privacy
                    DisclaimerSection(
                        title: "Privacy",
                        icon: "lock.shield.fill",
                        iconColor: .blue
                    ) {
                        Text("This app does not collect, transmit, or share any personal data. Voice recordings are stored locally on your device and are never uploaded to any server.")
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
