#!/usr/bin/env bash
# Assemble the Microsoft 365 Copilot Cowork app package (.zip).
#
# The package must have manifest.json, the two icons, the tools/ folder, and the
# skills/ folder all at the ZIP root. Skills are the cross-platform source of
# truth at the repo root (they also serve Claude Code / Cursor), so we copy them
# in at build time rather than duplicating them under m365/.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$root/m365/build"
stage="$out/pkg"
zip_path="$out/agenthost-cowork.zip"

rm -rf "$stage" "$zip_path"
mkdir -p "$stage"

# Icons are committed. Regenerate them with `node scripts/gen-icons.mjs` (needs
# sharp) if they are ever missing — we do not auto-generate here so a release
# never ships without the real brand icons.
if [[ ! -f "$root/m365/color.png" || ! -f "$root/m365/outline.png" ]]; then
  echo "error: m365/color.png or m365/outline.png missing." >&2
  echo "       run: npm install && node scripts/gen-icons.mjs" >&2
  exit 1
fi

cp "$root/m365/manifest.json" "$stage/"
cp "$root/m365/color.png" "$stage/"
cp "$root/m365/outline.png" "$stage/"
cp -R "$root/m365/tools" "$stage/tools"
cp -R "$root/skills" "$stage/skills"

( cd "$stage" && zip -r -q "$zip_path" manifest.json color.png outline.png tools skills )
echo "Built $zip_path"
( cd "$stage" && find . -type f | sed 's|^\./||' | sort )
