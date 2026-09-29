#!/usr/bin/env node
// Placeholder audio synthesizer: generates the game's music loops, sound effects and ambience as WAV files.
//   node tools/audio/synth.mjs [--only=<id>] [--list]
// These are original, procedurally composed stand-ins so the game has a complete soundscape from day one.
// Every asset is looked up by id at runtime (game/src/core/audio_manager.gd) - drop a composed .ogg/.mp3/.wav with the
// same name next to it and the game uses that instead. See docs/ASSET_PIPELINE.md.
import { SR, TAU, mtof, clamp, makeBuf, addNote, expDecay, attack, adsr, sine, tri, saw, rng, lowpass, highpass, bandpass, reverb, reverbLoop, normalize, fadeEnds, stats, writeWav } from '../lib/dsp.mjs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'game', 'assets', 'audio');
const args = Object.fromEntries(process.argv.slice(2).map((a) => a.replace(/^--/, '').split('=')).map(([k, v]) => [k, v ?? true]));

// =================================================================================
// instruments (all mono, additive/subtractive, deliberately soft and toy-like)
// =================================================================================
const bell = (buf, t0, f, dur, amp = 0.3, wrap = false) => addNote(buf, t0, dur + 1.6, (t) => {
  const e = Math.exp(-t * 2.6) * attack(t, 0.004);
  return amp * e * (sine(f, t) + 0.42 * sine(f * 2.76, t) * Math.exp(-t * 5) + 0.22 * sine(f * 5.4, t) * Math.exp(-t * 8) + 0.1 * sine(f * 8.93, t) * Math.exp(-t * 12));
}, wrap);
const celesta = (buf, t0, f, dur, amp = 0.3, wrap = false) => addNote(buf, t0, dur + 1.2, (t) => {
  const e = Math.exp(-t * 3.4) * attack(t, 0.003);
  return amp * e * (sine(f, t) + 0.3 * sine(f * 4, t) * Math.exp(-t * 9) + 0.15 * sine(f * 2, t));
}, wrap);
const harp = (buf, t0, f, dur, amp = 0.28, wrap = false) => addNote(buf, t0, dur + 1.4, (t) => {
  let s = 0;
  for (let h = 1; h <= 6; h++) s += sine(f * h, t) * (1 / h) * Math.exp(-t * (1.6 + h * 1.5));
  return amp * s * attack(t, 0.002);
}, wrap);
const marimba = (buf, t0, f, dur, amp = 0.3, wrap = false) => addNote(buf, t0, 0.7, (t) => {
  const e = Math.exp(-t * 7.5) * attack(t, 0.002);
  return amp * e * (sine(f, t) + 0.5 * sine(f * 4, t) * Math.exp(-t * 20));
}, wrap);
const pad = (buf, t0, f, dur, amp = 0.12, wrap = false) => addNote(buf, t0, dur + 1.2, (t) => {
  const env = adsr(t, dur, 0.7, 0.3, 0.8, 1.1);
  const v = 1 + 0.004 * sine(0.3, t);
  return amp * env * (sine(f * v, t) + 0.6 * tri(f * 1.003, t) + 0.35 * sine(f * 2, t) + 0.15 * sine(f * 3, t));
}, wrap);
const flute = (buf, t0, f, dur, amp = 0.2, wrap = false, r = rng(f | 0)) => addNote(buf, t0, dur + 0.25, (t) => {
  const env = adsr(t, dur, 0.06, 0.1, 0.85, 0.2);
  const vib = 1 + 0.006 * sine(5.2, t) * clamp(t * 3, 0, 1);
  return amp * env * (sine(f * vib, t) + 0.18 * sine(f * 2 * vib, t) + 0.04 * (r() - 0.5));
}, wrap);
const bass = (buf, t0, f, dur, amp = 0.3, wrap = false) => addNote(buf, t0, dur + 0.3, (t) => {
  const env = adsr(t, dur, 0.01, 0.15, 0.6, 0.2);
  return amp * env * (sine(f, t) + 0.3 * tri(f, t) * Math.exp(-t * 2));
}, wrap);
const kick = (buf, t0, amp = 0.35, wrap = false) => addNote(buf, t0, 0.3, (t) => amp * Math.exp(-t * 12) * sine(120 * Math.exp(-t * 14) + 45, t), wrap);
function shaker(buf, t0, amp = 0.06, wrap = false, r = rng(7)) {
  addNote(buf, t0, 0.09, (t) => amp * Math.exp(-t * 55) * (r() * 2 - 1), wrap);
}

