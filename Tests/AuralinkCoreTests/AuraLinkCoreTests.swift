import XCTest
@testable import AuraLinkCore

final class PointingSelectorTests: XCTestCase {
    let lamp = RegisteredDevice(id: "lamp", name: "Floor Lamp", position: Vector3(0, 0, -1.5))
    let tv = RegisteredDevice(id: "tv", name: "TV", position: Vector3(0.5, 0, -1.5))   // about 18 degrees from lamp, 1.6 m away

    func testSelectsDeviceInsideCone() {
        let s = PointingSelector()
        let match = s.bestMatch(origin: Vector3(0, 0, 0), forward: Vector3(0, 0, -1), devices: [lamp, tv])
        XCTAssertEqual(match?.0.id, "lamp")
    }

    func testIgnoresDeviceOutsideCone() {
        let s = PointingSelector()
        let match = s.bestMatch(origin: Vector3(0, 0, 0), forward: Vector3(0, 1, 0), devices: [lamp, tv])
        XCTAssertNil(match)
    }

    func testDwellPreventsInstantSelection() {
        let s = PointingSelector()
        let o = Vector3(0, 0, 0), f = Vector3(0, 0, -1)
        XCTAssertNil(s.update(origin: o, forward: f, devices: [lamp], time: 0.0))
        XCTAssertNil(s.update(origin: o, forward: f, devices: [lamp], time: 0.1))
        XCTAssertEqual(s.update(origin: o, forward: f, devices: [lamp], time: 0.3)?.id, "lamp")
    }

    func testHysteresisKeepsSelectionBetweenNeighbours() {
        let s = PointingSelector()
        let o = Vector3(0, 0, 0)
        _ = s.update(origin: o, forward: Vector3(0, 0, -1), devices: [lamp, tv], time: 0)
        _ = s.update(origin: o, forward: Vector3(0, 0, -1), devices: [lamp, tv], time: 0.3)
        // Aim just past the midpoint: TV is about 1.5 degrees closer, less than the 3 degree margin.
        let nearMid = Vector3(0.27, 0, -1.5)
        for t in stride(from: 0.4, through: 1.0, by: 0.1) {
            _ = s.update(origin: o, forward: nearMid, devices: [lamp, tv], time: t)
        }
        XCTAssertEqual(s.selected?.id, "lamp")
    }

    func testSixSimilarLampsPicksTheOneAimedAt() {
        // Six lamps 0.6 m apart on a wall 3 m away: the "room full of similar devices" case.
        let lamps = (0..<6).map { RegisteredDevice(id: "lamp\($0)", name: "Lamp", position: Vector3(Double($0) * 0.6 - 1.5, 0, -3)) }
        let s = PointingSelector()
        let match = s.bestMatch(origin: Vector3(0, 0, 0), forward: Vector3(0.3, 0, -3), devices: lamps)
        XCTAssertEqual(match?.0.id, "lamp3")
    }
}

final class DetentDialTests: XCTestCase {
    func testQuantizesToFivePercentSteps() {
        var d = DetentDial()
        d.set(0.43)
        XCTAssertEqual(d.value, 0.45, accuracy: 1e-9)
    }

    func testReportsDetentsCrossed() {
        var d = DetentDial(value: 0.5)
        XCTAssertEqual(d.set(0.62), 2)   // 0.50 -> 0.60
        XCTAssertEqual(d.set(0.61), 0)   // still 0.60: no tick
        XCTAssertEqual(d.set(0.40), 4)   // 0.60 -> 0.40
    }

    func testClampsToRange() {
        var d = DetentDial()
        d.set(1.4)
        XCTAssertEqual(d.value, 1.0, accuracy: 1e-9)
        d.set(-0.2)
        XCTAssertEqual(d.value, 0.0, accuracy: 1e-9)
    }

    func testAngleMapping() {
        XCTAssertEqual(DetentDial.position(forAngleDegrees: -135), 0, accuracy: 1e-9)
        XCTAssertEqual(DetentDial.position(forAngleDegrees: 0), 0.5, accuracy: 1e-9)
        XCTAssertEqual(DetentDial.position(forAngleDegrees: 135), 1, accuracy: 1e-9)
    }
}

