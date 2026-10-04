# AuraLink architecture

## AuraLink for Apple Watch

```
 iPhone (one-time setup)                     Apple Watch (every day)                        Apple Home
 ARKit room map, compass-aligned  --map-->  FacingRanker: devices within ±60° of heading -->  HomeKit / Matter
 Device anchors + "spots"         (WatchConnectivity)   Compass heading (CLHeading)            lights, thermostat,
                                            Digital Crown + CrownProfile (ticks, stops)        blinds, speakers
                                            Double-tap (primary action)
                                            Haptics: Taptic Engine; band zones (concept)
```

**Key decisions**

1. **Rank, don't aim.** The Watch has no camera and its compass drifts indoors by 10-20°, so it lists devices within ±60° of your heading, closest to straight ahead first. Facing roughly the right way is enough.
2. **The map is compass-aligned.** The iPhone builds the room map with ARKit's gravity-and-heading alignment (-z is north), so the Watch's compass heading needs no conversion.
3. **Position comes from "spots" in the prototype.** You save places you often stand ("Sofa", "Bed") during iPhone setup. A first-party version would get position from HomePod and hub UWB anchors.
4. **One Crown profile per device type** (`CrownProfile`): lights in 5% steps, thermostat in 1°F steps from 60 to 80°F, blinds in 10% steps, volume in 5% steps. A braked Crown uses `resistance(at:)` to stiffen near the limits and stop hard at them.

## Room Sense

```
 60 GHz radar  ->  on-chip tracker  ->  RadarFrame features  ->  FallDetector       --> event --> Home + Health alert to family
 (no camera)       (per person)         height, velocity,        PresenceDetector    --> event --> Home automations
                                        motion, chest motion     Breathing estimate  --> trend --> Health (wellness)
```

**Key decisions**

1. **Features, not raw data, leave the radar chip.** The sensor only ever has positions and motion, never images.
2. **Confirm before alerting.** A fall alert waits 10 seconds of staying down, which removes false alarms from sitting or bending quickly.
3. **Breathing only when still.** Body movement swamps chest micro-motion, so breathing is estimated only during stillness, such as sleep.
4. **Plug-in power.** Continuous radar plus on-device processing is best powered from USB-C (target under 3 W), avoiding battery anxiety for a safety product.

## Targets (to be validated)

| Product | Target | Value |
| --- | --- | --- |
| Watch | Correct device on top when facing it within ±20° | 90% |
| Watch | List updates after turning | under 0.3 s |
| Watch | Battery impact with daily use | no more than 5% |
| Watch band | Users identify the right direction | 90%, 4 zones |
| Room Sense | Real falls detected (staged study) | 95% |
| Room Sense | False fall alerts | under 1 per home per month |
| Room Sense | Breathing rate during sleep vs a chest-strap reference | within 1 breath per minute |
| Room Sense | Images captured | 0 |