// =================================================================================
// composition
// =================================================================================
const PENT = { major: [0, 2, 4, 7, 9], minor: [0, 3, 5, 7, 10] };
const pentNote = (root, mode, idx) => root + Math.floor(idx / 5) * 12 + PENT[mode][((idx % 5) + 5) % 5];
const CH = { maj: [0, 4, 7], min: [0, 3, 7] };

const PHRASES = {
  A: [ [[0, 2, 1], [1, 3, 1], [2, 4, 1.5], [3.5, 3, 0.5]], [[0, 2, 2], [2, 1, 1], [3, 0, 1]], [[0, 1, 1], [1, 2, 1], [2, 3, 1], [3, 4, 1]], [[0, 3, 2], [2, 2, 1], [3, 1, 1]] ],
  A2: [ [[0, 4, 1.5], [1.5, 3, 0.5], [2, 2, 1], [3, 3, 1]], [[0, 4, 2], [2, 5, 1], [3, 4, 1]], [[0, 5, 1], [1, 4, 1], [2, 3, 1], [3, 2, 1]], [[0, 1, 1.5], [1.5, 2, 0.5], [2, 0, 2]] ],
  B: [ [[0, 2, 2], [2, 3, 2]], [[0, 4, 3], [3, 3, 1]], [[0, 2, 2], [2, 1, 2]], [[0, 0, 4]] ],
  B2: [ [[0, 3, 2], [2, 4, 2]], [[0, 5, 3], [3, 4, 1]], [[0, 3, 2], [2, 2, 2]], [[0, 1, 2], [2, 0, 2]] ],
  C: [ [[0, 2, 0.5], [0.5, 3, 0.5], [1, 4, 1], [2, 3, 0.5], [2.5, 2, 0.5], [3, 3, 1]], [[0, 4, 0.5], [0.5, 3, 0.5], [1, 2, 1], [2, 1, 1], [3, 0, 1]], [[0, 2, 0.5], [0.5, 3, 0.5], [1, 4, 1], [2, 5, 1], [3, 4, 1]], [[0, 3, 1], [1, 2, 1], [2, 1, 0.5], [2.5, 2, 0.5], [3, 0, 1]] ],
  D: [ [[0, 2, 0.5], [0.5, 3, 0.5], [1, 4, 0.5], [1.5, 3, 0.5], [2, 2, 0.5], [2.5, 3, 0.5], [3, 4, 1]], [[0, 5, 0.5], [0.5, 4, 0.5], [1, 3, 0.5], [1.5, 4, 0.5], [2, 2, 1], [3, 1, 1]], [[0, 3, 0.5], [0.5, 4, 0.5], [1, 5, 0.5], [1.5, 4, 0.5], [2, 3, 0.5], [2.5, 2, 0.5], [3, 3, 1]], [[0, 4, 0.5], [0.5, 3, 0.5], [1, 2, 0.5], [1.5, 1, 0.5], [2, 2, 1], [3, 0, 1]] ],
};
const INSTR = { bell, celesta, harp, marimba, flute };

/** cfg: name, bpm, bars, root (midi of scale tonic, melody octave), mode, prog:[[semitone offset from root, 'maj'|'min'] x4],
 *  phrases:[phrase keys], melody:'bell'|..., arp:'harp'|..|null, pad, bass:'half'|'eighths'|null, perc:'shaker'|'ride'|null, wet, sparkle */
