# Vertical slice — plan & status

**Goal:** one polished 20–30 minute experience with Lumi in the Enchanted Forest that demonstrates all four game modes.
Status legend: ✅ working & covered by the automated playthrough · 🟡 working, needs art/polish · ⬜ not yet.

## The 25 flow steps

| # | Step | Status | Where |
|---|---|---|---|
| 1 | Main menu | ✅🟡 | `ui/main_menu.gd` |
| 2 | Simple princess customization | ✅🟡 | `ui/customize_screen.gd` (9 categories, big cards, live preview) |
| 3 | Castle introduction | ✅🟡 | `world/castle_hub.gd` `_first_visit` |
| 3b | Explore inside the castle (great hall, throne, mirror → dress-up, bedroom nap, toy box, kitchen cake, secret star) | ✅🟡 | `world/castle_inside.gd` via the garden gate |
| 4 | World map | ✅🟡 | `world/world_map.gd` |
| 5 | Select Enchanted Forest | ✅ | map → `forest_rescue` |
| 6 | Enter Lost Unicorn adventure | ✅ | `world/forest_level.gd` |
| 7 | Explore forest | ✅🟡 | platforming, bouncy mushrooms, secret hollow, wishing orbs |
| 8 | Follow clues | ✅ | 3 sparkling hoofprint clusters |
| 9 | Solve simple environmental puzzles | ✅ | rabbit + branch, Flower Magic vine bridge |
| 10 | Discover Lumi | ✅ | crying-off-screen camera pan, thorn cage |
| 11 | Rescue Lumi | ✅ | Flower Magic → thorns bloom |
| 12 | Cinematic celebration | ✅🟡 | orbit cam, hug, Magic Star rises into the crown |
| 13 | Return to castle | ✅ | cloud transition |
| 14 | Lumi's stable becomes available | ✅ | doors swing open, lock vanishes, feature saved |
| 15 | Care for Lumi | ✅ | `world/stable_scene.gd` |
| 16 | Brush | ✅ | |
| 17 | Feed | ✅ | rainbow apples |
| 18 | Hug / pet | ✅ | also petting in the garden |
| 19 | Lumi asks for help | ✅ | after all care needs are satisfied |
| 20 | Unlock Friendship Quest | ✅ | map shows the moon marker |
| 21 | Princess + Lumi search for the Moonflower | ✅ | `world/moonlit_level.gd` |
| 22 | Cooperative challenges | ✅ | rainbow bridge (Lumi), lifting log (princess), Star Light cave, wake the Moonflower (both) |
| 23 | Find the Moonflower | ✅ | |
| 24 | Return home | ✅ | Luna the mama arrives, Rainbow Magic given |
| 25 | Unlock Lumi-themed mini adventure | ✅ | rainbow signpost → **Rainbow Ride** (`minigames/rainbow_ride.gd`) |

Cross-cutting: adaptive 4-level hints ✅ · Flutter fall rescue ✅ · spoken voice for every line (device text-to-speech until recordings exist) ✅ · solid ledges + a rainbow that can never trap her ✅ · save/load ✅ · parent area with gate ✅ · settings (volumes, narration, subtitles, quality, reduce motion, touch) ✅ ·
data-driven characters/quests/dialogue ✅ · ElevenLabs pipeline ✅ (needs your key + voice ids) · placeholder audio ✅ · web export config ✅ (see below).

## Verification

`godot --headless --path game -- --playthrough` → **68 checks, 0 failures**: steps 1–25 (plus the castle interior, the ledge/river edge tests and the voice/controls checks) with every lifecycle transition (`DISCOVERED → RESCUED → AT_CASTLE → FRIENDS → QUEST_READY → QUEST_DONE`).

## Temporary stand-ins (each has a slot in `ASSET_PIPELINE.md`)

| Stand-in | Replace with |
|---|---|
| Procedural characters/faces, props, castle, terrain | authored glTF + painted parallax layers (highest visual impact first: backdrops, then princess/Lumi) |
| Synthesized music / SFX / ambience | composed music and recorded SFX |
| Text-only or placeholder dialogue audio | ElevenLabs-generated VO |
| Procedural icons | fine to keep; may be re-skinned |

## Polish backlog (ordered by child-facing value)

1. Painted backdrops + authored princess/Lumi (closes the gap to the reference art).
2. Real music and voice.
3. Camera/animation timing pass with a child playtest (`CHILD_TESTING.md`).
4. Accessibility: colour-blind checks on power icons, larger hit targets option, left-handed layout.
5. Content: Baby Dragon (Dragon Mountain) as the second character to prove the pipeline (`ARCHITECTURE.md` → "Adding a new character").
