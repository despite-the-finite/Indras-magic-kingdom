# Data models

All content is JSON under `game/data/`, loaded and cross-validated by `Content` (`src/core/content_db.gd`).

## Character — `data/characters/<id>.json`

```jsonc
{
  "id": "lumi", "name": "Lumi", "species": "unicorn", "age": "baby",
  "ui_color": "#c9a2ff", "voice_key": "lumi", "dialogue_file": "lumi",
  "visual": { "rig": "unicorn", "model": "res://assets/models/characters/lumi/lumi.glb",   // optional glb replaces the procedural rig
              "colors": { "body": "#fff4fb", "mane": ["#ff8fd2","#b58cf2","#6ec6f5"], "horn": "#ffe27a", "eye": "#7a4dd8" }, "scale": 1.0 },
  "home":   { "location": "unicorn_stable", "castle_feature": "unicorn_stable" },
  "rescue": { "quest": "lost_unicorn", "region": "enchanted_forest", "stars": 3 },
  "care":   { "location": "unicorn_stable",
              "needs": [ { "id": "brush", "tool": "brush", "count": 4, "reaction": "shimmy" }, ... ],
              "need_dialogue": { "brush": "lumi_care_brush", ... }, "all_done_dialogue": "lumi_care_done" },
  "friendship_quest": { "quest": "moonflower_for_mama", "ask_dialogue": "lumi_asks_help", "stars": 3, "reward_power": "rainbow" },
  "companion": { "ability": "rainbow_bridge", "ability_icon": "rainbow", "follow_distance": 2.2, "speed": 4.4 },
  "mini_adventures": ["rainbow_ride"], "mini_adventure_unlock_stage": 6,
  "animations": { "idle": "idle", "happy": "happy_jump", "sad": "cry", "hopeful": "hopeful", "look_up": "look_up" },
  "rewards": { "rescue_stars": 3, "quest_stars": 3, "castle_unlock": "unicorn_stable", "power": "rainbow" }
}
```

Mapping to the brief's `NAME / SPECIES / HOME / RESCUE ADVENTURE / CARE NEEDS / FRIENDSHIP QUEST / COMPANION ABILITY / MINI ADVENTURES / DIALOGUE / ANIMATIONS / REWARDS` is one-to-one.
NPCs (`"kind": "npc"`, e.g. Clover, Luna) only need `id`, `name`, `species`, `visual`.

## Quest — `data/quests/<id>.json`

```jsonc
{ "id": "lost_unicorn", "kind": "rescue|friendship", "character": "lumi", "region": "enchanted_forest", "level": "forest_rescue",
  "music": "forest_explore", "ambience": ["forest_birds"], "intro_dialogue": "forest_arrive", "reward": { "stars": 3, "character_stage": "rescued" },
  "steps": [
    { "id": "grow_bridge", "target": "river_gap",
      "complete_on": ["power:flower:river_gap"],             // interact:<id> | power:<power>:<id> | zone:<id> | custom:<name>
      "hint": { "voice": "hint_bridge", "voice_alt": "hint_bridge_2", "target": "river_gap" },
      "dialogue_on_start": "river_broken_bridge", "dialogue_on_complete": "bridge_grown",
      "star": { "amount": 1, "reason": "helped_rabbit" } } ] }
```
A step also completes if its key was already seen (no soft-locks). `level` is a scene id from `Router.SCENES`.

## Dialogue — `data/dialogue/*.json`

```jsonc
{ "defaults": { "character": "lumi", "emotion": "happy", "once": false },
  "sequences": { "lumi_asks_help": [
     { "id": "lumi_asks_help_01", "emotion": "excited", "animation": "happy_jump",
       "text": "Princess! Princess! I remembered why I went into the forest!", "trigger": "friendship:ready", "camera": "optional_cue" } ] } }
```

| Field | Meaning |
|---|---|
| `id` | globally unique; also the audio filename (`vo/<id>.mp3`) |
| `character` | narrator, princess, lumi, clover, luna … (voice + portrait + animated rig) |
| `emotion` | face preset (`neutral happy joyful excited surprised wonder curious worried sad determined hopeful sleepy proud giggle whisper`) |
| `animation` | body animation played by the speaker's rig |
| `text` | subtitle (for grown-ups/early readers) *and* the ElevenLabs script |
| `once` | skip if already seen (completion state is saved in `dialogue_seen`) |
| `trigger` | documentation of what plays it (code plays sequences by id) |
| `camera` | optional cue name a level can react to (`castle_reveal`, `rescue_orbit`, `star_rise` …) |
| `kind: "hint"` | non-blocking line (hints/barks) |

## Customization — `data/customization.json`
Categories → options (`skin`, `face` (eye colour/size/freckles), `hair_style`, `hair_color`, `dress` (`gown|tutu|pants`, two colours), `boots`, `crown`, `cape`, `accessory`).
The creator screen is generated from this file; adding an option = adding an entry (and, for a new hair/crown style, a builder case in `princess_rig.gd`).

## World — `data/world/world.json`
`regions` (map position, palette, availability) and `castle_features` (what each rescued friend unlocks).

## Progression — `data/progression.json`
Crown thresholds (stars → jewel level) and star values. No XP anywhere.

## Mini adventure — `data/minigames/<id>.json`
`scene` script, `duration_seconds`, `requires_characters`, `music`, `intro_dialogue`, `outro_dialogue`, `reward { stars_per, max_magic_stars }`.

## Save file (`user://save.json`, versioned)
`version, created, appearance, stars, powers[], characters{id:{stage, care{need:count}}}, quests{id:{status}}, castle{features[]}, dialogue_seen{}, minigames{id:{plays,best,awarded}}, flags{}, secrets[]`.
Unknown/missing keys are filled from defaults on load (`_migrate`).
