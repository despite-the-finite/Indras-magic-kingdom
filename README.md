# Indra's Magic Kingdom

A magical princess adventure for ages 4–6. Create a princess, explore enchanted kingdoms, rescue friends, care for them at your castle,
go on friendship quests together, and play mini adventures with them. Voice-first, no reading needed, no lives, no failure, no ads.

**Engine:** Godot 4.7 (GDScript, Compatibility renderer, web-exportable) — see [docs/ENGINE_DECISION.md](docs/ENGINE_DECISION.md).

## The vertical slice (playable now)

Menu → princess creator → castle → magic map → **Enchanted Forest: The Lost Unicorn** → rescue Lumi → **castle stable + care** (brush, feed, hug) →
Lumi asks for help → **Friendship Quest: Moonflower for Mama** (cooperative puzzles) → **Rainbow Ride with Lumi** mini adventure.
All four modes, the whole character lifecycle. Status: [docs/VERTICAL_SLICE_PLAN.md](docs/VERTICAL_SLICE_PLAN.md).

## Run it

1. Install **Godot 4.7.2** (standard, not .NET): <https://godotengine.org/download>
2. Open `game/project.godot` in the editor and press ▶ — or from a terminal: `godot --path game`

Controls — **keyboard:** ←/→ or A/D walk, Space jump, E/Enter magic (uses whatever the glowing object needs), Q cycle power · **mouse/touch:** tap the ground to walk,
tap a glowing object to walk there and use it, big on-screen buttons · **gamepad:** stick, A jump, X magic, Y cycle power.

Every normal launch opens on the Entropic Labs logo (`game/assets/video/entropic_ident.ogv`, played by
`game/src/boot/ident.gd`), then fades into the menu. Any tap, click, key or pad button skips it. Dev launches
(`--scene`, `--shot`, `--skipintro`, `--noident`) and headless runs skip it automatically.

## For developers

| Task | Command |
|---|---|
| Validate all content | `godot --headless --path game -- --check` |
| Whole-slice automated playthrough (41 checks) | `godot --headless --path game -- --playthrough` |
| Render any scene/state to a PNG | `bash tools/dev/shot.sh castle --scene=castle --preset=at_castle` |
| Jump to a story state | `godot --path game -- --scene=stable --preset=at_castle` (presets: `fresh rescued at_castle cared quest_ready quest_done crown5`) |
| Regenerate placeholder audio | `node tools/audio/synth.mjs` |
| Generate ElevenLabs voice-over | `node tools/voice/generate.mjs --dry-run` then without `--dry-run` ([docs](docs/VOICE_PIPELINE.md)) |
| Export for the web | see [tools/dev/README.md](tools/dev/README.md) |

Dev flags after `--`: `--scene=<menu|customize|castle|map|forest_rescue|moonlit_forest|stable|rainbow_ride|dev_rigs>`, `--preset=<state>`, `--skipintro`, `--shot=<png> --shot-delay=<s>`.

## Documentation

| Doc | What |
|---|---|
| [ENGINE_DECISION](docs/ENGINE_DECISION.md) | why Godot 4 and what it costs us |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | systems, lifecycle, guidance, how to add a character |
| [STYLE_BIBLE](docs/STYLE_BIBLE.md) | one coherent animated universe (incl. how the reference art is honoured) |
| [DATA_MODELS](docs/DATA_MODELS.md) | JSON formats for characters, quests, dialogue, world, saves |
| [ASSET_PIPELINE](docs/ASSET_PIPELINE.md) | replacing procedural stand-ins with authored / AI-assisted art and audio |
| [VOICE_PIPELINE](docs/VOICE_PIPELINE.md) | ElevenLabs generation without exposing credentials |
| [VERTICAL_SLICE_PLAN](docs/VERTICAL_SLICE_PLAN.md) | the 25 steps and their status |
| [CHILD_TESTING](docs/CHILD_TESTING.md) | how to test like a 4-year-old |

## Repository layout

```
game/                Godot project (project.godot)
  data/              characters, quests, dialogue, world, customization (JSON) — the content
  src/core/          autoloads: events, content, state, audio, dialogue, quests, hints, router...
  src/gameplay/      player, companion, interactables, magic, camera
  src/characters/    rigs (princess, unicorn, rabbit, Flutter) + mesh helpers
  src/world/         terrain, props, castle kit, levels, map, stable
  src/minigames/     mini adventure framework + Rainbow Ride
  src/ui/            HUD, menu, creator, parent area, icons
  src/dev/           screenshot/playthrough/dev tools
  shaders/           toon, face, sky, water, rainbow, transitions
  assets/            fonts, generated audio (music/sfx/ambient), future models & painted art
tools/               audio synthesizer, ElevenLabs pipeline, dev scripts
docs/                design documents
```

## Design principles

Voice first, visual second, text third · no lives, timers, XP, currencies, ads, or manipulative loops · the princess's real power is helping others ·
progress is something a child can *see* (the crown grows jewels, the castle fills with friends).

## Credits & licences

Fonts: Fredoka and Lilita One (SIL OFL 1.1, see `game/assets/fonts/`). Engine: Godot (MIT). All other art and audio in this repository is original/procedural placeholder work.
