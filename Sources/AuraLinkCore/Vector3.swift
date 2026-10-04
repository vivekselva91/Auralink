import Foundation

/// Minimal 3D vector so the core logic stays platform-independent and unit-testable.
public struct Vector3: Equatable, Sendable {
    public var x: Double, y: Double, z: Double
    public init(_ x: Double, _ y: Double, _ z: Double) { self.x = x; self.y = y; self.z = z }

    public static func - (a: Vector3, b: Vector3) -> Vector3 { Vector3(a.x - b.x, a.y - b.y, a.z - b.z) }
    public func dot(_ o: Vector3) -> Double { x * o.x + y * o.y + z * o.z }
    public var length: Double { sqrt(dot(self)) }
    public var normalized: Vector3 {
        let l = length
        return l > 0 ? Vector3(x / l, y / l, z / l) : self
    }
    /// Angle between two directions, in degrees.
    public func angle(to o: Vector3) -> Double {
        let c = max(-1, min(1, normalized.dot(o.normalized)))
        return acos(c) * 180 / .pi
    }
}
