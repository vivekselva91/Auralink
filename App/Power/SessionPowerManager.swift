import Foundation

/// The cameras and ARKit are the biggest power draws, so sensing only runs while the user is
/// actively pointing or adjusting. The front camera runs only in the optional no-look mode.
/// Two safety stops:
/// - stop everything after 10 s with no selection change or gesture
/// - stop when the device reports a serious thermal state
final class SessionPowerManager {
    var onIdleTimeout: (() -> Void)?
    var idleTimeout: TimeInterval = 10
    private var timer: Timer?

    init() {
        NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            if ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue {
                self?.onIdleTimeout?()
            }
        }
    }

    func activity() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            self?.onIdleTimeout?()
        }
    }
}
