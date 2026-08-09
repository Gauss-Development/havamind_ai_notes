/**
 * Tests for the MP4/M4A duration reader.
 *
 * Run: deno test supabase/functions/process-audio-note/mp4_duration.test.ts
 */

import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { readMp4DurationSeconds } from "./mp4_duration.ts";

// ── Synthetic ISO-BMFF builders ─────────────────────────────────────────

function box(type: string, payload: Uint8Array): Uint8Array {
  const size = 8 + payload.byteLength;
  const out = new Uint8Array(size);
  const dv = new DataView(out.buffer);
  dv.setUint32(0, size);
  for (let i = 0; i < 4; i++) out[4 + i] = type.charCodeAt(i);
  out.set(payload, 8);
  return out;
}

function concat(...parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((n, p) => n + p.byteLength, 0);
  const out = new Uint8Array(total);
  let off = 0;
  for (const p of parts) {
    out.set(p, off);
    off += p.byteLength;
  }
  return out;
}

function mvhdV0(timescale: number, duration: number): Uint8Array {
  // version+flags(4) creation(4) modification(4) timescale(4) duration(4)
  const payload = new Uint8Array(20);
  const dv = new DataView(payload.buffer);
  dv.setUint8(0, 0); // version 0
  dv.setUint32(12, timescale);
  dv.setUint32(16, duration);
  return payload;
}

function mvhdV1(timescale: number, duration: number): Uint8Array {
  // version+flags(4) creation(8) modification(8) timescale(4) duration(8)
  const payload = new Uint8Array(36);
  const dv = new DataView(payload.buffer);
  dv.setUint8(0, 1); // version 1
  dv.setUint32(20, timescale);
  dv.setBigUint64(24, BigInt(duration));
  return payload;
}

// ── Tests ───────────────────────────────────────────────────────────────

Deno.test("reads v0 mvhd duration, skipping a leading ftyp box", () => {
  const file = concat(
    box("ftyp", new Uint8Array([0x69, 0x73, 0x6f, 0x6d])),
    box("moov", box("mvhd", mvhdV0(1000, 5000))), // 5000/1000 = 5s
  );
  assertEquals(readMp4DurationSeconds(file), 5);
});

Deno.test("reads v1 (64-bit) mvhd duration", () => {
  const file = box("moov", box("mvhd", mvhdV1(48000, 48000 * 42))); // 42s
  assertEquals(readMp4DurationSeconds(file), 42);
});

Deno.test("rounds fractional durations", () => {
  const file = box("moov", box("mvhd", mvhdV0(1000, 5400))); // 5.4s → 5
  assertEquals(readMp4DurationSeconds(file), 5);
});

Deno.test("returns null when moov/mvhd is absent", () => {
  const file = box("ftyp", new Uint8Array(8));
  assertEquals(readMp4DurationSeconds(file), null);
});

Deno.test("returns null for non-MP4 bytes", () => {
  assertEquals(readMp4DurationSeconds(new Uint8Array(4)), null);
  assertEquals(
    readMp4DurationSeconds(new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18])),
    null,
  );
});

Deno.test("returns null when timescale is zero", () => {
  const file = box("moov", box("mvhd", mvhdV0(0, 5000)));
  assertEquals(readMp4DurationSeconds(file), null);
});
