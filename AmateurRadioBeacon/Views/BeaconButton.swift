import SwiftUI

/// Play/stop button for beacon control
struct BeaconButton: View {
    let isActive: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.red : Color.blue)
                    .frame(width: 72, height: 72)
                    .shadow(color: (isActive ? Color.red : Color.blue).opacity(0.4), radius: 8, y: 4)

                Image(systemName: isActive ? "stop.fill" : "play.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: isActive ? 0 : 2) // Visual centering for play icon
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled && !isActive)
        .opacity(isEnabled || isActive ? 1.0 : 0.4)
        .sensoryFeedback(.impact(weight: .medium), trigger: isActive)
        .accessibilityLabel(isActive ? "Stop beacon" : "Start beacon")
        .accessibilityHint(isActive ? "Double tap to stop transmitting" : "Double tap to begin transmitting")
    }
}

#Preview {
    HStack(spacing: 40) {
        BeaconButton(isActive: false, isEnabled: true, action: {})
        BeaconButton(isActive: true, isEnabled: true, action: {})
        BeaconButton(isActive: false, isEnabled: false, action: {})
    }
    .padding()
}