final class PinchDetectorTests: XCTestCase {
    func sample(_ t: Double, gap: Double, confidence: Double = 0.9) -> HandSample {
        HandSample(time: t, thumbTip: (0.5, 0.5), indexTip: (0.5 + gap, 0.5), confidence: confidence)
    }

    func testPinchFiresOncePerClose() {
        let p = PinchDetector()
        let fired = [0.10, 0.03, 0.02, 0.03, 0.10].enumerated().filter { p.process(sample(Double($0.offset) * 0.05, gap: $0.element)) }
        XCTAssertEqual(fired.count, 1)
    }

    func testLowConfidenceIgnored() {
        XCTAssertFalse(PinchDetector().process(sample(0, gap: 0.0, confidence: 0.2)))
    }
}

final class PushDetectorTests: XCTestCase {
    func testPushNeedsForwardThenBrake() {
        let p = PushDetector()
        XCTAssertFalse(p.process(acceleration: 0.8, time: 0.0))
        XCTAssertTrue(p.process(acceleration: -0.5, time: 0.2))
    }

    func testSlowMovementIsNotAPush() {
        let p = PushDetector()
        XCTAssertFalse(p.process(acceleration: 0.3, time: 0.0))
        XCTAssertFalse(p.process(acceleration: -0.3, time: 0.2))
    }

    func testBrakeTooLateIsNotAPush() {
        let p = PushDetector()
        _ = p.process(acceleration: 0.8, time: 0.0)
        XCTAssertFalse(p.process(acceleration: -0.5, time: 0.6))
    }
}

final class FacingRankerTests: XCTestCase {
    // Room map: you stand at the origin; -z is "north" (heading 0).
    let lamp = RegisteredDevice(id: "lamp", name: "Lamp", position: Vector3(0, 0, -3))        // straight ahead
    let thermo = RegisteredDevice(id: "thermo", name: "Thermostat", position: Vector3(3, 0, 0)) // 90° right
    let tv = RegisteredDevice(id: "tv", name: "TV", position: Vector3(1, 0, -3))               // ~18° right
    let behind = RegisteredDevice(id: "spk", name: "Speaker", position: Vector3(0, 0, 3))      // behind

    func testDevicesInFrontRankFirstAndBehindIsExcluded() {
        let r = FacingRanker().rank(position: Vector3(0, 0, 0), headingDegrees: 0, devices: [behind, tv, lamp, thermo])
        XCTAssertEqual(r.map(\.device.id), ["lamp", "tv"])
    }

    func testTurningReordersTheList() {
        let r = FacingRanker().rank(position: Vector3(0, 0, 0), headingDegrees: 90, devices: [lamp, thermo, tv])
        XCTAssertEqual(r.first?.device.id, "thermo")
    }

    func testOffsetSignShowsLeftOrRight() {
        let r = FacingRanker().rank(position: Vector3(0, 0, 0), headingDegrees: 0, devices: [tv])
        XCTAssertGreaterThan(r[0].offsetDegrees, 0)   // TV is to the right
    }
}

final class CrownProfileTests: XCTestCase {
    func testThermostatSnapsToWholeDegreesWithinLimits() {
        XCTAssertEqual(CrownProfile.thermostatF.snap(71.6), 72)
        XCTAssertEqual(CrownProfile.thermostatF.snap(95), 80)
    }

    func testResistanceRisesToAHardStop() {
        let p = CrownProfile.light
        XCTAssertEqual(p.resistance(at: 50), 0)
        XCTAssertGreaterThan(p.resistance(at: 97), 0)
        XCTAssertEqual(p.resistance(at: 100), 1)
    }
}

final class HapticDirectionTests: XCTestCase {
    func testFourZones() {
        XCTAssertEqual(HapticDirection.zone(forOffsetDegrees: 10), .ahead)
        XCTAssertEqual(HapticDirection.zone(forOffsetDegrees: 80), .right)
        XCTAssertEqual(HapticDirection.zone(forOffsetDegrees: -80), .left)
        XCTAssertEqual(HapticDirection.zone(forOffsetDegrees: 170), .behind)
    }
}
