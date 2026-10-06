# Architecture

Godot 4.7 · GDScript · Compatibility renderer · 2.5D lane gameplay · everything story-shaped is **data**.

## The one idea: the character lifecycle

Every friend the princess makes moves through the same seven stages. It is the spine of the game, and it is *data*, not code.

```
UNKNOWN → DISCOVERED → RESCUED → AT_CASTLE → FRIENDS → QUEST_READY → QUEST_DONE
 (heard)   (adventure)  (freed)   (home)     (cared)   (asks help)    (resident → mini adventures)
```

| Stage change | Triggered by | Where it lives |
|---|---|---|
| DISCOVERED | Flutter tells the princess (castle intro) | `castle_hub.gd` `_first_visit` |
| RESCUED | rescue quest's last step + cinematic | `forest_level.gd` `_rescue_cinematic` |
| AT_CASTLE | arrival story, unlocks the castle feature (stable opens) | `castle_hub.gd` `_after_rescue` |
| FRIENDS | every `care.needs` entry satisfied | `stable_scene.gd` `_friends_forever` |
| QUEST_READY | the character asks "Will you help me?" | `castle_hub.gd` `_lumi_asks_help` |
| QUEST_DONE | friendship quest complete, power + mini adventure unlocked | `moonlit_level.gd` `_finale` |

`GameState` (`src/core/game_state.gd`) owns the stage, care counts, stars, powers, unlocked castle features, secrets, mini-adventure records,
and persists all of it (versioned JSON, atomic write). `Events` announces every change so any system can react.

## Adding a new character (no core rewrite)

1. `game/data/characters/<id>.json` — name, species, home, rescue quest, care needs, friendship quest, companion ability, mini adventures, animations, rewards ([DATA_MODELS.md](DATA_MODELS.md)).
2. `game/data/quests/<rescue>.json` and `<friendship>.json` — ordered steps with `complete_on` event keys, hint config, dialogue hooks.
3. `game/data/dialogue/<id>.json` — lines with character, emotion, animation, text. Audio is generated from these ([VOICE_PIPELINE.md](VOICE_PIPELINE.md)).
4. A rig (`src/characters/…_rig.gd`, or a `.glb` via `Assets`) and a level script that builds the place and reacts visually to quest events.
5. Optional: `data/minigames/<id>.json`.

`Content.validate()` cross-checks every reference (quest→character, dialogue ids, mini adventure ids…) — run `godot --headless --path game -- --check`.

## Systems (all under `game/src`)

| System | File(s) | Notes |
|---|---|---|
| Global bus | `core/events.gd` | signals only |
| Data loading + validation | `core/content_db.gd` | JSON → dictionaries |
| Save / progress / lifecycle | `core/game_state.gd` | one source of truth |
| Settings (parent-owned) | `core/settings.gd` | separate file so reset never wipes them |
| Audio | `core/audio_manager.gd` | buses, adaptive music crossfade, SFX pool, ambience layers, voice with ducking; lines without a recording are read by the device's text-to-speech |
| Dialogue | `core/dialogue_system.gd` | plays sequences by id; drives voice, subtitle UI, and character animation cues |
| Quests | `core/quest_system.gd` | step machine driven by event keys (`interact:`, `power:`, `zone:`, `custom:`); completes steps already satisfied (no soft-locks) |
| Adaptive hints | `core/hint_system.gd` + `world/level_base.gd` | 4 layers, see below |
| Scene routing + transitions | `core/scene_router.gd`, `shaders/transition.gdshader` | cloud wipe (travel) and page-turn (menus) |
| Actor registry | `core/actor_registry.gd` | dialogue → `character_cue` → the right rig animates |
| Input | `core/input_router.gd` | keyboard, gamepad, mouse and touch share actions; tracks idle time |
| Player | `gameplay/player.gd` | coyote/jump-buffer, click-to-walk, tap-an-object-to-use, gentle Flutter fall rescue, `glide_to` for anything that must move her safely (rainbow lift, throne, bed) |
| Companion | `gameplay/companion.gd` | follows, hops, warps if lost; performs data-defined ability |
| Interaction | `gameplay/interactable.gd` | `touch` / `press` / `magic` / `coop`; quests listen by id |
| Magic | `gameplay/magic_system.gd`, `magic_swirl.gd` | sparkles → swirl → reaction → flourish → character reaction |
| Camera | `gameplay/follow_cam.gd` | automatic follow, look-ahead, dialogue framing, authored cinematic moves |
| World kit | `world/terrain.gd`, `forest_props.gd`, `castle_kit.gd`, `env_kit.gd` | procedural stand-ins (see ASSET_PIPELINE); terrain adds solid cliff faces at every segment edge |
| Levels | `world/level_base.gd` → `forest_level`, `moonlit_level`, `castle_hub`, `castle_inside` | shared plumbing, story-specific reactions; `castle_inside` is the explorable home (great hall, throne room, bedroom, kitchen) |
| Care | `world/stable_scene.gd` | Mode 2 |
| Mini adventures | `minigames/mini_adventure.gd` → `rainbow_ride.gd` | declared in `data/minigames/*.json` |
| Characters | `characters/rig_base.gd` → `princess_rig`, `unicorn_rig`, `rabbit_rig`, `flutter` | procedural animation + shader-driven faces |
| UI | `ui/*` | icon set drawn in code, `MagicButton`, HUD, portraits, parent area |
| Dev tools | `dev/*` | screenshots, presets, smoke check, automated playthrough |

## Guidance for non-readers (layered, curiosity-first)

`HintSystem` watches the current quest step. A timer runs while nothing meaningful happens — slower while the child is moving/exploring, faster when idle,
paused during dialogue, reset by any progress. Levels respond to `Events.hint_level_changed`:

1. **Spoken hint** (narrator voice; `hint.voice`)
2. **Visual hint** — target glows brighter/pulses, the princess looks toward it and does her curious animation
3. **Environmental** — Flutter the butterfly flies to the target and waits; second spoken variant (`hint.voice_alt`)
4. **Direct** — a sparkling trail briefly shows the way (repeats every ~22 s until progress)

Every level also has the safety net: *no fail state.* Falling → Flutter carries the princess back to the last safe spot with a giggle.
Ledges and river edges are solid (terrain end walls, the forest's river guard until the bridge grows), so falling is rare rather than routine.

## The 2.5D approach

Real 3D world (parallax layers, foreground foliage, fog, light shafts) with gameplay locked to a single lane (z = 0). Characters turn ~34° toward their
travel direction so faces stay expressive. The camera is never controlled by the child; cinematics are authored (`FollowCam.cine_to / cine_orbit`).
Camera framing rules: eye-level horizon low in frame, the princess in the lower third, characters shift up automatically when the dialogue bar is on screen.

## Rendering & performance

Compatibility (OpenGL) renderer so the identical project runs in browsers. Custom shaders: toon (banded diffuse, tinted shadows, rim, wind sway, glitter),
inverted-hull outline, procedural face (eyes, brows, mouth, blush, tears, freckles from ~20 uniforms), painterly sky, stylised water, rainbow ribbon, storybook transitions.
Instancing (MultiMesh) for grass and flowers; particle counts scale with the Parent Area graphics setting.

## Determinism & tests

- `godot --headless --path game -- --check` — data validation.
- `godot --headless --path game -- --playthrough [--from=rescue|care|friendship|ride]` — drives the real systems through the whole slice and asserts every
  lifecycle transition (68 checks).
- `tools/dev/shot.sh <name> --scene=<id> --preset=<state>` — renders any scene/state to `shots/<name>.png` for look-dev review.
