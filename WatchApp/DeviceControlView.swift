import SwiftUI
import WatchKit
import AuraLinkCore

/// Turn the Digital Crown to adjust; a haptic tick on every step.
/// Today's Crown simulates ticks with the Taptic Engine. The concept adds a braked Crown on premium
/// models, using CrownProfile.resistance(at:) to stiffen near the limits and stop hard at them.
struct DeviceControlView: View {
    @EnvironmentObject var model: WatchModel
    let id: String
    let name: String
    @State private var value: Double = 50
    @State private var lastSent: Double = -1

    var body: some View {
        let profile = model.profile(for: id)
        VStack(spacing: 6) {
            Text(name).font(.headline)
            Text("\(Int(profile.snap(value)))\(profile.unit)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            Gauge(value: profile.snap(value), in: profile.range) { EmptyView() }
                .gaugeStyle(.accessoryLinear).tint(.orange)
            Button("On / Off") { model.toggle(id) }
                .handGestureShortcut(.primaryAction)
        }
        .focusable()
        .digitalCrownRotation($value, from: profile.range.lowerBound, through: profile.range.upperBound,
                              by: profile.step, sensitivity: .medium, isContinuous: false,
                              isHapticFeedbackEnabled: true)
        .onChange(of: value) { _, newValue in
            let snapped = profile.snap(newValue)
            guard snapped != lastSent else { return }
            lastSent = snapped
            model.set(id, value: snapped)
        }
        .onAppear { value = (profile.range.lowerBound + profile.range.upperBound) / 2 }
    }
}
