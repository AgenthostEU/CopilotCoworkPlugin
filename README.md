# agenthost plugin for Microsoft 365 Copilot Cowork

Connect **Microsoft 365 Copilot Cowork** to [agenthost](https://agenthost.eu) — agent-first web
hosting — so Copilot can create projects, deploy apps from a GitHub repo or an upload, attach
databases, manage domains and environment variables, read deploy logs, and roll back.

The plugin adds two things to Cowork:

- **A connector** to the agenthost remote MCP server at `https://agenthost.eu/mcp`.
- **A skill**, `deploy-on-agenthost`, that teaches Cowork the deploy workflow.

There is **no API key to configure**. agenthost's MCP server supports OAuth 2.1 with
[Dynamic Client Registration](https://datatracker.ietf.org/doc/html/rfc7591), so Cowork
registers its own OAuth client automatically and the user just signs in once in the browser.

## Repository layout

This repo is a cross-platform Agent Skills plugin. The root is a Claude Code / Cursor plugin
(the source of truth); `m365/` holds the pre-built Microsoft 365 app package.

```
.
├── .claude-plugin/plugin.json   # Claude Code / Cursor / atk-import manifest
├── .mcp.json                    # MCP server: { type: http, url: https://agenthost.eu/mcp }
├── skills/
│   └── deploy-on-agenthost/
│       └── SKILL.md             # Agent Skill — works in Cowork AND Claude Code
├── m365/                        # Microsoft 365 Copilot Cowork package
│   ├── manifest.json            # Unified app manifest v1.28
│   ├── color.png                # 192x192 icon (placeholder — replace before store submit)
│   ├── outline.png              # 32x32 icon (placeholder)
│   └── tools/
│       └── agenthost-tools.json # mcpToolDescription — declares the connector's tools
└── scripts/
    ├── gen-icons.mjs            # Regenerate placeholder icons
    └── build-m365-package.sh    # Assemble the uploadable .zip
```

The connector in `m365/manifest.json` intentionally omits the `authorization` block: because
agenthost supports Dynamic Client Registration, Cowork creates the OAuth client on the plugin's
behalf. `mcpToolDescription` is still required — leaving it out fails the upload with HTTP 400.
The actual tool set is discovered live from the server's `tools/list` at runtime; the file is
the manifest-time declaration.

## Build the Microsoft 365 package

**Windows (PowerShell):**

```powershell
pwsh ./scripts/build-m365-package.ps1
# -> m365/build/agenthost-cowork.zip
```

**macOS / Linux (bash):**

```bash
scripts/build-m365-package.sh
# -> m365/build/agenthost-cowork.zip
```

Both require Node.js (for icon generation); the bash version also needs `zip`. The resulting
`.zip` has `manifest.json`, both icons, `tools/`, and `skills/` at its root — the shape Cowork
expects.

A prebuilt, ready-to-upload package is checked in at
[`m365/dist/agenthost-cowork.zip`](./m365/dist/agenthost-cowork.zip) if you'd rather not build
it yourself.

### Alternative: generate the package with the Agents Toolkit

If you prefer Microsoft's tooling, you can import the root plugin instead of hand-maintaining
`m365/manifest.json`:

```bash
npm install -g @microsoft/m365agentstoolkit-cli   # v1.1.12+
atk import openplugin --path . --output ./m365-generated \
  --privacy-url https://agenthost.eu/privacy \
  --terms-url https://agenthost.eu/terms
```

`atk import` reads `.claude-plugin/plugin.json`, `.mcp.json`, and `skills/`. Two hand-edits
afterward: (1) it autodetects the HTTPS URL as `OAuthPluginVault` and inserts a placeholder
`referenceId` — delete that `authorization` block to use Dynamic Client Registration; (2) it
emits a `devPreview` manifest, so bump `manifestVersion`/`$schema` to `1.28` and add the
`mcpToolDescription` file. The checked-in `m365/manifest.json` already reflects the finished
state.

## Install into Copilot Cowork

**Test it for yourself (sideload):**

```bash
npm install -g @microsoft/m365agentstoolkit-cli
atk auth login
atk install --file-path ./m365/build/agenthost-cowork.zip --scope Personal
```

**Publish to your tenant:** Microsoft 365 admin center → **Manage apps** → **Upload custom
app** → upload the `.zip`. It then appears under **Cowork → Sources & Skills → Plugins →
Discover**. Installing prompts the agenthost browser sign-in.

**Publish publicly:** submit via [Partner Center](https://partner.microsoft.com) to the
Microsoft 365 App Store.

## Local development against a local agenthost

The connector requires an HTTPS `mcpServerUrl`. To point Cowork at a local agenthost
(`http://localhost:3000/mcp`), expose it over HTTPS with a dev tunnel and update
`mcpServerUrl` accordingly:

```bash
devtunnel port create <tunnel> -p 3000 --protocol http
```

Use `--protocol http` (it describes the local service; the tunnel serves HTTPS).

## Use in Claude Code or Cursor

The same root plugin works directly:

```bash
# Claude Code
/plugin marketplace add agenthosteu/CopilotCoworkPlugin
/plugin install agenthost
```

Or connect the MCP server on its own: `claude mcp add --transport http agenthost https://agenthost.eu/mcp`.

## License

MIT — see [LICENSE](./LICENSE).
