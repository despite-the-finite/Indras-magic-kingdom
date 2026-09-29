# Voice-over pipeline (ElevenLabs)

Spoken words are **content, not code**. Dialogue lives in `game/data/dialogue/*.json`; audio is generated from it by a build-time script
and cached in the project. The shipped game only plays audio files — **no API key, no network calls, no credentials in client code.**

```
data/dialogue/*.json ──► tools/voice/generate.mjs ──► game/assets/audio/vo/<line_id>.mp3 ──► Audio.play_voice() at runtime
                              ▲                                  ▲
                    tools/voice/voices.json           tools/voice/voice-cache.json (content hashes)
                    ELEVENLABS_API_KEY (env or tools/voice/.env, git-ignored)
```

## Cast (`tools/voice/voices.json`)

`narrator`, `princess`, `lumi`, `clover`, `luna` — each maps to an ElevenLabs `voice_id` plus base `stability / similarity_boost / style / speed`.
`emotions` applies per-line deltas (e.g. `excited`: less stable, more style, slightly faster; `whisper`: more stable, slower). Optional v3-style audio tags (`use_audio_tags`) prefix lines with `[excited]` etc.

## Workflow

1. Cast voices in ElevenLabs, paste the `voice_id`s into `voices.json` (no secrets in that file).
2. `cp tools/voice/.env.example tools/voice/.env`, add your key (git-ignored) — or export `ELEVENLABS_API_KEY`.
3. `node tools/voice/generate.mjs --dry-run` → see lines and total characters (the whole slice is ≈ 4,700 characters).
4. `node tools/voice/generate.mjs` → generates only **missing or changed** lines (content-hash cache). `--only=lumi`, `--only=<line_id>`, `--force` are supported.
5. `godot --headless --path game --import` so Godot imports the new mp3s. Commit `vo/*.mp3` and `voice-cache.json`.
6. Edit a line's text/emotion in JSON → rerun → only that line regenerates. No game code changes.

Retries with exponential backoff on 429/5xx. `previous_text`/`next_text` are sent for lines in the same sequence so prosody flows naturally.

## Runtime lookup order (`Audio.voice_stream`)

1. `res://assets/audio/vo/<id>.mp3` (or `.ogg`/`.wav`) — the real recording
2. `res://assets/audio/vo/_ph/<id>.wav` — offline placeholder babble (`generate.mjs --placeholder`, not committed)
3. nothing → the line still plays with a reading-time estimate, portrait + subtitles + character animation

So development never depends on API availability, and a missing file never blocks the story.

## Other tooling

- `--list` shows status per line (`cached | missing | changed`).
- `--export-script=vo.csv` exports a recording script (id, character, emotion, animation, text) for a human voice actor or a localisation vendor.
- Localisation: add `data/dialogue/<lang>/` later; the id is the key, so translations regenerate the same way.

## Runtime behaviour

Voice plays on the `Voice` bus; music ducks while speaking; speaking characters flap their mouths and play the line's `animation`/`emotion`;
tapping/pressing advances (only after 0.55 s so it can't be skipped by accident); `Settings.narration = false` keeps text + animation but silences voice.
