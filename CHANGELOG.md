# Changelog

## v0.3: Two products, one foundation

- **AuraLink for Apple Watch:** new watchOS app. Devices in the direction you're facing appear closest first (`FacingRanker`); double-tap opens the top one; the Crown adjusts with per-device profiles (`CrownProfile`), including resistance curves for a braked Crown concept; 4-zone directional haptics for the band concept (`HapticDirection`).
- **iPhone app:** room map is now compass-aligned and syncs to the Watch with saved standing "spots". HomeKit control added for thermostats, blinds, and speaker volume.
- **Room Sense:** new Python package with fall, presence, and breathing algorithms, a scenario simulator, unit tests, and an evaluation script. Simulated results only.
- **Docs:** rewritten concept, architecture, and program plan for both products; new business case.

## v0.2: Pointing first, touch for control

- iPhone pointing selects a device; an on-screen haptic dial controls it; one optional no-look pinch.

## v0.1: First prototype

- Pointing selection with ARKit anchors, five air gestures, HomeKit control, haptics, and push-to-cast.