function composeTrack(cfg) {
  const beat = 60 / cfg.bpm, barLen = 4 * beat, secs = cfg.bars * barLen;
  const buf = makeBuf(secs), R = rng(cfg.seed ?? 3);
  const chordAt = (bar) => cfg.prog[bar % cfg.prog.length];
  for (let bar = 0; bar < cfg.bars; bar++) {
    const t0 = bar * barLen;
    const [off, type] = chordAt(bar);
    const rootM = cfg.root - 12 + off;      // chord root, one octave below the melody root
    const notes = CH[type].map((s) => rootM + s);
    if (cfg.pad) for (const n of notes) pad(buf, t0, mtof(n), barLen * 1.02, cfg.padAmp ?? 0.1, true);
    if (cfg.bass === 'half') { bass(buf, t0, mtof(rootM - 12), 2 * beat, 0.26, true); bass(buf, t0 + 2 * beat, mtof(rootM - 12 + (type === 'maj' ? 7 : 7)), 2 * beat, 0.2, true); }
    if (cfg.bass === 'eighths') for (let k = 0; k < 8; k++) bass(buf, t0 + k * beat / 2, mtof(rootM - 12 + (k % 4 === 3 ? 7 : 0)), beat * 0.45, 0.22, true);
    if (cfg.arp) {
      const inst = INSTR[cfg.arp], pat = cfg.arpPat ?? [0, 1, 2, 1, 0, 1, 2, 1], up = cfg.arpUp ?? 12;
      for (let k = 0; k < pat.length; k++) {
        const n = notes[pat[k] % 3] + up + (pat[k] >= 3 ? 12 : 0);
        inst(buf, t0 + k * barLen / pat.length, mtof(n), beat * 0.9, cfg.arpAmp ?? 0.16, true);
      }
    }
    if (cfg.perc === 'shaker') for (let k = 0; k < 8; k++) if (k % 2 === 1 || cfg.dense) shaker(buf, t0 + k * beat / 2, 0.05, true, R);
    if (cfg.perc === 'ride') { for (let k = 0; k < 8; k++) shaker(buf, t0 + k * beat / 2, k % 2 ? 0.07 : 0.045, true, R); kick(buf, t0, 0.3, true); kick(buf, t0 + 2 * beat, 0.26, true); }
    // melody phrase for this bar
    const pk = cfg.phrases[Math.floor(bar / 4) % cfg.phrases.length], phrase = PHRASES[pk][bar % 4];
    const inst = INSTR[cfg.melody];
    for (const [b, idx, len] of phrase) {
      const n = pentNote(cfg.root, cfg.mode, idx + (cfg.melOff ?? 0));
      inst(buf, t0 + b * beat, mtof(n), len * beat * 0.95, cfg.melAmp ?? 0.24, true);
      if (cfg.melody2) INSTR[cfg.melody2](buf, t0 + b * beat, mtof(n + 12), len * beat * 0.8, 0.07, true);
    }
    // random high sparkles for magic
    if (cfg.sparkle) for (let k = 0; k < cfg.sparkle; k++) if (R() < 0.6) celesta(buf, t0 + R() * barLen, mtof(pentNote(cfg.root + 12, cfg.mode, Math.floor(R() * 6))), 0.3, 0.06, true);
  }
  reverbLoop; const out = reverbLoop(buf, cfg.wet ?? 0.28, 0.84);
  return normalize(out, 0.72);
}

