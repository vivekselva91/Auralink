import Foundation

/// One hand-pose sample from Vision (normalized image coordinates, 0...1).
public struct HandSample: Sendable {
    public let time: TimeInterval
    public let thumbTip: (x: Double, y: Double)
    public let indexTip: (x: Double, y: Double)
    public let confidence: Double
    public init(time: TimeInterval, thumbTip: (Double, Double), indexTip: (Double, Double), confidence: Double) {
        self.time = time; self.thumbTip = thumbTip; self.indexTip = indexTip; self.confidence = confidence
    }
}

/// Detects one air gesture: a pinch, used to toggle the selected device without looking at the screen.
///
/// v0.1 recognised five air gestures. v0.2 keeps only the pinch: once the phone is in your hand,
/// touch is faster and more precise for everything else (see docs/CONCEPT.md).
public final class PinchDetector {
    public struct Config: Sendable {
        public var minConfidence = 0.6
        public var closeDistance = 0.04   // thumb-index distance that counts as pinched
        public var openDistance = 0.08    // must re-open past this before the next pinch (hysteresis)
        public var cooldown = 0.5         // seconds between pinches
        public init() {}
    }

    private let config: Config
    private var pinched = false
    private var lastPinch: TimeInterval = -.infinity

    public init(config: Config = Config()) { self.config = config }

    /// Returns true once per pinch.
    public func process(_ s: HandSample) -> Bool {
        guard s.confidence >= config.minConfidence else { return false }
        let d = hypot(s.thumbTip.x - s.indexTip.x, s.thumbTip.y - s.indexTip.y)
        if !pinched && d < config.closeDistance && s.time - lastPinch > config.cooldown {
            pinched = true
            lastPinch = s.time
            return true
        }
        if pinched && d > config.openDistance { pinched = false }
        return false
    }
}
