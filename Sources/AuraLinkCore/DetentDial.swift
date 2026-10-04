import Foundation

/// The on-screen control dial. Continuous thumb input is quantized into detents (default 5%),
/// and every detent crossed produces one haptic tick, so it feels like a physical dial
/// and can be used without looking.
public struct DetentDial: Sendable {
    public let step: Double
    public private(set) var value: Double

    public init(value: Double = 0, step: Double = 0.05) {
        self.step = step
        self.value = DetentDial.quantize(value, step: step)
    }

    /// Feed a raw position (0...1). Returns how many detents were crossed (0 = no change).
    @discardableResult
    public mutating func set(_ raw: Double) -> Int {
        let q = DetentDial.quantize(raw, step: step)
        let crossed = Int(((q - value) / step).rounded())
        value = q
        return abs(crossed)
    }

    /// Maps a thumb angle on a 270° dial (-135° ... +135°, 0° = top) to 0...1.
    public static func position(forAngleDegrees a: Double) -> Double {
        min(1, max(0, (a + 135) / 270))
    }

    static func quantize(_ v: Double, step: Double) -> Double {
        let clamped = min(1, max(0, v))
        return min(1, (clamped / step).rounded() * step)
    }
}
