// Render the Microsoft 365 app-package icons from the agenthost brand mark:
//   m365/color.png   — 192x192 full-color app icon (the "ah" monogram tile)
//   m365/outline.png — 32x32 white-on-transparent silhouette for compact views
//
// Source of truth is m365/brand/agenthost-icon.svg (a copy of the control-plane
// web app's master icon). Regenerate after changing that file:
//
//   npm install        # once, to get sharp
//   node scripts/gen-icons.mjs
//
// The rendered PNGs are committed, so building the package and cutting a release
// do NOT require sharp — only regenerating the icons does.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import sharp from "sharp";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const src = join(root, "m365/brand/agenthost-icon.svg");
const svg = readFileSync(src, "utf8");

// Outline variant: drop the background tile and paint every glyph white so the
// silhouette shows on dark toolbar chrome.
const outlineSvg = svg
  .replace(/<rect[^>]*\/>/, "")
  .replace(/fill="#ece9e1"/g, 'fill="#ffffff"')
  .replace(/fill="#c3f73a"/g, 'fill="#ffffff"');

const transparent = { r: 0, g: 0, b: 0, alpha: 0 };

// color.png: render the full tile at 192x192.
await sharp(Buffer.from(svg))
  .resize(192, 192, { fit: "contain", background: transparent })
  .png()
  .toFile(join(root, "m365/color.png"));

// outline.png: render large, trim to the glyph, then center into 32x32 with a
// 3px transparent margin so the mark fills the frame instead of sitting low-left.
const big = await sharp(Buffer.from(outlineSvg))
  .resize(512, 512, { fit: "contain", background: transparent })
  .png()
  .toBuffer();
const trimmed = await sharp(big).trim().toBuffer();
await sharp(trimmed)
  .resize(26, 26, { fit: "contain", background: transparent })
  .extend({ top: 3, bottom: 3, left: 3, right: 3, background: transparent })
  .png()
  .toFile(join(root, "m365/outline.png"));

console.log("wrote m365/color.png (192x192) and m365/outline.png (32x32)");
