// Tiny dependency-free DSP toolkit: buffers, oscillators, filters, reverb, WAV writer.
// Used by tools/audio/synth.mjs (placeholder music/SFX/ambience) and tools/voice/generate.mjs (placeholder speech).
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

export const SR = 24000;
export const TAU = Math.PI * 2;

export const mtof = (m) => 440 * Math.pow(2, (m - 69) / 12);
export const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

export function makeBuf(seconds, sr = SR) {
  return new Float32Array(Math.ceil(seconds * sr));
}

/** mix `fn(t)` (t seconds since note start) into buf at t0; wraps around the end when `wrap` (seamless loops). */
export function addNote(buf, t0, dur, fn, wrap = false, sr = SR) {
  const start = Math.floor(t0 * sr);
  const n = Math.floor(dur * sr);
  const L = buf.length;
  for (let i = 0; i < n; i++) {
    let idx = start + i;
    if (idx >= L) { if (!wrap) break; idx %= L; }
    buf[idx] += fn(i / sr);
  }
}

// ---- envelopes -------------------------------------------------------------------
export const expDecay = (t, rate) => Math.exp(-t * rate);
export const attack = (t, a) => (t >= a ? 1 : t / a);
export function adsr(t, dur, a, d, s, r) {
  if (t < a) return t / a;
  if (t < a + d) return 1 - (1 - s) * ((t - a) / d);
  if (t < dur) return s;
  if (t < dur + r) return s * (1 - (t - dur) / r);
  return 0;
}

// ---- oscillators -------------------------------------------------------------------
export const sine = (f, t, ph = 0) => Math.sin(TAU * f * t + ph);
export const tri = (f, t) => { const x = (f * t) % 1; return 4 * Math.abs(x - 0.5) - 1; };
export const saw = (f, t) => 2 * ((f * t) % 1) - 1;
export function rng(seed = 1) {
  let s = seed >>> 0 || 1;
  return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
}

// ---- filters -----------------------------------------------------------------------
export function lowpass(buf, cutoff, sr = SR) {
  const a = 1 - Math.exp(-TAU * cutoff / sr);
  let y = 0;
  for (let i = 0; i < buf.length; i++) { y += a * (buf[i] - y); buf[i] = y; }
  return buf;
}
export function highpass(buf, cutoff, sr = SR) {
  const a = 1 - Math.exp(-TAU * cutoff / sr);
  let y = 0;
  for (let i = 0; i < buf.length; i++) { y += a * (buf[i] - y); buf[i] = buf[i] - y; }
  return buf;
}
/** RBJ biquad band-pass (constant 0 dB peak). */
export function bandpass(buf, f0, q, sr = SR) {
  const w0 = TAU * f0 / sr, alpha = Math.sin(w0) / (2 * q), cw = Math.cos(w0);
  const b0 = alpha, b1 = 0, b2 = -alpha, a0 = 1 + alpha, a1 = -2 * cw, a2 = 1 - alpha;
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < buf.length; i++) {
    const x = buf[i];
    const y = (b0 / a0) * x + (b1 / a0) * x1 + (b2 / a0) * x2 - (a1 / a0) * y1 - (a2 / a0) * y2;
    x2 = x1; x1 = x; y2 = y1; y1 = y; buf[i] = y;
  }
  return buf;
}

// ---- reverb (Schroeder) -------------------------------------------------------------
export function reverb(buf, wet = 0.25, room = 0.82, sr = SR) {
  const combs = [1557, 1617, 1491, 1422].map((d) => Math.floor(d * sr / 44100));
  const aps = [225, 556].map((d) => Math.floor(d * sr / 44100));
  const out = new Float32Array(buf.length);
  for (const d of combs) {
    const line = new Float32Array(d); let p = 0, lp = 0;
    for (let i = 0; i < buf.length; i++) {
      const y = line[p]; lp += 0.35 * (y - lp);
      line[p] = buf[i] + lp * room; p = (p + 1) % d; out[i] += y / combs.length;
    }
  }
  for (const d of aps) {
    const line = new Float32Array(d); let p = 0;
    for (let i = 0; i < out.length; i++) {
      const y = line[p]; const x = out[i];
      line[p] = x + y * 0.5; p = (p + 1) % d; out[i] = y - x * 0.5;
    }
  }
  for (let i = 0; i < buf.length; i++) buf[i] = buf[i] * (1 - wet * 0.5) + out[i] * wet * 2.2;
  return buf;
}
/** Loop-safe reverb: run it on 3 copies concatenated and keep the middle so the tail wraps seamlessly. */
export function reverbLoop(buf, wet = 0.25, room = 0.82) {
  const L = buf.length, big = new Float32Array(L * 3);
  big.set(buf, 0); big.set(buf, L); big.set(buf, 2 * L);
  reverb(big, wet, room);
  return big.slice(L, 2 * L);
}

// ---- output ---------------------------------------------------------------------------
export function normalize(buf, peak = 0.89) {
  let m = 0; for (let i = 0; i < buf.length; i++) m = Math.max(m, Math.abs(buf[i]));
  if (m > 0) { const g = peak / m; for (let i = 0; i < buf.length; i++) buf[i] *= g; }
  return buf;
}
export function fadeEnds(buf, ms = 6, sr = SR) {
  const n = Math.floor(ms * sr / 1000);
  for (let i = 0; i < n && i < buf.length; i++) { const g = i / n; buf[i] *= g; buf[buf.length - 1 - i] *= g; }
  return buf;
}
export function stats(buf) {
  let peak = 0, sum = 0;
  for (let i = 0; i < buf.length; i++) { const a = Math.abs(buf[i]); peak = Math.max(peak, a); sum += buf[i] * buf[i]; }
  return { peak, rms: Math.sqrt(sum / buf.length) };
}
export function writeWav(path, buf, sr = SR) {
  const n = buf.length, data = Buffer.alloc(44 + n * 2);
  data.write('RIFF', 0); data.writeUInt32LE(36 + n * 2, 4); data.write('WAVE', 8); data.write('fmt ', 12);
  data.writeUInt32LE(16, 16); data.writeUInt16LE(1, 20); data.writeUInt16LE(1, 22);
  data.writeUInt32LE(sr, 24); data.writeUInt32LE(sr * 2, 28); data.writeUInt16LE(2, 32); data.writeUInt16LE(16, 34);
  data.write('data', 36); data.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) data.writeInt16LE(Math.round(clamp(buf[i], -1, 1) * 32767), 44 + i * 2);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, data);
}