const MUSIC = {
  title_theme:     { bpm: 76, bars: 8, root: 72, mode: 'major', prog: [[0, 'maj'], [9, 'min'], [5, 'maj'], [7, 'maj']], phrases: ['A', 'A2'], melody: 'bell', melody2: 'celesta', arp: 'harp', pad: true, wet: 0.34, sparkle: 3, seed: 11 },
  customize_theme: { bpm: 92, bars: 8, root: 74, mode: 'major', prog: [[0, 'maj'], [7, 'maj'], [9, 'min'], [5, 'maj']], phrases: ['C', 'A2'], melody: 'bell', arp: 'harp', pad: true, perc: 'shaker', bass: 'half', wet: 0.3, sparkle: 2, seed: 4 },
  castle_theme:    { bpm: 84, bars: 8, root: 77, mode: 'major', prog: [[0, 'maj'], [9, 'min'], [5, 'maj'], [7, 'maj']], phrases: ['B', 'B2'], melody: 'flute', arp: 'harp', arpAmp: 0.14, pad: true, bass: 'half', wet: 0.32, sparkle: 2, seed: 5 },
  map_theme:       { bpm: 104, bars: 8, root: 67, mode: 'major', prog: [[0, 'maj'], [7, 'maj'], [9, 'min'], [5, 'maj']], phrases: ['C', 'D'], melody: 'flute', melody2: 'marimba', arp: 'harp', pad: true, bass: 'half', perc: 'shaker', wet: 0.26, seed: 6 },
  forest_explore:  { bpm: 100, bars: 16, root: 67, mode: 'major', prog: [[0, 'maj'], [5, 'maj'], [9, 'min'], [7, 'maj']], phrases: ['C', 'A', 'C', 'B2'], melody: 'marimba', melody2: 'flute', arp: 'harp', arpPat: [0, 2, 1, 2, 0, 2, 1, 2], pad: true, padAmp: 0.08, bass: 'half', perc: 'shaker', wet: 0.28, sparkle: 2, seed: 8 },
  forest_moonlit:  { bpm: 64, bars: 8, root: 69, mode: 'minor', prog: [[0, 'min'], [-4, 'maj'], [3, 'maj'], [-2, 'maj']], phrases: ['B', 'B2'], melody: 'celesta', arp: 'bell', arpPat: [0, 1, 2, 1], arpAmp: 0.1, arpUp: 24, pad: true, padAmp: 0.13, wet: 0.5, sparkle: 4, seed: 9 },
  stable_lullaby:  { bpm: 58, bars: 8, root: 74, mode: 'major', prog: [[0, 'maj'], [5, 'maj'], [7, 'maj'], [0, 'maj']], phrases: ['B', 'B2'], melody: 'bell', pad: true, padAmp: 0.09, wet: 0.4, sparkle: 3, seed: 10 },
  ride_theme:      { bpm: 132, bars: 16, root: 72, mode: 'major', prog: [[0, 'maj'], [7, 'maj'], [9, 'min'], [5, 'maj']], phrases: ['D', 'C', 'D', 'A2'], melody: 'bell', melody2: 'marimba', arp: 'harp', arpPat: [0, 1, 2, 1, 0, 1, 2, 1], arpAmp: 0.11, pad: true, padAmp: 0.07, bass: 'eighths', perc: 'ride', wet: 0.22, seed: 12 },
  celebration:     { bpm: 112, bars: 8, root: 72, mode: 'major', prog: [[0, 'maj'], [5, 'maj'], [7, 'maj'], [0, 'maj']], phrases: ['D', 'A2'], melody: 'bell', melody2: 'flute', arp: 'harp', pad: true, bass: 'half', perc: 'shaker', dense: true, wet: 0.3, sparkle: 4, seed: 13 },
};

function rescueSwell() {
  // 4 bars, slow: warm chords swell, bells climb, then a bright resolve. Loops gently.
  const bpm = 66, beat = 60 / bpm, bar = 4 * beat, buf = makeBuf(4 * bar);
  const prog = [[60, 'maj'], [65, 'maj'], [67, 'maj'], [60, 'maj']];
  prog.forEach(([r, t], i) => {
    for (const s of CH[t]) { pad(buf, i * bar, mtof(r + s), bar * 1.05, 0.13, true); pad(buf, i * bar, mtof(r + s + 12), bar * 1.05, 0.06, true); }
    bass(buf, i * bar, mtof(r - 24), bar * 0.95, 0.24, true);
    [0, 1, 2, 3, 4, 5, 6, 7].forEach((k) => harp(buf, i * bar + k * bar / 8, mtof(r + 12 + CH[t][k % 3] + (k > 4 ? 12 : 0)), beat, 0.14, true));
  });
  const mel = [[0, 76, 3], [3, 79, 1], [4, 77, 3], [7, 81, 1], [8, 79, 2], [10, 83, 2], [12, 84, 4]];
  for (const [b, n, l] of mel) { flute(buf, b * beat, mtof(n), l * beat, 0.2, true); bell(buf, b * beat, mtof(n + 12), l * beat, 0.09, true); }
  return normalize(reverbLoop(buf, 0.4, 0.86), 0.74);
}

