# SQP_Classic Agent Directives

This document records the framework-first build discipline enforced by
`AGENTS.md` and the shared RGX-Framework CI include
(`/.gitlab/ci/addon.yml`). Follow it before writing or changing any code,
UI, timer, event, aura, or slash-command surface.

## The MCP tool loop

Before writing addon code, run the RGX-Framework MCP tools in order. Each
step has a single, ordered purpose; do not reorder or skip:

1. `rgx_get_contract` — read the current declarative contract surface
   (the live `RGXAddon(name, opts)` keys the framework ships today).
2. `rgx_generate_addon` — scaffold the addon file from the contract so
   the generated Lua matches what the framework would produce for these
   opts.
3. `rgx_validate_addon` — validate the actual opts table against the
   contract; fail on unknown, removed, or tier-4 keys.
4. `rgx_audit_lua` — audit every changed Lua file for forbidden raw-WoW
   patterns (see below) and confirm generated Lua matches integration.

Compare the generated Lua with the existing integration, then validate the
actual opts table and audit every changed Lua file. Never hand-roll what
the framework ships.

## The declarative contract

Build addon behavior from the declarative `RGXAddon(name, opts)` table
using **only** keys the framework ships today. Read
`docs/DECLARATIVE-API.md` in `rgxmods/warcraft/RGX-Framework` before
writing code.

- `name` — the addon name (matches the `## Title` TOC field).
- `opts` — the declarative options table. Only shipped keys are valid;
  tier 4 keys are future targets, not runtime features.

Use `onInit` and addon-scoped methods only where the shipped declarative
surface genuinely cannot express the behavior.

## Forbidden raw-WoW patterns

The following patterns fail `rgx_audit_lua` and must not appear in shipped
Lua. Replace them with their framework-managed equivalents; migrate the
fork's existing raw event/timer compatibility paths (deliberate Classic
guards) deliberately, never silently.

| Forbidden pattern | Framework equivalent |
|---|---|
| raw `C_Timer` (e.g. `C_Timer.After`, `C_Timer.NewTicker`) | RGX timers / repeating schedules |
| manual event frames (`CreateFrame("FRAME")`, manual `SetScript`) | `RGX:RegisterEvent` / `RGX:RegisterUnitEvent` |
| `SLASH_` globals | framework slash command registration |
| unguarded `SetAttribute` | framework UI controls / dropdowns |
| raw aura plumbing (`UnitAura`, custom aura watching) | `RGXAuras` module |
| raw hook reassignment (`hooksecurefunc`, `HookScript`) | framework lifecycle hooks |

## Release discipline

Release through the GitLab MR pipeline and green shared validation, then
patch-bump through the same discipline and create a protected GitLab
release tag matching the TOC version. The release flow is:

1. Validate — `addon:validate` (MR + push pipelines) must pass for every
   diff via the shared `.gitlab/ci/addon.yml` include.
2. Mirror — `mirror:github` publishes the identical protected GitLab tag
   to the downstream `RGXMods/SimpleQuestPlates_Classic` mirror.
3. Patch-bump — bump the patch version in `SQP_Classic.toc`
   (`## Version:`) together with `SQP.VERSION` in `data/core.lua` through
   an MR, then create a protected GitLab release tag matching the TOC
   version and retaining the fork's `-classic` identity.

Verify the identical tag on the `RGXMods/SimpleQuestPlates_Classic` mirror
before reporting distribution pickup.

## Supported Interface verification

`SQP_Classic.toc` carries three Classic flavors as a comma-separated list,
derived per the formula in `AGENTS.md` (`## Keeping Interface Versions
Current`): `major * 10000 + minor * 100 + patch`.

| WoW flavor | Client version | Derivation | `## Interface:` value |
|---|---|---|---|
| Classic Era | 1.15.9 | 1*10000 + 15*100 + 9 | `11509` |
| Burning Crusade Classic | 2.5.6 | 2*10000 + 5*100 + 6 | `20506` |
| Mists of Pandaria Classic | 5.5.4 | 5*10000 + 5*100 + 4 | `50504` |

This is a Classic-only fork: the list must not gain the Retail interface
target. Ground truth for verification is the installed client's
`.build.info` (one pipe-delimited row per product, `major.minor.patch.build`
in the Version column). Online cross-checks are wago.tools build pages and
versions.wowtools.io; verify a feed is reachable at runtime before trusting
it. Honest state at authoring time (2026-10-13): both live feeds returned
errors (wago.tools HTTP 503, versions.wowtools.io HTTP 525), so the values
above rest on the verified derivation formula and prior verification, not
on a fresh feed cross-check. If feeds are unreachable and the client is
not installed, never guess an uninstalled flavor's live version.

## Dependency posture

- `## RequiredDeps: RGX-Framework` with
  `## X-RGX-Framework-MinVersion: 2.7.14-beta.1`, kept accurate against
  the framework version line.
- SavedVariables `SQPClassicSettings` matches the declarative `dbName`;
  do not rename without migrating saved settings.

## Version surface

The TOC owns the version: `## Version: 1.9.10-classic.beta.1` in
`SQP_Classic.toc`, mirrored by `SQP.VERSION = "1.9.10-classic.beta.1"` in
`data/core.lua`. Bump both together in the `X.Y.Z-classic.N` pattern.
Version bumps and changelog entries are owned by the release workflow,
not by documentation edits.

## Related references

- Framework canonical docs: `rgxmods/warcraft/RGX-Framework`
  `docs/DECLARATIVE-API.md` and `docs/RGX-MCP.md`
- This addon's contract surface and validation rules: `AGENTS.md`
- Release and CI configuration: `.gitlab-ci.yml`,
  `rgxmods/warcraft/RGX-Framework /.gitlab/ci/addon.yml`
