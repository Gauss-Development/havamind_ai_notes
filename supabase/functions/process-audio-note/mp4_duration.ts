// Minimal MP4 / M4A (ISO-BMFF) duration reader.
//
// The app records AAC-LC in an .m4a container (audio_recording_service.dart),
// so the true recording length can be read from the `moov → mvhd` box. This
// lets the server be authoritative on `duration_seconds` instead of trusting
// the client-supplied value (which could be set to 0 to defeat the usage
// quota). Returns the duration in whole seconds, or null if the atom cannot
// be found or parsed.

interface BoxContent {
  start: number; // first byte of box payload
  end: number; // one past the last byte of box payload
}

function ascii(dv: DataView, pos: number): string {
  return String.fromCharCode(
    dv.getUint8(pos),
    dv.getUint8(pos + 1),
    dv.getUint8(pos + 2),
    dv.getUint8(pos + 3),
  );
}

/** Find a direct child box of the given type within [start, end). */
function findBox(
  dv: DataView,
  start: number,
  end: number,
  type: string,
): BoxContent | null {
  let pos = start;
  while (pos + 8 <= end) {
    let size = dv.getUint32(pos);
    let header = 8;
    if (size === 1) {
      // 64-bit largesize follows the type field.
      if (pos + 16 > end) break;
      size = Number(dv.getBigUint64(pos + 8));
      header = 16;
    } else if (size === 0) {
      // Box extends to the end of the enclosing range.
      size = end - pos;
    }
    if (size < header) break;
    const boxEnd = Math.min(pos + size, end);
    if (ascii(dv, pos + 4) === type) {
      return { start: pos + header, end: boxEnd };
    }
    pos = boxEnd;
  }
  return null;
}

function parseMvhd(dv: DataView, start: number, end: number): number | null {
  if (start + 4 > end) return null;
  const version = dv.getUint8(start);
  let timescale: number;
  let duration: number;
  if (version === 1) {
    // version+flags(4) creation(8) modification(8) timescale(4) duration(8)
    if (start + 32 > end) return null;
    timescale = dv.getUint32(start + 20);
    duration = Number(dv.getBigUint64(start + 24));
  } else {
    // version+flags(4) creation(4) modification(4) timescale(4) duration(4)
    if (start + 20 > end) return null;
    timescale = dv.getUint32(start + 12);
    duration = dv.getUint32(start + 16);
  }
  if (!timescale || timescale <= 0) return null;
  const seconds = duration / timescale;
  if (!Number.isFinite(seconds) || seconds < 0) return null;
  return Math.round(seconds);
}

export function readMp4DurationSeconds(bytes: Uint8Array): number | null {
  if (bytes.byteLength < 16) return null;
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const moov = findBox(dv, 0, bytes.byteLength, "moov");
  if (!moov) return null;
  const mvhd = findBox(dv, moov.start, moov.end, "mvhd");
  if (!mvhd) return null;
  return parseMvhd(dv, mvhd.start, mvhd.end);
}
