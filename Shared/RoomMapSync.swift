import Foundation
import WatchConnectivity
import AuraLinkCore

/// Sends the room map from iPhone to Apple Watch.
/// iPhone does the one-time room setup with its camera; the Watch has no camera, so it uses this map.
/// Add this file to both the iOS and watchOS targets.
struct RoomMap: Codable {
    struct Device: Codable { let id: String; let name: String; let kind: String; let x: Double; let z: Double }
    struct Spot: Codable { let name: String; let x: Double; let z: Double }   // places you often stand, e.g. "Sofa"
    var devices: [Device]
    var spots: [Spot]

    var registered: [RegisteredDevice] {
        devices.map { RegisteredDevice(id: $0.id, name: $0.name, position: Vector3($0.x, 0, $0.z)) }
    }
}

final class RoomMapSync: NSObject, WCSessionDelegate {
    var onReceive: ((RoomMap) -> Void)?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// iPhone side: send the latest map. Application context keeps only the newest copy,
    /// which is what we want, and it arrives even if the Watch app isn't running.
    func send(_ map: RoomMap) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        try? WCSession.default.updateApplicationContext(["roomMap": data])
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        guard let data = context["roomMap"] as? Data,
              let map = try? JSONDecoder().decode(RoomMap.self, from: data) else { return }
        DispatchQueue.main.async { self.onReceive?(map) }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif
}
