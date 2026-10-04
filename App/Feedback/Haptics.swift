import CoreHaptics

/// Haptic language for AuraLink, so the user never has to look at the screen:
/// - selected:   one crisp tap when the pointer locks onto a device
/// - detent:     a light tick for every 5% step on the dial, like a physical dial
/// - confirm:    a double tap when a command is sent or the dial is released
/// - modeChange: a short soft buzz when entering no-look pinch mode
final class Haptics {
    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        try? engine?.start()
    }

    func selected()   { play([tap(0.0, intensity: 0.8, sharpness: 0.7)]) }
    func detent()     { play([tap(0.0, intensity: 0.35, sharpness: 0.9)]) }
    func confirm()    { play([tap(0.0, intensity: 0.9, sharpness: 0.5), tap(0.09, intensity: 0.9, sharpness: 0.5)]) }
    func modeChange() {
        play([CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [.init(parameterID: .hapticIntensity, value: 0.4),
                                         .init(parameterID: .hapticSharpness, value: 0.2)],
                            relativeTime: 0, duration: 0.12)])
    }

    private func tap(_ t: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [.init(parameterID: .hapticIntensity, value: intensity),
                                   .init(parameterID: .hapticSharpness, value: sharpness)],
                      relativeTime: t)
    }

    private func play(_ events: [CHHapticEvent]) {
        guard let engine, let pattern = try? CHHapticPattern(events: events, parameters: []) else { return }
        try? engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
    }
}