// =================================================================================
// sound effects
// =================================================================================
const P = (root, mode, idxs) => idxs.map((i) => mtof(pentNote(root, mode, i)));
const SFX = {
  ui_tap:   () => { const b = makeBuf(0.5); bell(b, 0, 1046, 0.05, 0.4); bell(b, 0.03, 1568, 0.05, 0.18); return b; },
  ui_soft:  () => { const b = makeBuf(0.35); addNote(b, 0, 0.3, (t) => 0.4 * Math.exp(-t * 14) * sine(660 + 90 * t, t)); return b; },
  ui_magic: () => { const b = makeBuf(1.2); P(72, 'major', [0, 1, 2, 3, 4, 5]).forEach((f, i) => harp(b, i * 0.06, f, 0.2, 0.3)); bell(b, 0.4, 2093, 0.3, 0.2); return reverb(b, 0.3); },
  jump:     () => { const b = makeBuf(0.35); addNote(b, 0, 0.3, (t) => 0.32 * Math.exp(-t * 7) * sine(300 + 900 * t, t)); bell(b, 0.05, 1568, 0.1, 0.12); return b; },
  land:     () => { const b = makeBuf(0.25); addNote(b, 0, 0.2, (t) => 0.5 * Math.exp(-t * 22) * sine(140 * Math.exp(-t * 10) + 50, t)); return b; },
  step_grass: () => { const b = makeBuf(0.14), r = rng(5); addNote(b, 0, 0.12, (t) => 0.5 * Math.exp(-t * 40) * (r() * 2 - 1)); return lowpass(b, 2600); },
  whoosh:   () => { const b = makeBuf(0.7), r = rng(2); addNote(b, 0, 0.65, (t) => Math.sin(Math.PI * t / 0.65) * (r() * 2 - 1) * 0.6); return bandpass(bandpass(b, 900, 0.7), 1400, 0.8); },
  whoosh_soft: () => { const b = makeBuf(1.1), r = rng(3); addNote(b, 0, 1.05, (t) => Math.sin(Math.PI * t / 1.05) ** 2 * (r() * 2 - 1) * 0.5); return lowpass(bandpass(b, 700, 0.6), 1800); },
  page_turn: () => { const b = makeBuf(0.8), r = rng(4); addNote(b, 0, 0.7, (t) => (Math.sin(Math.PI * t / 0.7) ** 2) * (r() * 2 - 1) * 0.5 * (0.6 + 0.4 * sine(38, t))); highpass(b, 700); bell(b, 0.4, 2093, 0.2, 0.1); return b; },
  page_flip: () => { const b = makeBuf(0.3), r = rng(6); addNote(b, 0, 0.22, (t) => Math.exp(-t * 14) * (r() * 2 - 1) * 0.5); return highpass(b, 1200); },
  chime_soft: () => { const b = makeBuf(1.6); bell(b, 0, 1046, 0.3, 0.3); bell(b, 0.12, 1318, 0.3, 0.25); return reverb(b, 0.3); },
  chime_up: () => { const b = makeBuf(1.6); P(76, 'major', [0, 2, 3, 5]).forEach((f, i) => bell(b, i * 0.11, f, 0.3, 0.28)); return reverb(b, 0.32); },
  chime_trail: () => { const b = makeBuf(1.6); P(88, 'major', [4, 3, 2, 1, 0]).forEach((f, i) => celesta(b, i * 0.09, f, 0.2, 0.22)); return reverb(b, 0.3); },
  magic_charge: () => { const b = makeBuf(0.9); addNote(b, 0, 0.9, (t) => 0.16 * (t / 0.9) * (sine(500 + 1400 * (t / 0.9) ** 2, t) + 0.5 * sine((500 + 1400 * (t / 0.9) ** 2) * 1.5, t)) * (1 + 0.3 * sine(14, t))); P(84, 'major', [0, 2, 3, 4, 5]).forEach((f, i) => celesta(b, 0.15 + i * 0.12, f, 0.2, 0.12)); return reverb(b, 0.3); },
  magic_flourish: () => { const b = makeBuf(2.2); P(72, 'major', [0, 1, 2, 3, 4, 5, 6, 7, 8]).forEach((f, i) => harp(b, i * 0.055, f, 0.3, 0.26)); [0, 2, 4].forEach((k, i) => bell(b, 0.55 + i * 0.09, mtof(pentNote(96, 'major', k)), 0.4, 0.2)); pad(b, 0.2, mtof(72), 1.2, 0.08); pad(b, 0.2, mtof(79), 1.2, 0.08); return reverb(b, 0.4); },
  horn_charge: () => { const b = makeBuf(1.1); addNote(b, 0, 1.05, (t) => 0.22 * Math.sin(Math.PI * t / 1.05) * sine(420 + 700 * t, t) * (1 + 0.25 * sine(9, t))); P(96, 'major', [0, 1, 2, 3]).forEach((f, i) => bell(b, 0.4 + i * 0.1, f, 0.2, 0.12)); return reverb(b, 0.3); },
  star_get: () => { const b = makeBuf(1.0); bell(b, 0, 1568, 0.2, 0.32); bell(b, 0.09, 2093, 0.3, 0.3); bell(b, 0.18, 2637, 0.4, 0.24); return reverb(b, 0.28); },
  secret_found: () => { const b = makeBuf(2.2); P(72, 'minor', [0, 2, 3, 4, 5, 7]).forEach((f, i) => celesta(b, i * 0.16, f, 0.3, 0.26)); bell(b, 1.0, 1568, 0.6, 0.22); return reverb(b, 0.45); },
  wish_pick: () => { const b = makeBuf(0.9); bell(b, 0, 2093, 0.2, 0.3); bell(b, 0.06, 3136, 0.2, 0.14); return reverb(b, 0.3); },
  boing: () => { const b = makeBuf(0.6); addNote(b, 0, 0.5, (t) => 0.36 * Math.exp(-t * 5) * sine(220 + 320 * Math.exp(-t * 9) + 40 * sine(28, t), t)); return b; },
  splash: () => { const b = makeBuf(0.9), r = rng(9); addNote(b, 0, 0.7, (t) => Math.exp(-t * 6) * (r() * 2 - 1) * 0.6); bandpass(b, 1800, 0.5); for (let i = 0; i < 4; i++) addNote(b, 0.1 + i * 0.09, 0.08, (t) => 0.2 * Math.exp(-t * 30) * sine(900 + 500 * t * 10 + i * 200, t)); return b; },
  push: () => { const b = makeBuf(0.8), r = rng(11); addNote(b, 0, 0.55, (t) => 0.5 * Math.sin(Math.PI * t / 0.55) * (r() * 2 - 1)); lowpass(b, 500); addNote(b, 0.55, 0.2, (t) => 0.5 * Math.exp(-t * 20) * sine(90, t)); return b; },
  vine_grow: () => { const b = makeBuf(1.8), r = rng(12); addNote(b, 0, 1.7, (t) => 0.4 * (t / 1.7) * (r() * 2 - 1) * (0.5 + 0.5 * sine(24 + 20 * t, t))); highpass(bandpass(b, 2400, 1.2), 900); P(84, 'major', [0, 1, 2, 3, 4, 5, 6]).forEach((f, i) => celesta(b, 0.2 + i * 0.2, f, 0.2, 0.14)); return reverb(b, 0.35); },
  bloom_big: () => { const b = makeBuf(2.8); P(72, 'major', [0, 1, 2, 3, 4, 5, 6, 7]).forEach((f, i) => harp(b, i * 0.07, f, 0.4, 0.26)); for (const n of [60, 64, 67, 72]) pad(b, 0.1, mtof(n), 1.6, 0.11); bell(b, 0.7, 2093, 0.6, 0.22); return reverb(b, 0.45); },
  rainbow_make: () => { const b = makeBuf(2.6); P(72, 'major', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]).forEach((f, i) => { harp(b, i * 0.1, f, 0.3, 0.24); bell(b, i * 0.1 + 0.04, f * 2, 0.2, 0.08); }); pad(b, 0.4, mtof(72), 1.8, 0.1); return reverb(b, 0.42); },
  starlight_cast: () => { const b = makeBuf(2.0), r = rng(14); for (let i = 0; i < 14; i++) celesta(b, r() * 0.9, mtof(pentNote(84, 'major', Math.floor(r() * 8))), 0.2, 0.16); pad(b, 0, mtof(79), 1.2, 0.08); return reverb(b, 0.45); },
  rabbit_squeak: () => { const b = makeBuf(0.4); [0, 0.14].forEach((t0) => addNote(b, t0, 0.12, (t) => 0.3 * Math.sin(Math.PI * t / 0.12) * sine(1500 + 900 * t / 0.12, t))); return b; },
  happy_chime: () => { const b = makeBuf(1.2); P(76, 'major', [0, 2, 3]).forEach((f, i) => bell(b, i * 0.08, f, 0.2, 0.28)); return reverb(b, 0.28); },
  hug_chime: () => { const b = makeBuf(1.8); for (const n of [72, 76, 79]) pad(b, 0, mtof(n), 0.6, 0.16); P(84, 'major', [0, 2]).forEach((f, i) => bell(b, 0.1 + i * 0.12, f, 0.3, 0.18)); return reverb(b, 0.4); },
  brush: () => { const b = makeBuf(0.6), r = rng(15); for (let i = 0; i < 4; i++) addNote(b, i * 0.13, 0.11, (t) => Math.sin(Math.PI * t / 0.11) * (r() * 2 - 1) * 0.3); return highpass(lowpass(b, 6000), 1500); },
  munch: () => { const b = makeBuf(0.7), r = rng(16); for (let i = 0; i < 3; i++) addNote(b, i * 0.16, 0.1, (t) => Math.exp(-t * 30) * (r() * 2 - 1) * 0.5); return bandpass(b, 1200, 0.6); },
  flutter: () => { const b = makeBuf(0.3), r = rng(17); addNote(b, 0, 0.25, (t) => Math.sin(Math.PI * t / 0.25) * (r() * 2 - 1) * 0.35 * (0.5 + 0.5 * sine(40, t))); return highpass(b, 2000); },
  door_open: () => { const b = makeBuf(1.6); addNote(b, 0, 1.2, (t) => 0.16 * Math.sin(Math.PI * t / 1.2) * saw(90 + 60 * t + 10 * sine(8, t), t)); lowpass(b, 900); bell(b, 1.0, 1046, 0.3, 0.2); bell(b, 1.12, 1568, 0.3, 0.18); return reverb(b, 0.3); },
  sparkle_pick: () => { const b = makeBuf(0.9), r = rng(18); for (let i = 0; i < 4; i++) celesta(b, i * 0.05, mtof(pentNote(90, 'major', 2 + Math.floor(r() * 5))), 0.15, 0.2); return reverb(b, 0.3); },
  rescue_sting: () => { const b = makeBuf(4.2); [[60, 0], [64, 0], [67, 0], [72, 0]].forEach(([n]) => pad(b, 0, mtof(n), 1.0, 0.16)); [[65, 1.0], [69, 1.0], [72, 1.0], [77, 1.0]].forEach(([n, t]) => pad(b, t, mtof(n), 1.0, 0.16)); [[67, 2.0], [71, 2.0], [74, 2.0], [79, 2.0]].forEach(([n, t]) => pad(b, t, mtof(n), 1.6, 0.18)); P(84, 'major', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]).forEach((f, i) => harp(b, 2.0 + i * 0.07, f, 0.5, 0.22)); bell(b, 2.6, 2093, 1.0, 0.25); bell(b, 2.7, 2637, 1.0, 0.2); return reverb(b, 0.45); },
};

