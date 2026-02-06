import SwiftUI

/// Main beacon station interface
struct BeaconView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel = BeaconViewModel()
    @State private var selectedMode: BeaconMode?
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            if let mode = selectedMode {
                beaconControlView(for: mode, showBackButton: false)
            } else {
                ContentUnavailableView(
                    "Select a Mode",
                    systemImage: "antenna.radiowaves.left.and.right",
                    description: Text("Choose a beacon mode from the sidebar to begin")
                )
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        .onAppear {
            if selectedMode == nil {
                selectedMode = .tone
            }
        }
    }

    private var sidebarView: some View {
        List(BeaconMode.allCases, selection: $selectedMode) { mode in
            sidebarRow(for: mode)
                .tag(mode)
        }
        .navigationTitle("Beacon")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                aboutButton
            }
        }
    }

    private func sidebarRow(for mode: BeaconMode) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.displayName)
                Text(mode.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: iconName(for: mode))
                .foregroundStyle(iconColor(for: mode))
        }
    }

    private func iconName(for mode: BeaconMode) -> String {
        switch mode {
        case .tone: return "waveform"
        case .cw: return "ellipsis.message"
        case .message: return "mic.fill"
        }
    }

    private func iconColor(for mode: BeaconMode) -> Color {
        switch mode {
        case .tone: return .blue
        case .cw: return .purple
        case .message: return .orange
        }
    }

    @State private var showingAbout = false

    private var aboutButton: some View {
        Button {
            showingAbout = true
        } label: {
            Image(systemName: "info.circle")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        NavigationStack {
            if let mode = selectedMode {
                beaconControlView(for: mode, showBackButton: true)
            } else {
                ModeSelectionView(selectedMode: $selectedMode)
            }
        }
    }

    @ViewBuilder
    private func beaconControlView(for mode: BeaconMode, showBackButton: Bool) -> some View {
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
        .navigationTitle(mode.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showBackButton {
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
        .onChange(of: viewModel.lastError as? NSError) { _, newError in
            if let error = newError {
                errorMessage = describeError(error)
                showingError = true
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func describeError(_ error: Error) -> String {
        switch error {
        case MorseCodeError.emptyText:
            return String(localized: "Please enter text to transmit.")
        case MorseCodeError.noMorseCharacters:
            return String(localized: "The text contains no valid Morse code characters.")
        case MorseCodeError.bufferCreationFailed:
            return String(localized: "Failed to generate audio. Please try again.")
        case RecordingService.RecordingError.fileNotFound:
            return String(localized: "Recording file not found. It may have been deleted.")
        case RecordingService.RecordingError.playbackFailed:
            return String(localized: "Failed to play recording. Please try again.")
        default:
            return error.localizedDescription
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
