# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Toolchain is managed by **rokit** (`rokit install`). Packages are managed by **pesde** (`pesde install`).

```sh
just dev          # parallel: blink watcher + argon sourcemap watcher + argon serve (main dev loop)
stylua src        # format all source files
stylua --check src  # check formatting (used in CI)
selene src        # lint
```

CI runs `stylua --check src` and `selene src` on push/PR to main.

## Project structure

Argon syncs `src/` to the Roblox DataModel via `default.project.json`:

| Filesystem | Roblox location |
|---|---|
| `src/Server/` | ServerScriptService |
| `src/Shared/` | ReplicatedStorage |
| `src/Client/` | ReplicatedStorage/Client |
| `src/Preload/` | ReplicatedFirst |
| `src/Storage/` | ServerStorage |
| `roblox_packages/` | ReplicatedStorage/Packages |
| `roblox_server_packages/` | ServerScriptService/ServerPackages |

### `src/Shared/` layout

```
src/Shared/
├── Data/           # shared data templates (e.g. PlayerData default values)
├── Libraries/      # self-contained packages — have their own internal structure/state (e.g. Chance, Collections)
├── Types/          # type definition modules (no runtime code)
└── Utilities/      # stateless helpers and infrastructure (e.g. Loader, NumberUtil, TableUtil, Debounce)
```

**Libraries** vs **Utilities**: a library is a small reusable project with its own API surface (like a mini-package); a utility is a thin helper module. When in doubt: if it has submodules or encapsulates non-trivial state, it's a library.

## Service/controller architecture

`src/Shared/Utilities/Loader.luau` bootstraps all services and controllers. Any `ModuleScript` whose parent folder is named `Services` is automatically treated as a service — no boilerplate needed. Lifecycle:

1. **`OnInit()`** — called synchronously in dependency order; use for setup that other services depend on
2. **`OnStart()`** — spawned via `task.spawn` after all `OnInit` calls complete; safe to yield

Dependencies are declared by name (matching the `ModuleScript` instance name):

```luau
-- PUBLIC MODULE
const MyService = {}
MyService.Dependencies = { "PlayerService" }  -- optional

function MyService:OnInit() end  -- PascalCase because called by Loader (public contract)
function MyService:OnStart() end  -- can yield

return MyService
```

### Server folder convention

```
src/Server/
├── Shared/Services/          # foundational — any feature service may depend on these
└── [Feature]/Services/       # feature-specific — no cross-feature dependencies allowed
```

`PlayerService` lives in `Shared/Services/` because it is a reliable foundation. A feature service (e.g. `src/Server/Round/Services/RoundService.luau`) may declare `Dependencies = { "PlayerService" }`, but a service in `Misc/Services/` must never depend on a service in `Round/Services/` or vice versa.

The loader API returns Promises:

```luau
Loader.Load(container)   -- requires all modules, calls OnInit in dependency order; resolves with the services list
    :andThen(Loader.Start)  -- spawns OnStart on each service; safe to yield
    :catch(function(err)
        warn("Loader failed:", err)
    end)
```

`Load` rejects if dependency resolution or any `OnInit` throws. `Start` always resolves immediately after spawning.

## Networking

**blink** compiles `src/Network.blink` into typed RemoteEvent/RemoteFunction wrappers. Run `just blink` (or `just dev`) to watch for changes. The server-side generated module is used from `src/Server/Network/Server.luau` and the client-side from `src/Client/Network/Client.luau` (both gitignored). Events are namespaced by blink `scope` blocks, so a `Sync` event inside `scope Data` is reached as `Network.Data.Sync`.

## State management

**Charm** provides reactive state. Stores use `Charm.signal(initial)`, which returns a `(getter, setter)` pair — read with the getter (reactive when called inside an effect/Vide computed), write with the setter. The setter takes a value or an updater `(current) -> next`; always return a **new** table, since Charm only detects a change when the signal is set to a fresh value.

