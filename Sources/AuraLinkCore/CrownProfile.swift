import Foundation

/// How the Digital Crown should feel for each kind of device.
/// Every model gets haptic ticks. Premium models with a braked Crown also get real resistance
/// near the ends of the range and a hard stop at the limit (see docs/CONCEPT.md).
public struct CrownProfile: Equatable, Sendable {
    public let range: ClosedRange<Double>
    public let step: Double            // one haptic tick per step
    public let unit: String
    public let resistanceZone: Double  // fraction of the range near each end where a braked Crown stiffens

    public static let light = CrownProfile(range: 0...100, step: 5, unit: "%", resistanceZone: 0.1)
    public static let thermostatF = CrownProfile(range: 60...80, step: 1, unit: "°F", resistanceZone: 0.15)
    public static let blinds = CrownProfile(range: 0...100, step: 10, unit: "% open", resistanceZone: 0.1)
    public static let volume = CrownProfile(range: 0...100, step: 5, unit: "%", resistanceZone: 0.2)

    /// Snap a raw Crown value to the nearest step inside the range.
    public func snap(_ v: Double) -> Double {
        let clamped = min(range.upperBound, max(range.lowerBound, v))
        return range.lowerBound + ((clamped - range.lowerBound) / step).rounded() * step
    }

    /// 0 = free turning, 1 = hard stop. Only braked Crowns use this; others ignore it.
    public func resistance(at v: Double) -> Double {
        let span = range.upperBound - range.lowerBound
        let fromEdge = min(v - range.lowerBound, range.upperBound - v) / span
        if fromEdge <= 0 { return 1 }
        if fromEdge >= resistanceZone { return 0 }
        return 1 - fromEdge / resistanceZone
    }
}
