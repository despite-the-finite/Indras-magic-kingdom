# Asset pipeline & replacement plan

The vertical slice ships with **procedural stand-ins** for all art and audio (generated in code/scripts). Nothing is a dead-end: every stand-in has a named slot,
and gameplay code only knows ids, so authored assets drop in without touching game logic.

> Honest status: the procedural art is a *consistent, playable look-dev baseline* — not final art. The reference key art in `docs/art/reference/`
> is the quality bar. Reaching it needs painted layers and authored characters; this document is how to get there.

## Slots

| Asset | Today (temporary) | Slot (drop-in) | Spec |
|---|---|---|---|
| Characters (princess, Lumi, Luna, Clover) | code-built rigs + procedural face shader | `res://assets/models/characters/<id>/<id>.glb` referenced by `data/characters/<id>.json` → `visual.model` (`Assets.model()`) | glTF 2.0, ≤ 25k tris, single skeleton, ≤ 2 materials, 1–2k textures; animation clip names below |
| Environment props (trees, flowers, mushrooms, rocks) | `world/forest_props.gd` | `res://assets/models/props/<name>.glb` | ≤ 3k tris each, pivot at ground centre, vertex-colour or 1 atlas |
| Castle, stable, bridge | `world/castle_kit.gd` | `res://assets/models/castle/*.glb` | modular pieces on a 1 m grid |
| **Painted parallax layers** (the biggest visual win) | procedural hills/backdrops | `res://assets/art/<level>/layer_<n>_<name>.png` (+ optional `.webp`) | 4096×1024 PNG with alpha, tileable horizontally; placed as planes at real depths (−90, −60, −35, −12, +4) |
| Sky | `shaders/sky.gdshader` | keep (shader) or a painted 2048×1024 equirect | |
| UI icons/frames | code-drawn (`ui/icon_art.gd`) | keep or `res://assets/ui/*.svg` | icons stay tint-able |
| Music | synthesized loops (`tools/audio/synth.mjs`) | `res://assets/audio/music/<cue>.ogg` (same name wins over `.wav`) | 44.1 kHz stereo OGG, seamless loop, −14 LUFS |
| SFX | synthesized (`tools/audio/synth.mjs`) | `res://assets/audio/sfx/<id>.ogg` | mono/stereo, ≤ 3 s, peak −3 dBFS |
| Ambience | synthesized | `res://assets/audio/ambient/<id>.ogg` | 10–30 s seamless loops |
| Voice | text-only (subtitles + timed) or placeholder babble | `res://assets/audio/vo/<line_id>.mp3` from ElevenLabs | see `VOICE_PIPELINE.md` |
| Fonts | Fredoka + Lilita One (OFL, included) | | |

## Animation clip names (authored characters)

Princess: `idle walk run jump fall land wave celebrate dance hug cast curious surprised giggle point pet brush feed push nod bow spin wonder ride`
Unicorn: `idle walk gallop happy_jump look_up hopeful cry hug eat shimmy nod sleep trapped horn_glow`
Rabbit: `idle hop happy_hop worried wave point sniff`
Facial expressions map to blend shapes named after the emotion presets in `characters/rig_base.gd` (`happy joyful excited surprised wonder curious worried sad determined hopeful sleepy proud giggle whisper`).
Until then the faces are shader-driven; an authored face can reuse the same parameter names.

## Keeping AI-generated art coherent (one universe)

1. **Lock a style reference set** (the key art board + 6 approved character turnarounds). Every prompt starts with the same style block.
2. **Style block** (paste first, always):
   > *Premium 3D-animated children's fantasy film look, soft painterly lighting, warm golden-hour key with lilac shadows, big glossy expressive eyes with two highlights, rounded friendly shapes, saturated but harmonious pastels (pink #ff8fbf, lilac #b58cf2, teal, sunlit gold), gentle rim light, storybook depth with layered foreground/midground/background, no text, no logos, no scary or dark elements.*
3. **Characters:** generate front / 3-4 / side / back turnarounds on a neutral background first, then image-to-3D (Meshy/Tripo/Rodin/Luma) → retopo in Blender → rig/animate (Mixamo or Blender) → export glTF. Reject anything with realistic proportions.
4. **Backdrops:** prompt one *level-length* concept, then split into 4–5 depth layers with alpha (inpaint background layers to remove overlaps). Keep the horizon at 38 % from the bottom to match the camera.
5. **Palette gate:** run `tools/dev/shot.sh` on the integrated scene; compare with `docs/art/reference/`. If hues drift, grade the asset (don't regenerate) — it is cheaper and keeps the universe consistent.
6. **Record provenance** in `game/assets/CREDITS.md` (tool, prompt id, date, licence) for every generated asset.

### Ready-to-use prompts

- *Princess (customizable base):* "3/4 view full-body 3D-animated kids' film princess, ~3 heads tall, chestnut wavy hair, pink ballgown with cream trim and bow, small gold tiara with pink gem, lilac cape, adventure boots, holding a star wand, warm smile, big glossy brown eyes …" + style block.
- *Lumi:* "baby unicorn, chubby proportions, white coat with lavender shading, rainbow-gradient mane and tail (pink, lilac, sky), short golden spiral horn with a soft glow, huge violet sparkly eyes, tiny pink hooves, curious hopeful expression …" + style block.
- *Enchanted Forest backdrop:* "wide side-view fairytale forest at golden hour, giant pink and lilac flowers, glowing mushrooms, blossom-canopy trees, mist and light shafts, a winding stream and a small broken wooden bridge, layered depth …" + style block.
- *Castle:* "pastel fairytale castle on a hill, lilac cone roofs, waving pennants, waterfalls beside it, meadow with rose hedges …" + style block.

## Placeholder policy

Every procedural stand-in is **explicitly temporary**. `docs/VERTICAL_SLICE_PLAN.md` lists them and the replacement status. Do not add new one-off procedural assets without adding a slot row above.

## Build steps

```
node tools/audio/synth.mjs                 # regenerate placeholder music/SFX/ambience (idempotent)
node tools/voice/generate.mjs --dry-run    # preview VO generation (no key needed)
godot --headless --path game --import      # import any new assets (run after adding audio/models)
```
