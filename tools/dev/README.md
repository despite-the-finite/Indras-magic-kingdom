# Dev tooling

## Godot version

Pinned to **Godot 4.7.2 stable** (standard build). Export templates must be the same version.

Windows quick setup (what this repo was developed with):

```powershell
$t="$HOME\tools\godot"; New-Item -ItemType Directory -Force $t | Out-Null
Invoke-WebRequest https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip -OutFile "$t\godot.zip"
Expand-Archive "$t\godot.zip" $t -Force
# export templates (needed for web export): download Godot_v4.7.2-stable_export_templates.tpz, unzip it,
# copy the "templates" folder contents to %APPDATA%\Godot\export_templates\4.7.2.stable\
```

Scripts read `GODOT` (path to the *console* exe) and default to `~/tools/godot/Godot_v4.7.2-stable_win64_console.exe`.

## Scripts

- `shot.sh <name> [game args]` — render a scene to `shots/<name>.png` (`SIZE=1280x720`). Examples:
  `bash tools/dev/shot.sh forest --scene=forest_rescue --preset=fresh --skipintro --shot-delay=4`
- `godot --headless --path game -- --check` — data validation.
- `godot --headless --path game -- --playthrough [--from=rescue|care|friendship|ride]` — automated slice run.

## Web export

`game/export_presets.cfg` defines a **Web** preset (single-threaded, so it works on any static host without special headers; Compatibility renderer).

```bash
mkdir -p build/web
godot --headless --path game --export-release "Web" ../build/web/index.html
# serve locally
cd build/web && python -m http.server 8080        # or: npx serve
```

Notes: first load is ~35–40 MB (engine wasm ≈ 30 MB uncompressed; enable gzip/brotli on the host to cut it to ~10 MB). Audio starts after the first tap (browser autoplay rules) — the title screen's Play button covers this.
Deploy `build/web` to any static host (GitHub Pages, Netlify, itch.io).

## Regenerating audio / voice

`node tools/audio/synth.mjs` (placeholder music/SFX/ambience) · `node tools/voice/generate.mjs` (see docs/VOICE_PIPELINE.md). After adding audio: `godot --headless --path game --import`.
