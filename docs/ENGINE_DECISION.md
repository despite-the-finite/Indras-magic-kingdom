# Engine Decision — Godot 4 (GDScript, Compatibility renderer)

**Decision:** Build *Indra's Magic Kingdom* in **Godot 4.7** with **GDScript**, a **2.5D** presentation
(real 3D world, gameplay locked to a readable side-scrolling lane), and the **Compatibility (OpenGL)** renderer so the
same project runs on desktop, mobile browsers and the web.

This was chosen on quality and extensibility, not prototype speed. The comparison below is what actually decided it.

## Criteria (from the brief) and how the candidates score

| Criterion | Godot 4 | Unity 6 | Notes |
|---|---|---|---|
| Beautiful stylized 2.5D | Strong. Custom toon/sky/water/face shaders, glow, fog, shadows. | Stronger raw tooling (URP, Shader Graph, volumetrics on desktop). | Our look is stylized, not photoreal; Godot is sufficient. |
| Character animation | Skeleton + AnimationTree + procedural pose code; imports glTF rigs. | Excellent (Animator, Timeline, Cinemachine). | Unity wins on authoring UX, but we procedurally animate expressive rigs today and can swap in authored clips later. |
| Particles / lighting / shaders | GPUParticles3D, shader language, glow, fog. No SSAO / volumetric fog on Compatibility. | VFX Graph (not on WebGL), URP. | Volumetric light is faked with light-shaft cards + fog + glow. Acceptable for the storybook look. |
| Audio / voice-over | AudioServer buses, easy runtime loading of cached VO. | FMOD/Wwise optional. | Equal for our needs. |
| Controller / mouse / touch | Unified `InputEvent` model; touch emulation built in. | New Input System, more setup. | One code path across all three. |
| Performance on modest hardware | Very light. Dev machine here is a Quadro M1000M. | Heavier baseline. | Kids' devices are often old tablets. |
| **Web deployment** | First-class, small builds, single-thread export needs no special server headers. | Web builds are heavier and slower to load; mobile-browser support weaker. | Web is a hard requirement. |
| Maintainability | Plain-text scenes/scripts/resources, diff-friendly, scriptable from CLI, CI-friendly. | Binary/YAML assets, editor-centric workflow. | Decisive: this project is authored and tested largely from the command line. |
| Expandability | Data-driven content in JSON; easy to add kingdoms. | Also fine. | |
| AI-generated asset compatibility | glTF/GLB is the native 3D interchange format (Blender, Meshy, Tripo, etc.). PNG/WebP/OGG/WAV/MP3 direct. | Also fine, FBX-centric. | Godot's glTF path is the shortest. |
| License / cost | MIT, no fees, no seat licenses. | Runtime/plan terms to track. | Matters for a children's product with no monetization. |

Other candidates rejected:
- **Phaser / Canvas / Three.js / Babylon:** fastest to pixels, but cap the ceiling for lighting, animation and audio; the brief explicitly says not to pick the browser-first option for speed.
- **Unreal:** far beyond what a stylized kids' game needs; web export effectively unavailable.
- **Bevy / custom engine:** no editor, immature animation and UI stack.

## Honest constraints of this choice

1. **Compatibility renderer** is required for web. That means no SSAO, SSIL, SDFGI or volumetric fog. We compensate with
   authored fog, glow/bloom, additive light-shaft meshes, rim-lit toon shading, soft shadows, particles and painterly sky shaders.
   Desktop-only builds could opt into Forward+ later (renderer is a project setting).
2. **No image/3D generation is available inside this repo's build environment.** The vertical slice therefore ships with
   *procedural* stylized art (meshes, shaders and procedural faces built in code). Every such asset sits behind the
   `Assets` library indirection so AI-generated / hand-authored `.glb` models can replace them without touching gameplay
   code. See `ASSET_PIPELINE.md` for the replacement table and art prompts.
3. **Web audio:** we use pre-rendered WAV/MP3/OGG (no runtime audio synthesis) and a single-threaded web export.
4. **Godot version:** pinned to 4.7.2 stable (see `tools/dev/README.md`). Upgrading is a deliberate step.

## Why 2.5D lane gameplay

Navigation must be understandable to a 4-year-old: *left, right, jump.* The world is fully 3D (parallax layers,
foreground foliage, camera drift, fog depth) but the princess moves in a single lane, so there is no camera management, no
"where do I go?" confusion, and no way to get lost. Cinematic camera moves are authored, not player-driven.
