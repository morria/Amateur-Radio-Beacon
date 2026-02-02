import SwiftUI

/// Controls for recorded message mode
struct MessageModeView: View {
    let recordings: [Recording]
    @Binding var selectedRecording: Recording?
    let isRecording: Bool
    let recordingDuration: TimeInterval
    let isPlaying: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onCancelRecording: () -> Void
    let onPreview: () -> Void
    let onDelete: (Recording) -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Recording List
            VStack(alignment: .leading, spacing: 8) {
                Text("Recordings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if recordings.isEmpty && !isRecording {
                    Text("No recordings yet")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 30)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    VStack(spacing: 0) {
                        ForEach(recordings) { recording in
                            RecordingRow(
                                recording: recording,
                                isSelected: selectedRecording?.id == recording.id,
                                onSelect: { selectedRecording = recording },
                                onDelete: { onDelete(recording) }
                            )

                            if recording.id != recordings.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Recording Controls
            if isRecording {
                recordingInProgressView
            } else {
                recordingIdleView
            }
        }
    }

    private var recordingInProgressView: some View {
        VStack(spacing: 16) {
            // Recording indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 12, height: 12)

                Text("Recording...")
                    .font(.headline)

                Spacer()

                Text(formatDuration(recordingDuration))
                    .font(.system(.title2, design: .monospaced))
                    .monospacedDigit()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Stop/Cancel buttons
            HStack(spacing: 12) {
                Button {
                    onCancelRecording()
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    onStopRecording()
                } label: {
                    Label("Save", systemImage: "checkmark")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recordingIdleView: some View {
        VStack(spacing: 12) {
            // Record new button
            Button {
                onStartRecording()
            } label: {
                Label("Record New Message", systemImage: "mic.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            // Preview button
            if selectedRecording != nil {
                Button {
                    onPreview()
                } label: {
                    Label(
                        isPlaying ? "Stop Preview" : "Preview Selected",
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

/// Individual recording row
private struct RecordingRow: View {
    let recording: Recording
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onSelect()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .blue : .secondary)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recording.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)

                        Text(recording.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}

#Preview {
    MessageModeView(
        recordings: [
            Recording(name: "CQ Call", duration: 5.2, fileName: "test1.m4a"),
            Recording(name: "ID Message", duration: 3.8, fileName: "test2.m4a")
        ],
        selectedRecording: .constant(nil),
        isRecording: false,
        recordingDuration: 0,
        isPlaying: false,
        onStartRecording: {},
        onStopRecording: {},
        onCancelRecording: {},
        onPreview: {},
        onDelete: { _ in }
    )
    .padding()
}
