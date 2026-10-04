import Foundation

/// Directional haptics for the AuraLink band: 4 motors around the wrist.
/// People reliably tell apart only about 4 vibration spots around the wrist, so we use 4 zones.
public enum HapticZone: Equatable, Sendable { case ahead, right, behind, left }

public enum HapticDirection {
    /// Maps a device's offset from your heading (degrees, negative = left) to a band zone.
    public static func zone(forOffsetDegrees offset: Double) -> HapticZone {
        let a = FacingRanker.wrap(offset)
        switch a {
        case -45...45: return .ahead
        case 45...135: return .right
        case -135 ..< -45: return .left
        default: return .behind
        }
    }
}
