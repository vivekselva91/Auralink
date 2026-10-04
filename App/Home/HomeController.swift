import HomeKit

/// Controls accessories through HomeKit (which includes Matter accessories added to the Home app).
/// Shared by the iOS and watchOS targets.
final class HomeController: NSObject, HMHomeManagerDelegate {
    var onAccessoriesChanged: (([(id: String, name: String)]) -> Void)?
    private let manager = HMHomeManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        let list = manager.homes.flatMap(\.accessories).map { (id: $0.uniqueIdentifier.uuidString, name: $0.name) }
        onAccessoriesChanged?(list)
    }

    func togglePower(deviceID: String) {
        guard let c = characteristic(deviceID, HMCharacteristicTypePowerState) else { return }
        c.readValue { error in
            guard error == nil, let on = c.value as? Bool else { return }
            c.writeValue(!on) { _ in }
        }
    }

    func setBrightness(deviceID: String, level: Double) {
        guard let c = characteristic(deviceID, HMCharacteristicTypeBrightness) else { return }
        c.writeValue(Int((level * 100).rounded())) { _ in }
    }

    /// Thermostat target. HomeKit stores temperatures in Celsius.
    func setTargetTemperature(deviceID: String, fahrenheit: Double) {
        guard let c = characteristic(deviceID, HMCharacteristicTypeTargetTemperature) else { return }
        c.writeValue((fahrenheit - 32) * 5 / 9) { _ in }
    }

    /// Blinds and other window coverings, 0 = closed, 100 = open.
    func setPosition(deviceID: String, percent: Double) {
        guard let c = characteristic(deviceID, HMCharacteristicTypeTargetPosition) else { return }
        c.writeValue(Int(percent.rounded())) { _ in }
    }

    /// Speakers that expose volume through HomeKit. AirPlay speakers may need AirPlay controls instead.
    func setVolume(deviceID: String, percent: Double) {
        guard let c = characteristic(deviceID, HMCharacteristicTypeVolume) else { return }
        c.writeValue(Int(percent.rounded())) { _ in }
    }

    /// Device kind, so the Watch knows which Crown profile to use.
    func kind(deviceID: String) -> String {
        guard let a = manager.homes.flatMap(\.accessories).first(where: { $0.uniqueIdentifier.uuidString == deviceID }) else { return "light" }
        switch a.category.categoryType {
        case HMAccessoryCategoryTypeThermostat: return "thermostat"
        case HMAccessoryCategoryTypeWindowCovering: return "blinds"
        default:
            return a.services.contains { $0.serviceType == HMServiceTypeSpeaker } ? "speaker" : "light"
        }
    }

    private func characteristic(_ deviceID: String, _ type: String) -> HMCharacteristic? {
        manager.homes.flatMap(\.accessories)
            .first { $0.uniqueIdentifier.uuidString == deviceID }?
            .services.flatMap(\.characteristics)
            .first { $0.characteristicType == type }
    }
}
