import Foundation

/// A smart-home device registered at a position in the room (from ARKit anchors or UWB).
public struct RegisteredDevice: Equatable, Sendable {
    public let id: String
    public let name: String
    public let position: Vector3
    public init(id: String, name: String, position: Vector3) {
        self.id = id; self.name = name; self.position = position
    }
}

/// Picks the device the phone is pointing at.
///
/// Design choices (see docs/ARCHITECTURE.md):
/// - Angular cone, not ray-hit: devices are points, so we pick the smallest angle inside the cone.
/// - The cone widens with proximity, because a fixed angle is too strict for nearby devices.
/// - Hysteresis + dwell time stop the selection from flickering between neighbours.
public final class PointingSelector {
    public struct Config: Sendable {
        public var baseConeDegrees = 8.0        // acceptance cone at 3 m and beyond
        public var maxConeDegrees = 15.0        // cap for very close devices
        public var switchMarginDegrees = 3.0    // a new device must beat the current one by this much
        public var dwellSeconds = 0.25          // must stay best for this long before selection changes
        public init() {}
    }

    public private(set) var selected: RegisteredDevice?
    private var candidate: RegisteredDevice?
    private var candidateSince: TimeInterval = 0
    private let config: Config

    public init(config: Config = Config()) { self.config = config }

    /// Cone half-angle for a device at a given distance (wider when closer).
    func cone(forDistance d: Double) -> Double {
        guard d > 0 else { return config.maxConeDegrees }
        return min(config.maxConeDegrees, config.baseConeDegrees * max(1, 3.0 / d))
    }

    /// Returns the best device inside its cone, with its angle, ignoring hysteresis.
    public func bestMatch(origin: Vector3, forward: Vector3,
                          devices: [RegisteredDevice]) -> (RegisteredDevice, Double)? {
        devices
            .map { d -> (RegisteredDevice, Double, Double) in
                let toDevice = d.position - origin
                return (d, forward.angle(to: toDevice), toDevice.length)
            }
            .filter { $0.1 <= cone(forDistance: $0.2) }
            .min { $0.1 < $1.1 }
            .map { ($0.0, $0.1) }
    }

    /// Feed one pose sample (e.g. every ARFrame). Returns the stable selection.
    @discardableResult
    public func update(origin: Vector3, forward: Vector3,
                       devices: [RegisteredDevice], time: TimeInterval) -> RegisteredDevice? {
        guard let (best, bestAngle) = bestMatch(origin: origin, forward: forward, devices: devices) else {
            candidate = nil
            return selected
        }
        if best.id == selected?.id { candidate = nil; return selected }

        // Hysteresis: keep the current selection unless the new one is clearly better.
        if let current = selected {
            let currentAngle = forward.angle(to: current.position - origin)
            if currentAngle <= cone(forDistance: (current.position - origin).length),
               bestAngle > currentAngle - config.switchMarginDegrees {
                return selected
            }
        }
        // Dwell: the new device must stay best for `dwellSeconds`.
        if candidate?.id != best.id { candidate = best; candidateSince = time }
        if time - candidateSince >= config.dwellSeconds {
            selected = best
            candidate = nil
        }
        return selected
    }

    public func clear() { selected = nil; candidate = nil }
}