Store modules live in `src/Server/Store/` and `src/Client/Store/`. Shared data shape templates (e.g. `PlayerData`) live in `src/Shared/Data/Templates/`.

**CharmSync** replicates server state to clients (`charm-sync` exposes a flat `CharmSync.server` / `CharmSync.client` API, not a factory). State is matched across sides by string key, so a store exposes exactly the half its side uses:

- **Server store** exposes its **getter** (`PlayerDataStore.Getter`) — the server only reads state to diff it.
- **Client store** exposes its **setter** (`PlayerDataStore.Setter`) — the client only writes received patches.

`DataReplicationService` (server) registers each player via `CharmSync.server.addSignalsToClient(player, { key = getter })` on `PlayerService.PlayerAdded`. The blink `Data.Sync` event models charm-sync's `SyncPayload` as a tagged enum (`init`/`patch`, each with `data: unknown`) and carries **one** payload per fire, so the service fans the charm-sync batch out (`for payload in payloads do Network.Data.Sync.Fire(player, payload) end`). `DataReplicationController` (client) registers the setter with `CharmSync.client.addSignals`, then `Network.Data.Sync.On` wraps each received payload in a list for `CharmSync.client.patch`. The `data` field stays `unknown` because the inner patch tables are dynamic; `unknown` round-trips them with full fidelity, and `config.fixArrays` (default) handles array serialization. blink also buffers events received before the client attaches its listener, so early payloads are not lost.

**Synced maps must be keyed by string.** Any store replicated through CharmSync should key its map by `tostring(userId)` (not the raw numeric `userId`), and the client accessor must look up with the same `tostring`. Numeric keys can be coerced crossing the sync/remote boundary, leaving the client unable to find its own entry (the data replicates, but the lookup misses). `PlayerDataStore` on both sides follows this.

`PlayerService` profiles remain the persistent source of truth; the synced store is a separate in-memory view. To push a live change to clients, write it through the store (e.g. `PlayerDataStore.Update(userId, mutator)`) — mutating `record.Data` in place persists but does not replicate. Keep sensitive fields out of the synced store, since the single map replicates to every client.

## UI

- **Vide** — primary reactive UI framework for production UI
- **Iris** — immediate-mode debug overlay
- **UiLabs** — story viewer; stories are `.story.luau` files in `src/Client/ui/stories/`
- **Fluid** — additional reactive primitives

## Dev console

**Conch** provides an in-game command console. Server commands go in `src/Server/conch/commands/`, client commands in `src/Client/conch/commands/`. The corresponding service/controller that registers them lives alongside in a `services/` or `controllers/` subfolder.

## Code style

- Luau **strict mode** is enforced project-wide (`.luaurc`)
- StyLua is configured with `call_parentheses = "None"` — omit parentheses on single-string and single-table calls
- Selene uses `std = "roblox"` with `shadowing = true`

### Module layout

The canonical reference is `src/Client/Example.luau`. Every module uses this section-header order (omit sections that don't apply):

```
-- SERVICES
-- IMPORTED MODULES
-- TYPES
-- ALIASES
-- CONSTANTS
-- PRIVATE STATE
-- PRIVATE FUNCTIONS
-- PRIVATE MODULE
-- PUBLIC MODULE
```

### Naming

All files and folders under `src/` are **PascalCase** — this includes every directory and every `.luau` filename.

Public exports (functions and values on the returned module table) are **PascalCase**. Private functions, state, and internal modules use **camelCase**, prefixed with `_` if they are private state.

Do not abbreviate identifiers. Write the full word (`humanoidRootPart`, not `hrp`; `modifiers`, not `mods`). The only exceptions are abbreviations that are globally standard and universally understood (`ui`, `id`).

### `const` vs `local`

Use `const` for any binding that is never reassigned — top-level variables, inner functions, and locals inside function bodies. Only use `local` when the variable is actually reassigned later. Mutating a table does not count as reassignment; the binding is still `const`.
