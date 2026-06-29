# VibePerks for Codex

A quiet, one-line sponsor in your Codex terminal title and prompt that earns you a
little credit while you code. One line, no popups, nothing to click - and **nothing
about your code, prompts, or files ever leaves your machine.**

```
Fast APIs for every chain - alchemy.com
```

Codex exposes no custom status-line slot, so VibePerks renders into the terminal title
and the prompt line above your input instead.

## How it works

Two parts, deliberately separate so the terminal never waits on a server:

- **The render surface** (`vibeperks-codex render`) runs on every prompt repaint. It only
  reads a cached ad file, marks it displayed, and prints - **zero network calls**, so
  the line is always instant.
- **The Codex prompt hook** (`vibeperks-codex prompt`) fires on `UserPromptSubmit`
  (thinking start). It spawns a detached worker that records the previously displayed
  impression, fetches the next ad, and flushes the impression buffer. The host CLI is
  never blocked.

All network, auth, caching, and privacy live in the shared Go client
([`../claude-code/src/core`](../claude-code/src/core)), reused unchanged; the adapter
([`src/main.go`](src/main.go)) only hooks the Codex lifecycle and where to draw text.
Every command runs inside a single fail-silent boundary (`core.Guard`) - if anything
goes wrong, the error is swallowed and Codex proceeds normally. That boundary is the
**only** place errors are swallowed.

## What leaves your machine

| Leaves your machine | Never leaves your machine |
|---|---|
| Device token (to authenticate) | Your code or file contents |
| Display facts: how long an ad was shown, CLI + plugin version | Your prompts or Codex's replies |
| | File names, paths, or repo names |

## Install

```
./install.sh            # macOS/Linux: build + add shell integration
./install.ps1           # Windows PowerShell
```

Then link your device once (token from the VibePerks website):

```
vibeperks-codex login <device-token>
```

The Codex plugin hooks live in [`.codex-plugin/plugin.json`](.codex-plugin/plugin.json)
and [`hooks/hooks.json`](hooks/hooks.json); install them through Codex's plugin system.

Local state lives in `~/.vibeperks/` (override with `$VIBEPERKS_HOME`). The API base can be
overridden with `$VIBEPERKS_API`.

## Opt out

```
vibeperks-codex optout   # fetch nothing, report nothing
vibeperks-codex optin    # re-enable
```

## Build

Requires Go 1.23+. `bin/vibeperks-codex` is a committed launcher; it auto-builds or
runs a prebuilt distribution binary, so installs work without a manual build.

```
./build.sh            # builds bin/vibeperks-codex.real for your platform
DIST=1 ./build.sh     # also cross-compiles the distribution binaries
```

## Commands

| Command | Hook / use | Purpose |
|---------|------------|---------|
| `render` | prompt repaint | render the cached ad (no network), mark it displayed |
| `prompt` | UserPromptSubmit | thinking start -> spawn detached `refresh` |
| `refresh` | (detached) | record the prior impression, serve + cache the next ad, flush |
| `stop` | session end | report the displayed impression (for hosts with a stop signal) |
| `login <token>` | manual | store the device token |
| `optout` / `optin` | manual | toggle ad fetching/reporting |

See [`context/plans/plugin/`](../../context/plans/plugin) for the full design.

## License

Source-available under the [PolyForm Shield License 1.0.0](LICENSE). You may read,
audit, and use this code, but not to build a product that competes with VibePerks.
Copyright (c) 2026 VibePerks.