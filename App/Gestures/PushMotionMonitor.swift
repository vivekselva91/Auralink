import CoreMotion
import AuraLinkCore

/// Watches device motion for a forward "push" (used to cast to the selected TV).
final class PushMotionMonitor {
    var onPush: (() -> Void)?
    private let motion = CMMotionManager()
    private let detector = PushDetector()

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 100.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            // Device z points out of the screen toward the user, so pushing toward the TV is -z.
            let forward = -data.userAcceleration.z
            if self.detector.process(acceleration: forward, time: data.timestamp) { self.onPush?() }
        }
    }

    func stop() { motion.stopDeviceMotionUpdates() }
}
