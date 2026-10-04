# AuraLink program plan

Phases with exit criteria, per product. Durations are set once device prototypes exist.

## AuraLink for Apple Watch

| Phase | Scope | Exit criteria |
| --- | --- | --- |
| 1. Software prototype | iPhone setup, room-map sync, Watch facing list and Crown control | Works end to end in 3 rooms |
| 2. 5-person pilot | Watch vs Control Center vs Siri in a room with 6 similar lamps | At least 3 of 5 prefer the Watch |
| 3. Crown and band prototypes | Braked Crown and 4-motor band | Battery impact under 5%; 90% direction accuracy |
| 4. 20-person study | Real homes, 2 weeks each | Daily use and preference data |

## Room Sense

| Phase | Scope | Exit criteria |
| --- | --- | --- |
| 1. Algorithms on simulation | Fall, presence, breathing (done in this repo) | Tests pass on all scenarios |
| 2. Real data collection | 60 GHz radar kit; staged falls on mats; 500+ hours of normal daily life | Labelled dataset |
| 3. Model and tuning | On-device model trained on real data | 95% falls detected, under 1 false alert per home per month |
| 4. Home pilot | 20 homes of older adults, with family consent | Alert accuracy and family satisfaction |
| 5. Regulatory review | Confirm positioning as safety and wellness | Clear plan for any medical claims |

## Risks I'm managing

| Risk | Product | Mitigation |
| --- | --- | --- |
| Indoor compass error | Watch | Rank a list instead of aiming; ±60° field of view |
| Battery from Crown brake and band | Watch | Premium tier only; power budget target under 5% |
| False fall alarms | Room Sense | 10 s confirmation, cancel on getting up, real-world false-alarm study |
| Missed falls | Room Sense | Staged-fall study across fall types; escalation if no movement after an alert |
| Privacy perception | Room Sense | No camera, no images, on-device processing, clear onboarding |
| Medical claims | Room Sense | Position as safety and wellness; regulatory review before any health claim |
