# AuraLink

**Your home, aware of you.** Two products that give the Apple home spatial awareness, built on a shared foundation of iPhone room mapping, Apple Home, and on-device sensing.

| | AuraLink for Apple Watch | Room Sense |
| --- | --- | --- |
| **Job** | Control: raise your wrist, the devices in front of you rise up, turn the Crown to adjust | Care: camera-free fall, presence, and sleep-breathing alerts for family members |
| **Sensing** | Watch compass and motion, room map from iPhone, UWB anchors (first-party) | Short-range 60 GHz radar, no camera |
| **Feedback** | Haptic Crown ticks; real Crown stops and a directional haptic band on premium models | Alerts to family through Home and Health |
| **Status in this repo** | Swift core logic with unit tests, iPhone setup app, watchOS app | Python algorithms with simulator, tests, and evaluation |

> **Status: v0.3 concept prototype.** The Swift core has unit tests (`swift test`); the iOS and watchOS layers are written against current APIs but haven't yet been built and tuned on devices. Room Sense algorithms run on **simulated** radar data; real-world accuracy must be measured on recorded sensor data. All performance and business figures in `docs/` are targets and estimates.

## AuraLink for Apple Watch

1. **Raise your wrist.** The devices in the direction you're facing appear, closest first, with a haptic tap when the top device changes.
2. **Double-tap** (Series 9 and later) to open the top device, or tap any device in the list.
3. **Turn the Digital Crown** to adjust: brightness, temperature, blinds, or volume, with a haptic tick at every step. Double-tap again to switch it on or off.

**How it fits together:** the iPhone maps each room once (ARKit, aligned to the compass) and sends device positions and your usual "spots" to the Watch. The Watch combines that map with its compass heading. A first-party version would use HomePod and home-hub UWB signals to know your position automatically.

**Concept hardware for premium models (not in this prototype):** a Digital Crown with an electromagnetic brake for real resistance and hard stops, and a band with 4 haptic motors that tell you which direction a device is in.

## Room Sense

A small plug-in sensor for rooms where a camera would feel invasive: bedrooms, bathrooms, hallways.

- **Falls:** a fast drop to the floor, followed by staying down, sends an alert to family. Getting back up cancels it.
- **Presence:** knows if someone is in the room, even sitting still, because radar sees breathing micro-motion.
- **Sleep breathing:** breaths per minute while lying still, as a wellness trend.
- **Privacy:** radar measures distance and motion only. No images exist to store or leak, and processing runs on the device.

It complements Apple Watch fall detection by covering the times a watch isn't worn: the shower, overnight while charging, or for people who don't wear one.

## Repository layout

```
Package.swift                 Swift package for the platform-independent core
Sources/AuraLinkCore/         PointingSelector, FacingRanker, CrownProfile, HapticDirection, DetentDial, PinchDetector, PushDetector
Tests/AuralinkCoreTests/      Unit tests for the core
App/                          iPhone app: room setup, pointing control, sends the room map to the Watch
WatchApp/                     Apple Watch app: facing list, Crown control, double-tap
Shared/                       Room map sync between iPhone and Watch
RoomSense/                    Radar algorithms (fall, presence, breathing), simulator, tests, evaluation
docs/                         Concept, architecture, program plan, business case
```

## Build and run

- **Swift core (macOS):** `swift test`
- **iPhone and Watch apps:** create an iOS app with a watchOS companion in Xcode 16+, add this folder as a local package, add `App/` to the iOS target, `WatchApp/` to the watchOS target, and `Shared/` plus `App/Home/HomeController.swift` to both. Enable HomeKit on both targets. Info.plist keys: `NSCameraUsageDescription`, `NSHomeKitUsageDescription`, `NSMotionUsageDescription`, `NSLocationWhenInUseUsageDescription` (Watch compass), `NSNearbyInteractionUsageDescription`.
- **Room Sense:** `cd RoomSense && pip install -r requirements.txt && pytest && python evaluate.py`

## Demo

Concept animation: https://github.com/vivekselva91/Auralink/blob/main/AuraLink_Concept_Watch_RoomSense.mp4

## License

MIT. See `LICENSE`.
