import Foundation

/// Manages the beacon transmission timing cycle
@Observable
final class CadenceService {
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var phaseStartTime: Date?

    private(set) var phase: CadencePhase = .idle
    private(set) var timeRemaining: TimeInterval = 0

    var configuration = CadenceConfiguration()

    /// Callbacks for phase changes
    @ObservationIgnored var onStartTransmitting: (() -> Void)?
    @ObservationIgnored var onStopTransmitting: (() -> Void)?

    var isRunning: Bool {
        phase != .idle
    }

    func start() {
        guard !isRunning else {
            print("[CadenceService] Already running, ignoring start request")
            return
        }
        print("[CadenceService] Starting cadence")
        startTransmitting()
    }

    func stop() {
        print("[CadenceService] Stopping cadence")
        timer?.invalidate()
        timer = nil
        phaseStartTime = nil

        if phase == .transmitting {
            print("[CadenceService] Calling onStopTransmitting")
            onStopTransmitting?()
        }

        phase = .idle
        timeRemaining = 0
        print("[CadenceService] Cadence stopped, phase is now idle")
    }

    /// Called when content playback finishes (for CW/message modes)
    /// This triggers the pause phase if not continuous
    func contentDidFinish() {
        print("[CadenceService] Content did finish, phase: \(phase), isContinuous: \(configuration.isContinuous)")
        guard phase == .transmitting else {
            print("[CadenceService] Not transmitting, ignoring contentDidFinish")
            return
        }

        if configuration.isContinuous {
            // Immediately restart
            print("[CadenceService] Continuous mode - restarting transmission")
            onStartTransmitting?()
        } else {
            // Start pause phase
            print("[CadenceService] Starting wait phase")
            startWaiting()
        }
    }

    private func startTransmitting() {
        phase = .transmitting
        timeRemaining = 0
        print("[CadenceService] Phase set to transmitting, calling onStartTransmitting")
        print("[CadenceService] onStartTransmitting is \(onStartTransmitting == nil ? "nil" : "set")")
        onStartTransmitting?()
        print("[CadenceService] onStartTransmitting callback completed")
    }

    private func startWaiting() {
        onStopTransmitting?()
        phase = .waiting
        timeRemaining = configuration.pauseDuration
        phaseStartTime = Date()

        // Start timer for pause duration
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateWaitingTimer()
        }
    }

    private func updateWaitingTimer() {
        guard let startTime = phaseStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = configuration.pauseDuration - elapsed
        timeRemaining = max(0, remaining)

        if remaining <= 0 {
            timer?.invalidate()
            timer = nil
            startTransmitting()
        }
    }

    /// Format time remaining for display
    var formattedTimeRemaining: String {
        if phase != .waiting {
            return ""
        }

        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
