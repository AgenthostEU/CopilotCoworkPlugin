// Generates placeholder plugin icons required by the Microsoft 365 app package:
//   m365/color.png   — 192x192 full-color app icon
//   m365/outline.png — 32x32 single-color (white on transparent) outline icon
//
// These are deliberately simple placeholders. Replace them with real brand
// artwork before submitting to the Microsoft 365 App Store.
//
// No image libraries are used — PNGs are encoded by hand (RGBA truecolor) so the
// script runs anywhere Node does.
import { deflateSync } from "node:zlib";
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function chunk(type, data) {
  const typeBuf = Buffer.from(type, "ascii");
  const body = Buffer.concat([typeBuf, data]);
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body), 0);
  return Buffer.concat([len, body, crc]);
}

// paint(x, y) -> [r, g, b, a]
function png(size, paint) {
  const raw = Buffer.alloc(size * (size * 4 + 1));
  let o = 0;
  for (let y = 0; y < size; y++) {
    raw[o++] = 0; // filter: none
    for (let x = 0; x < size; x++) {
      const [r, g, b, a] = paint(x, y);
      raw[o++] = r;
      raw[o++] = g;
      raw[o++] = b;
      raw[o++] = a;
    }
  }
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type: RGBA
  return Buffer.concat([
    sig,
    chunk("IHDR", ihdr),
    chunk("IDAT", deflateSync(raw, { level: 9 })),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

const BLUE = [0x2b, 0x57, 0x9a]; // accentColor #2B579A

// color.png: solid brand-blue rounded square with a white "a" bar mark.
function colorPaint(x, y) {
  const s = 192;
  const r = 28; // corner radius
  const inCorner =
    (x < r && y < r && Math.hypot(r - x, r - y) > r) ||
    (x >= s - r && y < r && Math.hypot(x - (s - r), r - y) > r) ||
    (x < r && y >= s - r && Math.hypot(r - x, y - (s - r)) > r) ||
    (x >= s - r && y >= s - r && Math.hypot(x - (s - r), y - (s - r)) > r);
  if (inCorner) return [0, 0, 0, 0];
  // simple white mark: a horizontal bar and a dot, evoking a lowercase "a"
  const bar = y > 132 && y < 150 && x > 48 && x < 144;
  const stem = x > 128 && x < 144 && y > 60 && y < 150;
  const bowl = Math.hypot(x - 96, y - 108) < 34 && Math.hypot(x - 96, y - 108) > 18;
  if (bar || stem || bowl) return [255, 255, 255, 255];
  return [...BLUE, 255];
}

// outline.png: white filled circle on transparent (single-color glyph).
function outlinePaint(x, y) {
  const c = 16;
  return Math.hypot(x - c, y - c) < 13 ? [255, 255, 255, 255] : [0, 0, 0, 0];
}

for (const [path, size, paint] of [
  ["m365/color.png", 192, colorPaint],
  ["m365/outline.png", 32, outlinePaint],
]) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, png(size, paint));
  console.log("wrote", path);
}
