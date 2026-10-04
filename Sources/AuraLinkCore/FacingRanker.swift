import Foundation

/// Apple Watch: "the devices in front of you rise up."
///
/// The Watch has no camera, so it can't aim precisely like the iPhone. Instead it ranks
/// devices by how close they are to the direction you're facing (compass heading), so
/// facing roughly the right way is enough. Devices behind you are left out.
public struct FacingRanker {
    public var fieldOfViewDegrees = 120.0   // only devices within ±60° of your heading are listed
    public var maxResults = 4
    public init() {}

    public struct Ranked: Equatable {
        public let device: RegisteredDevice
        public let offsetDegrees: Double    // signed: negative = to your left, positive = to your right
        public let distance: Double
    }

    /// - Parameters:
    ///   - position: where you are in the room map (x, z on the floor plane; y ignored)
    ///   - headingDegrees: direction you're facing in the room map's frame (0 = map's -z axis, clockwise positive)
    public func rank(position: Vector3, headingDegrees: Double, devices: [RegisteredDevice]) -> [Ranked] {
        devices.compactMap { d -> Ranked? in
            let dx = d.position.x - position.x, dz = d.position.z - position.z
            let distance = (dx * dx + dz * dz).squareRoot()
            guard distance > 0.1 else { return nil }
            let bearing = atan2(dx, -dz) * 180 / .pi            // same convention as heading
            let offset = FacingRanker.wrap(bearing - headingDegrees)
            guard abs(offset) <= fieldOfViewDegrees / 2 else { return nil }
            return Ranked(device: d, offsetDegrees: offset, distance: distance)
        }
        // Closest to straight ahead first; distance breaks near-ties.
        .sorted { (abs($0.offsetDegrees) + $0.distance) < (abs($1.offsetDegrees) + $1.distance) }
        .prefix(maxResults)
        .map { $0 }
    }

    static func wrap(_ a: Double) -> Double {
        var x = a.truncatingRemainder(dividingBy: 360)
        if x > 180 { x -= 360 }
        if x < -180 { x += 360 }
        return x
    }
}
