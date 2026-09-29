# Testing from a 4-year-old's perspective

Adults are bad at this. Use this protocol with a real child (with a parent present), and the design questions below with your team.

## Design questions (ask of every screen and puzzle)

1. Would a 4-year-old understand what to do **without reading or being told**? (voice + icon + glow + Flutter)
2. Would a 6-year-old still think this is cool? (spectacle, secrets, dress-up, riding)
3. Does it feel magical? (sparkle → swirl → reaction → flourish → character reaction)
4. Does it make the princess feel like she is *helping someone*?
5. Does the rescued character feel like a real friend afterwards? (they greet her, wander, ask for help, appear in Rainbow Ride)

## Observation protocol (10 minutes per section, don't help unless she asks)

| Watch for | Signal it's a problem | Fix knob |
|---|---|---|
| Stops and looks around for > 15 s | hint too slow | `HintSystem.THRESHOLDS` |
| Taps the wrong thing repeatedly | icon/affordance unclear | interactable `halo_height`, prompt icon |
| Mashes the magic button with nothing targeted | fine (ambient magic is delightful) — but note if she expects something | ambient cast content |
| Falls and looks upset | rescue too slow/scary | `Player._rescue_fall` timings |
| Misses spoken hints due to noise | voice too quiet or too long | line length, `Voice` bus gain |
| Doesn't notice the crown growing | reward feedback too subtle | `StarFly`, crown FX |
| Asks "where's Lumi?" at the castle | resident presence unclear | Wanderer greet distance |
| Touch: thumbs cover the action | HUD placement | `Hud._ready` anchors |

## Comfort & safety checklist

- No timers, lives, failure, or scary sounds. Loudest sfx ≤ −3 dBFS; music ducks under voice.
- Reduce-motion setting removes shake/FOV punch and sway.
- Parent gate cannot be passed by tapping randomly (2-digit answer, reading required).
- No network, ads, analytics, or purchases (`Settings` + Parent Area privacy note).
- Session length: natural stopping points at castle, at the map, after every rescue/quest (celebration then castle).
- Test on: Chrome desktop (mouse), Chrome/Safari tablet (touch), gamepad.

## Playtest log template

`date · child age · device · section · minutes · stuck moments (where/how long) · delights (what she said/did) · changes made`
