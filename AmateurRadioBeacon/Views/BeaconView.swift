import SwiftUI

/// Main beacon station interface
struct BeaconView: View {
    @State private var viewModel = BeaconViewModel()
    @State private var selectedMode: BeaconMode?

    var body: some View {
        NavigationStack {
            if let mode = selectedMode {
                beaconControlView(for: mode)
            } else {
                ModeSelectionView(selectedMode: $selectedMode)
            }
        }
    }

    @ViewBuilder
    private func beaconControlView(for mode: BeaconMode) -> some View {
        VStack(spacing: 0) {
            // Mode-specific controls
            ScrollView {
                VStack(spacing: 20) {
                    modeSpecificView(for: mode)
                        .padding(.horizontal)
                        .disabled(viewModel.isBeaconActive)

                    Divider()
                        .padding(.horizontal)

                    // Cadence Controls
                    CadenceControlsView(configuration: $viewModel.cadenceConfiguration)
                        .padding(.horizontal)
                        .disabled(viewModel.isBeaconActive)
                }
                .padding(.vertical)
            }

            Divider()

            // Play/Stop Button
            BeaconButton(
                isActive: viewModel.isBeaconActive,
                isEnabled: canStartBeacon(for: mode),
                action: { viewModel.toggleBeacon(mode: mode) }
            )
            .padding(.vertical, 24)
        }
        .navigationTitle(mode.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if viewModel.isBeaconActive {
                        viewModel.stopBeacon()
                    }
                    selectedMode = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Modes")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func modeSpecificView(for mode: BeaconMode) -> some View {
        switch mode {
        case .tone:
            ToneModeView(
                frequency: $viewModel.toneFrequency,
                duration: $viewModel.toneDuration,
                durationRange: BeaconViewModel.minToneDuration...BeaconViewModel.maxToneDuration,
                isPlaying: viewModel.toneGenerator.isPlaying,
                onPreview: { viewModel.previewTone() }
            )
        case .message:
            MessageModeView(
                recordings: viewModel.recordingService.recordings,
                selectedRecording: $viewModel.selectedRecording,
                isRecording: viewModel.recordingService.isRecording,
                recordingDuration: viewModel.recordingService.recordingDuration,
                isPlaying: viewModel.recordingService.isPlaying,
                onStartRecording: { Task { await viewModel.startNewRecording() } },
                onStopRecording: { viewModel.stopNewRecording() },
                onCancelRecording: { viewModel.cancelNewRecording() },
                onPreview: { viewModel.previewRecording() },
                onDelete: { recording in viewModel.deleteRecording(recording) }
            )
        case .cw:
            CWModeView(
                text: $viewModel.cwText,
                wpm: $viewModel.cwWPM,
                morsePreview: viewModel.morsePreview,
                durationText: viewModel.cwDurationText,
                isPlaying: viewModel.morseCode.isPlaying,
                onPreview: { viewModel.previewCW() }
            )
        }
    }

    private func canStartBeacon(for mode: BeaconMode) -> Bool {
        switch mode {
        case .tone:
            return true
        case .cw:
            return !viewModel.cwText.isEmpty
        case .message:
            return viewModel.selectedRecording != nil
        }
    }
}

#Preview {
    BeaconView()
}
