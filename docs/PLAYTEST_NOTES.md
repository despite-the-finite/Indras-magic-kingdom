# Full-game test pass — findings, fixes and what to do next

A whole-slice pass with one question in mind: *can a 4-year-old who cannot read, but understands spoken English, play this from
the title screen to the Rainbow Ride without a grown-up and without ever getting stuck?* Everything below was verified with the
automated playthrough (`godot --headless --path game -- --playthrough`), which now also reproduces the reported ledge bug.

## What was broken, and what changed

### 1. There was no voice at all
The voice folder (`game/assets/audio/vo/`) was empty, so every "spoken" line was a subtitle timed by a reading estimate. For a
non-reader that is silence. **Fix:** every line is now read aloud by the device's own text-to-speech whenever no recording exists
(Windows, macOS, tablets and browsers all have one). Each character gets a distinct pitch and pace, the dialogue bar waits for the
engine to finish talking, and a tap cannot skip a line for its first second. The ElevenLabs pipeline is untouched: drop real
recordings into `vo/` and they take over line by line. New lines were added where the game used to be silent at a decision point:
the title screen ("tap the big pink button"), how to walk and jump on first entering the forest, how to jump in the Rainbow Ride,
the ride's results screen, and every room inside the castle.

### 2. Rainbow ledge: stuck behind the rainbow, then falling through the ledge
Two separate bugs. (a) Terrain cliffs had no collision at all: the lower meadow simply ended at the ledge, so walking into the
rock face dropped the princess through the world (then Flutter rescued her, far back). (b) The rainbow always grew from a fixed
spot. If she asked for it while standing near the ledge, 24 thin collision boxes appeared on top of and around her, boxing her in,
and the box seams made walking up it stutter. **Fix:** every terrain segment now has solid invisible cliff faces (she bumps, she
does not fall). The rainbow starts *behind* wherever she stands, is one smooth collision surface, climbs to the ledge and runs
flat onto it, and if she or Lumi is inside its span when it appears it lifts them gently onto it. The playthrough now walks up to
the ledge, casts from right there, and walks up and over without falling.

### 3. Falling into the river over and over
In the forest, the only thing stopping her at the broken bridge was the river; a small child leaning on the arrow key would fall
in repeatedly (rescue, walk back, fall in...). **Fix:** an invisible guard at the river's edge until the vine bridge grows. Falls
and the Flutter rescue still exist as the safety net, they are just no longer the normal way to learn "I need magic here".

### 4. Up arrow did not jump
Jump was Space / pad A. **Fix:** Up arrow (and W, d-pad up) jump everywhere; Space still works; the on-screen button was already
an up arrow so the voice line "press up to jump" is true on every device.

### 5. The castle was scenery
**Fix:** a garden gate on the lane opens a four-room interior: great hall (music box that makes Flutter dance, portraits with a
hidden Magic Star), throne room (sit on the throne; the magic mirror re-opens dress-up and brings her straight back), bedroom
(a cozy nap with the lights dimming, a toy box that bounces balls around), kitchen (bake a rainbow cake that Lumi comes to eat,
a cookie jar). Lumi wanders the halls once she lives at the castle. Nothing inside is required by the story; Flutter and the glow
point to whatever she has not tried yet, and the front door always leads back to the garden.

## Other things checked and found fine
- Quest steps that were satisfied early still complete (no soft-locks), confirmed for every step of both quests.
- The hint ladder (voice → glow → Flutter → sparkle trail) fires on every quest step, the care screen, the map and the castle.
- Every scene can be left with the home button; the parent gate still needs reading and a two-digit answer.
- Falling anywhere still ends with Flutter carrying her back; nothing is lost.

## Suggestions to make the game stronger (ordered by value for a 4-year-old)

1. **Record the real voices.** TTS is clear but flat. The ElevenLabs cast is already set up (`tools/voice/voices.json`): add five
   voice ids and your key, run `node tools/voice/generate.mjs`, commit the mp3s. About 6,000 characters for the whole slice.
2. **Hear a hint sooner when she is idle.** The first spoken hint comes after about 14 "effective" seconds; a 4-year-old who stops
   moving is usually already lost. Try 9 s for the first level and keep the later ones (`HintSystem.THRESHOLDS`).
3. **One obvious "Flutter, help me" button.** The hint system has a `nudge()` entry point but nothing on screen calls it. A big
   butterfly button in the HUD that jumps straight to the next hint level would let her ask for help without a grown-up.
4. **Let a tap on the princess make her do something.** Tapping the ground walks there; tapping *her* does nothing. A giggle, a
   twirl or a wave on tap is cheap delight and teaches "tapping things makes things happen".
5. **Touch: hold-to-walk on the whole screen half.** The on-screen arrows are small for thumbs. Holding the left or right half of
   the screen (outside the buttons) to walk that way is the pattern most toddler games use.
6. **Shorter story lines.** Several narrator lines are 20+ words ("Giant flowers, glowing mushrooms, and somewhere in here, a
   little lost unicorn"). Four-year-olds follow one idea per sentence; split the long ones into two lines.
7. **A second resident.** The castle gets markedly better with each friend (portraits, wanderers, kitchen visits). The Baby Dragon
   in the plan would prove the pipeline and double the "my castle is alive" feeling.
8. **Autosave on scene changes is already there; add a "last played" resume prompt.** On launch, if a save exists, Flutter could
   say "Welcome back! Lumi is waiting" and go straight to the castle instead of the title screen.
9. **Sound-only confirmation for every button.** Most buttons chime; the category tabs in the creator and the map islands are
   quiet. A consistent tap sound tells a non-reader "that was a button".
10. **Reduce-motion also for the camera sway inside rooms.** Small, but the interior camera drift is more noticeable against
    straight walls than in the forest.

## How this was tested
`godot --headless --path game -- --check` (content cross-references) and `--playthrough` (drives the real systems: quests,
dialogue, magic, care, companion, mini adventure, castle interior; asserts every lifecycle transition and, new in this pass,
walks into the cliff and river edges and up the rainbow). The playthrough runs at 5x and takes about three minutes.
