import NearbyInteraction
import AuraLinkCore

/// Optional UWB refinement. Where a device (or a nearby anchor such as a UWB-equipped hub)
/// supports Nearby Interaction, distance and direction from UWB can confirm the ARKit selection
/// and relocalize faster. Most lamps and plugs have no UWB radio today, which is why ARKit
/// anchors are the primary method and UWB is a refinement.
final class UWBRanging: NSObject, NISessionDelegate {
    var onUpdate: ((_ distanceMeters: Float, _ direction: Vector3?) -> Void)?
    private var session: NISession?

    /// `accessoryData` comes from the accessory over Bluetooth, per Apple's Nearby Interaction accessory protocol.
    func start(accessoryData: Data) throws {
        guard NISession.deviceCapabilities.supportsPreciseDistanceMeasurement else { return }
        let config = try NINearbyAccessoryConfiguration(data: accessoryData)
        let s = NISession()
        s.delegate = self
        s.run(config)
        session = s
    }

    func stop() { session?.invalidate(); session = nil }

    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let obj = nearbyObjects.first, let d = obj.distance else { return }
        let dir = obj.direction.map { Vector3(Double($0.x), Double($0.y), Double($0.z)) }
        onUpdate?(d, dir)
    }

    // The accessory must also receive shareable configuration data over Bluetooth;
    // see Apple's "Implementing spatial interactions with third-party accessories".
    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data,
                 for object: NINearbyObject) {}
}
