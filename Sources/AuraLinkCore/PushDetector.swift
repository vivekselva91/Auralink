import Foundation

/// Detects a deliberate forward "push" of the phone (cast to the selected TV).
/// Input is CoreMotion user acceleration along the phone's pointing axis, in g.
/// A push is a sharp forward peak followed by a braking peak, both within a short window,
/// which separates it from walking or putting the phone down.
public final class PushDetector {
    public var forwardThreshold = 0.6   // g
    public var brakeThreshold = 0.4     // g (opposite sign)
    public var window = 0.35            // seconds between peaks
    private var forwardPeakTime: TimeInterval?

    public init() {}

    public func process(acceleration a: Double, time t: TimeInterval) -> Bool {
        if a > forwardThreshold { forwardPeakTime = t; return false }
        if let t0 = forwardPeakTime {
            if t - t0 > window { forwardPeakTime = nil; return false }
            if a < -brakeThreshold { forwardPeakTime = nil; return true }
        }
        return false
    }
}
