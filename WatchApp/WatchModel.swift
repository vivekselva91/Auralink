import Foundation
import CoreLocation
import WatchKit
import AuraLinkCore

/// Raise your wrist; the devices in front of you rise up.
///
/// Position: in this prototype you pick where you're standing (a "spot" saved during iPhone setup).
/// A first-party version would get position automatically from HomePod and home-hub UWB anchors.
/// Heading: the Watch compass. The iPhone builds the room map with ARKit's gravity-and-heading
/// alignment, so the map's -z axis is north and compass heading needs no conversion.
@MainActor
final class WatchModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var inFront: [FacingRanker.Ranked] = []
    @Published private(set) var spots: [RoomMap.Spot] = []
    @Published var currentSpot: RoomMap.Spot?

    private var map = RoomMap(devices: [], spots: [])
    private let ranker = FacingRanker()
    private let location = CLLocationManager()
    private let sync = RoomMapSync()
    private let home = HomeController()          // shared with the iOS target
    private var heading: Double = 0
    private var lastTopID: String?

    override init() {
        super.init()
        location.delegate = self
        sync.onReceive = { [weak self] map in
            self?.map = map
            self?.spots = map.spots
            if self?.currentSpot == nil { self?.currentSpot = map.spots.first }
            self?.refresh()
        }
        sync.activate()
    }

    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        location.headingFilter = 3          // degrees; ignore tiny wobbles
        location.startUpdatingHeading()
    }

    func stop() { location.stopUpdatingHeading() }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.heading = h
            self.refresh()
        }
    }

    private func refresh() {
        guard let spot = currentSpot else { inFront = []; return }
        inFront = ranker.rank(position: Vector3(spot.x, 0, spot.z), headingDegrees: heading, devices: map.registered)
        if inFront.first?.device.id != lastTopID {
            lastTopID = inFront.first?.device.id
            if lastTopID != nil { WKInterfaceDevice.current().play(.click) }   // new device on top
        }
    }

    // MARK: Control

    func kind(of id: String) -> String { map.devices.first { $0.id == id }?.kind ?? "light" }

    func profile(for id: String) -> CrownProfile {
        switch kind(of: id) {
        case "thermostat": return .thermostatF
        case "blinds": return .blinds
        case "speaker": return .volume
        default: return .light
        }
    }

    func set(_ id: String, value: Double) {
        switch kind(of: id) {
        case "thermostat": home.setTargetTemperature(deviceID: id, fahrenheit: value)
        case "blinds": home.setPosition(deviceID: id, percent: value)
        case "speaker": home.setVolume(deviceID: id, percent: value)
        default: home.setBrightness(deviceID: id, level: value / 100)
        }
    }

    func toggle(_ id: String) {
        home.togglePower(deviceID: id)
        WKInterfaceDevice.current().play(.success)
    }
}
