#!/usr/bin/env node
// Voice-over pipeline: game/data/dialogue/*.json  ->  game/assets/audio/vo/<line_id>.mp3  (ElevenLabs, build-time only)
//
//   node tools/voice/generate.mjs --list                    list every line + cache status
//   node tools/voice/generate.mjs --dry-run                 show what would be generated and the character cost
//   node tools/voice/generate.mjs                           generate all missing/changed lines with ElevenLabs
//   node tools/voice/generate.mjs --only=lumi               only one character (or a single line id / sequence id)
//   node tools/voice/generate.mjs --force                   regenerate even if cached
//   node tools/voice/generate.mjs --placeholder             synthesize offline "babble" speech into vo/_ph/ (no API, no key)
//   node tools/voice/generate.mjs --export-script=vo.csv    export a recording script (for a human voice actor)
//
// SECURITY: the API key is read from the ELEVENLABS_API_KEY environment variable or tools/voice/.env (git-ignored).
// It is never written to game files, never logged, and never shipped. The game only plays the cached audio files.
import { readFileSync, writeFileSync, existsSync, readdirSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { SR, TAU, makeBuf, addNote, sine, saw, rng, lowpass, bandpass, normalize, fadeEnds, writeWav } from '../lib/dsp.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, '..', '..');
const DIALOGUE_DIR = join(ROOT, 'game', 'data', 'dialogue');
const VO_DIR = join(ROOT, 'game', 'assets', 'audio', 'vo');
const CACHE_FILE = join(HERE, 'voice-cache.json');
const args = Object.fromEntries(process.argv.slice(2).map((a) => a.replace(/^--/, '').split('=')).map(([k, v]) => [k, v ?? true]));

// ---- load config + lines ------------------------------------------------------------------
const cfg = JSON.parse(readFileSync(join(HERE, 'voices.json'), 'utf8'));

function loadLines() {
  const lines = [];
  for (const f of readdirSync(DIALOGUE_DIR).filter((x) => x.endsWith('.json')).sort()) {
    const d = JSON.parse(readFileSync(join(DIALOGUE_DIR, f), 'utf8'));
    for (const [seq, arr] of Object.entries(d.sequences ?? {})) {
      arr.forEach((raw, i) => {
        const ln = { ...(d.defaults ?? {}), ...raw, sequence: seq, index: i, count: arr.length, prev: arr[i - 1]?.text, next: arr[i + 1]?.text };
        lines.push(ln);
      });
    }
  }
  return lines;
}

function voiceFor(ln) {
  const v = cfg.voices[ln.character] ?? cfg.voices.narrator;
  const emo = cfg.emotions[ln.emotion] ?? {};
  const settings = {
    stability: clamp01((v.stability ?? 0.5) + (emo.stability_delta ?? 0)),
    similarity_boost: v.similarity_boost ?? 0.8,
    style: clamp01((v.style ?? 0.2) + (emo.style_delta ?? 0)),
    use_speaker_boost: true,
    speed: Math.max(0.7, Math.min(1.2, (v.speed ?? 1.0) * (emo.speed_mult ?? 1))),
  };
  const tag = cfg.use_audio_tags ? (cfg.emotion_tags?.[ln.emotion] ?? '') : '';
  return { voice_id: v.voice_id, settings, text: (tag ? tag + ' ' : '') + ln.text };
}
const clamp01 = (x) => Math.max(0, Math.min(1, x));
const hashOf = (ln) => {
  const v = voiceFor(ln);
  return createHash('sha256').update(JSON.stringify([v.text, v.voice_id, cfg.model, cfg.output_format, v.settings])).digest('hex').slice(0, 16);
};

function loadCache() { return existsSync(CACHE_FILE) ? JSON.parse(readFileSync(CACHE_FILE, 'utf8')) : {}; }
function saveCache(c) { writeFileSync(CACHE_FILE, JSON.stringify(c, Object.keys(c).sort(), 2) + '\n'); }

function loadKey() {
  if (process.env.ELEVENLABS_API_KEY) return process.env.ELEVENLABS_API_KEY.trim();
  const envFile = join(HERE, '.env');
  if (existsSync(envFile)) {
    for (const l of readFileSync(envFile, 'utf8').split(/\r?\n/)) {
      const m = l.match(/^\s*ELEVENLABS_API_KEY\s*=\s*(.+?)\s*$/);
      if (m) return m[1].replace(/^["']|["']$/g, '');
    }
  }
  return '';
}

// ---- selection ------------------------------------------------------------------------------
let lines = loadLines();
if (typeof args.only === 'string') lines = lines.filter((l) => l.character === args.only || l.id === args.only || l.sequence === args.only);
const cache = loadCache();
const status = (l) => {
  const mp3 = join(VO_DIR, l.id + '.mp3');
  if (!existsSync(mp3)) return 'missing';
  return cache[l.id] === hashOf(l) ? 'cached' : 'changed';
};
const todo = lines.filter((l) => args.force || status(l) !== 'cached');
const chars = todo.reduce((n, l) => n + voiceFor(l).text.length, 0);

if (args.list) {
  for (const l of lines) console.log(`${status(l).padEnd(8)} ${l.id.padEnd(30)} ${(l.character ?? '').padEnd(9)} ${(l.emotion ?? '').padEnd(10)} ${l.text}`);
  console.log(`\n${lines.length} lines, ${todo.length} to generate (~${chars} characters)`);
  process.exit(0);
}
if (args['export-script']) {
  const esc = (s) => '"' + String(s).replace(/"/g, '""') + '"';
  const rows = [['id', 'character', 'emotion', 'animation', 'text'], ...lines.map((l) => [l.id, l.character, l.emotion ?? '', l.animation ?? '', l.text])];
  writeFileSync(String(args['export-script']), rows.map((r) => r.map(esc).join(',')).join('\n') + '\n');
  console.log('wrote', args['export-script']);
  process.exit(0);
}

// ---- placeholder speech (offline) ---------------------------------------------------------------
const VOWELS = { a: [800, 1200], e: [500, 1900], i: [320, 2300], o: [500, 900], u: [350, 700] };
const VOICE_PITCH = { narrator: 200, princess: 270, lumi: 320, clover: 350, luna: 225 };
function babble(ln) {
  const r = rng([...ln.id].reduce((a, c) => (a * 31 + c.charCodeAt(0)) >>> 0, 7));
  const base = VOICE_PITCH[ln.character] ?? 240;
  const words = ln.text.replace(/[^\w\s'?!.,]/g, '').split(/\s+/).filter(Boolean);
  const excited = ['excited', 'joyful', 'surprised', 'wonder'].includes(ln.emotion);
  const sylPerWord = words.map((w) => Math.max(1, Math.round(w.replace(/[^a-z]/gi, '').length / 3)));
  const totalSyl = sylPerWord.reduce((a, b) => a + b, 0);
  const sylDur = 0.17, gap = 0.05, wordGap = 0.09;
  const total = totalSyl * (sylDur + gap) + words.length * wordGap + 0.3;
  const out = makeBuf(total);
  let t = 0.05, s = 0;
  const question = /\?\s*$/.test(ln.text);
  words.forEach((w, wi) => {
    const vowels = w.toLowerCase().replace(/[^aeiou]/g, '') || 'a';
    for (let k = 0; k < sylPerWord[wi]; k++, s++) {
      const [f1, f2] = VOWELS[vowels[k % vowels.length]];
      const prog = s / Math.max(1, totalSyl - 1);
      const contour = question ? 1 + 0.35 * prog : 1 - 0.18 * prog;
      const f0 = base * (excited ? 1.12 : 1) * contour * (1 + 0.07 * Math.sin(s * 1.7) + (r() - 0.5) * 0.05);
      const syl = makeBuf(sylDur + 0.03);
      addNote(syl, 0, sylDur, (tt) => {
        const env = Math.sin(Math.PI * Math.min(1, tt / sylDur)) ** 0.7;
        return env * saw(f0 * (1 + 0.012 * sine(5.5, tt)), tt);
      });
      const a = bandpass(Float32Array.from(syl), f1, 4), b = bandpass(Float32Array.from(syl), f2, 6);
      for (let i = 0; i < syl.length; i++) { const idx = Math.floor(t * SR) + i; if (idx < out.length) out[idx] += a[i] * 1.6 + b[i] * 1.0; }
      t += sylDur + gap;
    }
    t += wordGap;
  });
  return fadeEnds(normalize(lowpass(out, 4200), 0.3), 10);
}

if (args.placeholder) {
  const dir = join(VO_DIR, '_ph');
  mkdirSync(dir, { recursive: true });
  let n = 0;
  for (const l of lines) {
    const p = join(dir, l.id + '.wav');
    if (existsSync(p) && !args.force) continue;
    writeWav(p, babble(l));
    n++;
  }
  console.log(`wrote ${n} placeholder speech files to ${dir} (not committed; regenerate any time)`);
  process.exit(0);
}

// ---- ElevenLabs generation ---------------------------------------------------------------------
if (args['dry-run']) {
  for (const l of todo) console.log(`would generate ${l.id}  [${l.character}/${l.emotion ?? '-'}]  ${voiceFor(l).text.length} chars`);
  console.log(`\n${todo.length} lines, ~${chars} characters (model ${cfg.model})`);
  const bad = Object.entries(cfg.voices).filter(([, v]) => !v.voice_id || v.voice_id.startsWith('REPLACE'));
  if (bad.length) console.log('voices without an id yet:', bad.map(([k]) => k).join(', '));
  process.exit(0);
}
const key = loadKey();
if (!key) { console.error('No ElevenLabs key found. Set ELEVENLABS_API_KEY or create tools/voice/.env (see .env.example).'); process.exit(2); }
const missingVoices = [...new Set(todo.map((l) => l.character))].filter((c) => !(cfg.voices[c]?.voice_id) || cfg.voices[c].voice_id.startsWith('REPLACE'));
if (missingVoices.length) { console.error('Set real voice_id values in tools/voice/voices.json for:', missingVoices.join(', ')); process.exit(2); }
mkdirSync(VO_DIR, { recursive: true });

async function synth(ln) {
  const v = voiceFor(ln);
  const url = `https://api.elevenlabs.io/v1/text-to-speech/${v.voice_id}?output_format=${cfg.output_format}`;
  const body = { text: v.text, model_id: cfg.model, voice_settings: v.settings };
  if (ln.prev) body.previous_text = ln.prev;   // helps prosody continuity within a sequence
  if (ln.next) body.next_text = ln.next;
  for (let attempt = 0; attempt < 5; attempt++) {
    const res = await fetch(url, { method: 'POST', headers: { 'xi-api-key': key, 'Content-Type': 'application/json', Accept: 'audio/mpeg' }, body: JSON.stringify(body) });
    if (res.ok) return Buffer.from(await res.arrayBuffer());
    if (res.status === 429 || res.status >= 500) { await new Promise((r) => setTimeout(r, 1500 * 2 ** attempt)); continue; }
    throw new Error(`ElevenLabs ${res.status}: ${(await res.text()).slice(0, 200)}`);
  }
  throw new Error('ElevenLabs: too many retries');
}

let ok = 0, fail = 0;
for (const l of todo) {
  try {
    writeFileSync(join(VO_DIR, l.id + '.mp3'), await synth(l));
    cache[l.id] = hashOf(l);
    saveCache(cache);
    console.log('generated', l.id);
    ok++;
  } catch (e) { console.error('FAILED', l.id, e.message); fail++; }
}
console.log(`\ndone: ${ok} generated, ${fail} failed, ${lines.length - todo.length} already cached`);
console.log('Next: run `godot --headless --path game --import` so Godot imports the new audio files.');
process.exit(fail ? 1 : 0);
