# Style Bible — one coherent animated universe

> Target: a premium animated children's fantasy film, translated into an interactive game.
> Reference: the key-art board supplied for the project (`docs/art/reference/`): painted, golden-hour, glossy, cozy.
> Whenever a design decision is unclear, ask: *would a 4-year-old understand it, would a 6-year-old think it's cool, does it feel magical, does the princess feel like she is helping someone?*

## What the reference tells us (and how we honour it)

| From the reference | Rule in this project |
|---|---|
| Warm golden-hour light, soft rim, hazy layered depth | Warm key + cool lilac fill, exposure kept a touch low, fog tinted lilac, light-shaft cards, 3–4 depth layers per scene |
| Saturated but harmonious: pink / lavender characters against teal water, sunlit gold, deep foliage green | Palette below; grass is *yellow-green → teal*, never neon; shadows are lilac, never grey |
| Big glossy eyes with two highlights, soft blush, expressive brows | The face shader (`shaders/face.gdshader`): iris gradient + limbal ring + 2 highlights + lashes, blush and tears; 14 emotion presets |
| Voluminous wavy hair, layered gowns with trim, tiara with a pink gem, flowing cape | 6 hair styles built from overlapping volumes, gowns with hem scallops/sash/bow, cape with wind sway |
| White unicorn with lavender/pink mane and a golden horn | Lumi: chubby proportions, rainbow-gradient mane and tail, glowing horn; her colours are in `data/characters/lumi.json` |
| Cream rounded UI panels with gold trim, wooden signposts, glossy candy buttons, gold script title | `ui/ui_kit.gd`, `ui/magic_button.gd`; Lilita One title, Fredoka body; cards `#fff4e0` with `#ffd9a0` trim |
| Storybook world map, castle on a hill with waterfalls, floating clouds | `world/world_map.gd` diorama; castle is always the hero silhouette |
| Hearts on the HUD and "3/5" star counters | **Not adopted** — hearts read as lives. Progress is shown as a crown with jewels and a filling ring. |

## Colour language

| Role | Colours |
|---|---|
| Princess / warmth / kindness | pink `#ff8fbf`, blush `#ffd6ec`, cream `#fff4e0` |
| Magic | gold `#ffc94d`, star `#ffe27a`, lilac `#b58cf2`, sky `#6ec6f5`, mint `#66d9b0` |
| Flower Magic | pink + yellow · Animal Friendship | warm orange + hearts · Star Light | gold · Rainbow | all seven |
| Enchanted Forest (day) | greens `#4fc25f → #238a6a`, pink blossom canopies `#e878b8`, teal shade |
| Moonlit | indigo `#2a1f5c`, violet `#7a58c8`, glow-cyan `#7ad8ff`, warm star-gold |
| Shadows | plum/lilac (`#5c2a6b` family), **never black** |
| Outlines | soft plum `#5c2a6b`-ish, thin — storybook, not comic |

## Proportions & silhouettes

- Princess: ~3 heads tall, head radius 0.30 on a 1.55 m body, small hands and boots, big readable crown. Facing 3/4 toward travel.
- Baby unicorn: head almost as large as the body, short thick legs, big rounded ears, horn ≈ 40 % head height.
- Companions are always *cuter and simpler* than the princess (rounder, fewer parts).
- Everything interactive has a soft glow; nothing decorative glows as strongly.

## Lighting

Key (warm) from front-upper-left, rim (pink/lilac) from behind, sky ambient. Toon banding is soft (`shade_softness 0.22`). Glow/bloom subtle (`threshold 1.15`).
Night scenes keep faces readable: higher ambient, blue-violet key, warm stars/fireflies as the accent.

## Materials & textures

Procedural: vertex-colour gradients + toon shader. No photo textures. Glitter uniform gives sparkle on gowns, hair, cape, horn.
When authored assets arrive they should be hand-painted, low-frequency, with painted highlights rather than baked realism.

## UI style

- Big (≥ 84 px) round candy buttons, icon-first, springy press with a star burst and a chime.
- Cream cards, gold border, pink accent; portraits are round with a coloured ring per character.
- Text is subtitles for grown-ups and early readers only; gameplay never depends on it.
- Transitions: clouds sweep in for travel; a golden page-turn for menus.

## Icon style

Chunky filled shapes, 1–2 highlight dots, a slightly darker rim, no thin lines. Drawn in code (`ui/icon_art.gd`) so they scale and tint.

## Particle style

Soft additive glows, 4-point sparkles, hearts and petals. Warm→cool colour ramps, gentle upward drift, fade in fast / out slow. Magic always plays:
sparkles → swirling particles → environmental reaction → musical flourish → character reaction.

## Animation personality

Squash and stretch on landing, slight overshoot on turns, everything breathes. Emotions read from silhouette first (arms up = joy, head tilt = curiosity, ears down = worry).
Characters are never still: idle bob, blink every 2–5 s, gaze drifts, tail/mane/hair sway.

## Audio personality

Music-box, celesta, harp, marimba, soft flute, warm pads; pentatonic melodies (can't clash). Reverb-wet and gentle. Voice is warm, unhurried, kind.
Emotional moments (rescue, star, bloom) get a full chord swell.

## The painted-layers plan (closing the gap to the reference)

Procedural 3D cannot fully match a hand-painted key art. The pipeline therefore reserves slots for painted parallax layers
(`game/assets/art/<level>/layer_*.png`) placed as textured planes at real depths, plus authored glTF characters. Prompts and rules are in `ASSET_PIPELINE.md`.
