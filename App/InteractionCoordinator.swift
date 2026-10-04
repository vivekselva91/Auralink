import Foundation
import AuraLinkCore

/// Point to select. Control on the screen. Feel it.
///
///   POINTING:  rear camera + ARKit pose feed the PointingSelector. A haptic tap confirms lock-on.
///   CONTROL:   touching the on-screen dial freezes the selection, so the phone can be lowered
///              while adjusting. Pointing and touch run together; no mode switch is needed.
///   NO-LOOK (optional): pinch in the air to toggle. This needs the front camera, which can't run
///              alongside ARKit world tracking in a third-party app, so pointing pauses while it's on.
@MainActor
final class InteractionCoordinator: ObservableObject {
    enum Phase: Equatable { case idle, pointing, noLook }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var selectedName: String?
    @Published private(set) var selectionLocked = false
    @Published private(set) var dial = DetentDial()
    @Published private(set) var lastAction = ""

    let anchors = DeviceAnchorStore()
    private let selector = PointingSelector()
    private let pinch = PinchDetector()
    private let hand = HandPoseCapture()
    private let push = PushMotionMonitor()
    private let home = HomeController()
    private let haptics = Haptics()
    private let power = SessionPowerManager()
    private let watchSync = RoomMapSync()
    private var spots: [RoomMap.Spot] = []

    init() {
        anchors.onPose = { [weak self] origin, forward, time in
            self?.handlePose(origin: origin, forward: forward, time: time)
        }
        hand.onSample = { [weak self] sample in self?.handleHand(sample) }
        push.onPush = { [weak self] in self?.handlePush() }
        power.onIdleTimeout = { [weak self] in self?.stop() }
        watchSync.activate()
        home.onAccessoriesChanged = { [weak self] list in
            self?.anchors.knownAccessories = list.map { .init(id: $0.id, name: $0.name) }
        }
    }

    // MARK: Lifecycle

    func startPointing() {
        hand.stop()
        selectionLocked = false
        anchors.start()
        push.start()
        phase = .pointing
        power.activity()
    }

    func stop() {
        anchors.pause(); hand.stop(); push.stop()
        selector.clear(); selectedName = nil; selectionLocked = false
        phase = .idle
    }

    /// Optional no-look mode: pause pointing, keep the current selection, listen for a pinch.
    func startNoLook() {
        guard selector.selected != nil else { return }
        anchors.pause()
        hand.start()
        phase = .noLook
        haptics.modeChange()
        power.activity()
    }

    // MARK: Apple Watch

    /// Save where you're standing (e.g. "Sofa") so the Watch knows your position in this room.
    func saveSpot(named name: String) {
        guard let p = anchors.currentFloorPosition() else { return }
        spots.removeAll { $0.name == name }
        spots.append(.init(name: name, x: p.x, z: p.z))
        syncRoomMapToWatch()
    }

    /// Send device positions and spots to the Watch. Called after room setup.
    func syncRoomMapToWatch() {
        let devices = anchors.registeredDevices.map {
            RoomMap.Device(id: $0.id, name: $0.name, kind: home.kind(deviceID: $0.id), x: $0.position.x, z: $0.position.z)
        }
        watchSync.send(RoomMap(devices: devices, spots: spots))
    }

    // MARK: Control dial

    /// Called continuously while the thumb moves on the dial (position 0...1).
    func dialMoved(to position: Double) {
        guard let device = selector.selected else { return }
        selectionLocked = true              // freeze the selection while adjusting
        let crossed = dial.set(position)
        guard crossed > 0 else { return }
        haptics.detent()
        home.setBrightness(deviceID: device.id, level: dial.value)
        lastAction = "\(device.name) \(Int((dial.value * 100).rounded()))%"
        power.activity()
    }

    func dialReleased() {
        haptics.confirm()
        selectionLocked = false
    }

    func togglePower() {
        guard let device = selector.selected else { return }
        haptics.confirm()
        home.togglePower(deviceID: device.id)
        lastAction = "Toggled \(device.name)"
        power.activity()
    }

    // MARK: Sensor handlers

    private func handlePose(origin: Vector3, forward: Vector3, time: TimeInterval) {
        guard !selectionLocked else { return }
        let previous = selector.selected?.id
        let current = selector.update(origin: origin, forward: forward,
                                      devices: anchors.registeredDevices, time: time)
        if current?.id != previous {
            selectedName = current?.name
            if current != nil { haptics.selected() }
            power.activity()
        }
    }

    private func handleHand(_ sample: HandSample) {
        if pinch.process(sample) { togglePower() }
    }

    private func handlePush() {
        guard let device = selector.selected, device.name.localizedCaseInsensitiveContains("tv") else { return }
        haptics.confirm()
        lastAction = "Play on \(device.name): confirm in the AirPlay picker"
        // Third-party apps can't start AirPlay silently; the UI presents AVRoutePickerView.
        NotificationCenter.default.post(name: .auraLinkShowAirPlayPicker, object: nil)
    }
}

extension Notification.Name {
    static let auraLinkShowAirPlayPicker = Notification.Name("AuraLinkShowAirPlayPicker")
}
