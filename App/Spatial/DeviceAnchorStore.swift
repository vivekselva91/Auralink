import ARKit
import AuraLinkCore

/// Spatial map of smart-home devices.
/// Setup: the user aims at each accessory and taps; we raycast to the surface and drop an ARAnchor.
/// Runtime: every ARFrame gives the phone's 6-DoF pose; we pass origin + pointing direction to the selector.
/// On LiDAR iPhones, scene reconstruction makes the setup raycast land on real geometry.
final class DeviceAnchorStore: NSObject, ARSessionDelegate {
    struct AccessoryRef { let id: String; let name: String }

    var onPose: ((Vector3, Vector3, TimeInterval) -> Void)?
    var knownAccessories: [AccessoryRef] = []
    private(set) var registeredDevices: [RegisteredDevice] = []

    private let session = ARSession()
    private let prefix = "auralink:"
    private var names: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: "auralink.names") as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "auralink.names") }
    }
    private var mapURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("room.worldmap")
    }

    var unplacedAccessories: [AccessoryRef] {
        let placed = Set(registeredDevices.map(\.id))
        return knownAccessories.filter { !placed.contains($0.id) }
    }

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        // Align the map to the compass (-z = north) so Apple Watch heading can be used directly.
        config.worldAlignment = .gravityAndHeading
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh          // LiDAR devices only
        }
        if let data = try? Data(contentsOf: mapURL),
           let map = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
            config.initialWorldMap = map                // relocalize into the saved room
        }
        session.run(config)
    }

    func pause() { session.pause() }

    func placeAnchor(for accessory: AccessoryRef) {
        guard let frame = session.currentFrame else { return }
        var transform = frame.camera.transform
        let query = frame.raycastQuery(from: CGPoint(x: 0.5, y: 0.5), allowing: .estimatedPlane, alignment: .any)
        if let hit = session.raycast(query).first {
            transform = hit.worldTransform
        } else {
            transform.columns.3 += -2.0 * transform.columns.2   // fallback: 2 m straight ahead
        }
        session.add(anchor: ARAnchor(name: prefix + accessory.id, transform: transform))
        names[accessory.id] = accessory.name
    }

    /// Where the phone is right now on the floor plane, for saving "spots" the Watch can use.
    func currentFloorPosition() -> (x: Double, z: Double)? {
        guard let p = session.currentFrame?.camera.transform.columns.3 else { return nil }
        return (Double(p.x), Double(p.z))
    }

    func saveWorldMap() {
        session.getCurrentWorldMap { [mapURL] map, _ in
            guard let map,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
            else { return }
            try? data.write(to: mapURL, options: .atomic)
        }
    }

    // MARK: ARSessionDelegate

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        registeredDevices = frame.anchors.compactMap { anchor in
            guard let name = anchor.name, name.hasPrefix(prefix) else { return nil }
            let id = String(name.dropFirst(prefix.count))
            let p = anchor.transform.columns.3
            return RegisteredDevice(id: id, name: names[id] ?? id, position: Vector3(Double(p.x), Double(p.y), Double(p.z)))
        }
        // Only trust the pose when tracking is normal; limited tracking causes wrong selections.
        guard case .normal = frame.camera.trackingState else { return }
        let t = frame.camera.transform
        let origin = Vector3(Double(t.columns.3.x), Double(t.columns.3.y), Double(t.columns.3.z))
        // The rear camera looks along the camera's -Z axis: that is the "pointing" direction.
        let forward = Vector3(Double(-t.columns.2.x), Double(-t.columns.2.y), Double(-t.columns.2.z))
        onPose?(origin, forward, frame.timestamp)
    }
}