// =================================================================================
// ambience (12 s seamless loops)
// =================================================================================
function loopify(raw, fadeSecs = 1.5) {
  const F = Math.floor(fadeSecs * SR), L = raw.length - F, out = new Float32Array(L);
  for (let i = 0; i < L; i++) out[i] = raw[i];
  for (let i = 0; i < F; i++) { const w = i / F; out[i] = raw[i] * w + raw[L + i] * (1 - w); }
  return out;
}
const AMBIENT = {
  forest_birds: () => {
    const r = rng(21), raw = makeBuf(13.5);
    const bed = makeBuf(13.5); for (let i = 0; i < bed.length; i++) bed[i] = (r() * 2 - 1) * 0.05; lowpass(bed, 420);
    for (let i = 0; i < bed.length; i++) raw[i] += bed[i] * (1 + 0.4 * sine(0.15, i / SR));
    for (let c = 0; c < 22; c++) {
      const t0 = r() * 12.5, f0 = 2400 + r() * 2200, n = 2 + Math.floor(r() * 3), amp = 0.06 + r() * 0.06;
      for (let k = 0; k < n; k++) addNote(raw, t0 + k * 0.11, 0.09, (t) => amp * Math.sin(Math.PI * t / 0.09) * sine(f0 * (1 + 0.25 * (t / 0.09) * (k % 2 ? -1 : 1)) + 60 * sine(38, t), t));
    }
    return normalize(loopify(raw), 0.42);
  },
  forest_wind: () => {
    const r = rng(22), raw = makeBuf(13.5);
    for (let i = 0; i < raw.length; i++) raw[i] = (r() * 2 - 1);
    lowpass(raw, 700);
    for (let i = 0; i < raw.length; i++) raw[i] *= 0.35 + 0.25 * sine(0.11, i / SR) + 0.12 * sine(0.27, i / SR);
    return normalize(loopify(raw), 0.32);
  },
  night_crickets: () => {
    const r = rng(23), raw = makeBuf(13.5);
    for (let g = 0; g < 7; g++) {
      const f = 3900 + r() * 1200, t0 = r() * 8, n = 20 + Math.floor(r() * 10), rate = 0.045 + r() * 0.01;
      for (let k = 0; k < n; k++) if (k % 5 !== 4) addNote(raw, t0 + k * rate, 0.022, (t) => 0.07 * Math.sin(Math.PI * t / 0.022) * sine(f, t));
    }
    const bed = makeBuf(13.5); for (let i = 0; i < bed.length; i++) bed[i] = (r() * 2 - 1) * 0.06; lowpass(bed, 300);
    for (let i = 0; i < raw.length; i++) raw[i] += bed[i];
    return normalize(loopify(raw), 0.4);
  },
  garden_water: () => {
    const r = rng(24), raw = makeBuf(13.5);
    for (let i = 0; i < raw.length; i++) raw[i] = (r() * 2 - 1) * 0.5;
    bandpass(raw, 1500, 0.6);
    for (let i = 0; i < raw.length; i++) raw[i] *= 0.6 + 0.4 * sine(0.9 + 0.3 * sine(0.2, i / SR), i / SR);
    for (let b = 0; b < 40; b++) addNote(raw, r() * 12.5, 0.07, (t) => 0.06 * Math.exp(-t * 30) * sine(700 + 1400 * t * 8 + b * 20, t));
    return normalize(loopify(raw), 0.34);
  },
  stable_soft: () => {
    const r = rng(25), raw = makeBuf(13.5);
    for (let i = 0; i < raw.length; i++) raw[i] = (r() * 2 - 1);
    lowpass(raw, 240);
    for (let i = 0; i < raw.length; i++) raw[i] *= 0.4 + 0.15 * sine(0.09, i / SR);
    for (let k = 0; k < 3; k++) addNote(raw, 2 + r() * 8, 0.5, (t) => 0.02 * Math.sin(Math.PI * t / 0.5) * sine(180 + 30 * t, t));
    return normalize(loopify(raw), 0.22);
  },
};

// =================================================================================
const jobs = [];
for (const [id, cfg] of Object.entries(MUSIC)) jobs.push(['music', id, () => composeTrack({ name: id, ...cfg })]);
jobs.push(['music', 'rescue_swell', rescueSwell]);
for (const [id, fn] of Object.entries(SFX)) jobs.push(['sfx', id, () => fadeEnds(normalize(fn(), 0.85))]);
for (const [id, fn] of Object.entries(AMBIENT)) jobs.push(['ambient', id, fn]);

if (args.list) { for (const [k, id] of jobs) console.log(k + '/' + id); process.exit(0); }
let done = 0;
for (const [kind, id, fn] of jobs) {
  if (args.only && args.only !== id) continue;
  const t0 = Date.now(), buf = fn(), s = stats(buf);
  writeWav(join(ROOT, kind, id + '.wav'), buf);
  console.log(`${kind}/${id}.wav  ${(buf.length / SR).toFixed(1)}s  peak=${s.peak.toFixed(2)} rms=${s.rms.toFixed(3)}  (${Date.now() - t0}ms)`);
  done++;
}
console.log(`\nwrote ${done} files to ${ROOT}`);
