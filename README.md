# roblox_game_template

A Roblox game template built on a strict layered architecture.

## Getting Started

```bash
embr install   # install packages and tools
just dev       # rogen watch, larvae process, sourcemap and rojo serve
```

Then connect to the Rojo server from Roblox Studio.

## Architecture

The source is split into five layers that form a directed acyclic graph. A layer may only import from the layers
below it, never from a layer above.

```
app        the root: entry points and high-level UI layouts
features   vertical slices of gameplay
core       game foundations shared by features
platform   Roblox-specific, game-agnostic
base       platform-agnostic, game-agnostic
```

The structure is inspired by Erich Gamma's work.

### Layers

| Layer        | Uses Roblox APIs | Knows about the game | Portable to other projects |
| ------------ | ---------------- | -------------------- | -------------------------- |
| **Base**     | No               | No                   | Yes                        |
| **Platform** | Yes              | No                   | Yes                        |
| **Core**     | Yes              | Yes                  | No                         |
| **Features** | Yes              | Yes                  | No                         |
| **App**      | Yes              | Yes                  | No                         |

- **Base**: pure Luau with no knowledge of Roblox or the game, such as data structures, math, serialization,
  signals and table utilities. It should be possible to copy this layer into any Luau project unchanged.
- **Platform**: Roblox-specific code that still knows nothing about the game, such as the module `Loader`,
  data store providers and instance helpers. It should be possible to copy this layer into any Roblox project
  unchanged.
- **Core**: types, foundational game logic and data structures, and the modules features are built on, such as a
  `CharacterController`.
- **Features**: vertical slices. Each feature owns everything it needs, from server logic to client UI.
- **App**: the root that boots the game and holds the high-level UI layouts.

### Rules

1. **Import downward only.** A layer may import from any layer below it and never from a layer above it.
2. **No cross-feature imports.** Modules inside one feature may import each other freely, but a feature may never
   import another feature. When two features need the same thing, move it down into Core.
3. **Keep the bottom portable.** Base and Platform must not reference anything game-specific.
4. **Respect run context.** Client code never imports Server code. Shared code may be imported by both.

### Folder layout

```
src/
    Base/
    Platform/
    Core/
    Features/
        <Feature>/
            Server/
            Client/
            Shared/
    App/
        Server/
        Client/
```

### Singletons and lifecycle

`Main.server.luau` and `Main.client.luau` start the `Loader`, which finds every module whose name ends in `Service`
(server) or `Controller` (client), orders them by their `Dependencies` list, then calls `OnInit` on each in order and
`OnStart` on each in its own thread.

```luau
const InventoryService = {}

InventoryService.Dependencies = { "DataService" }

function InventoryService.OnInit() end

function InventoryService.OnStart() end

return InventoryService
```

`Dependencies` follows the same rules as imports: a singleton may only name singletons from its own feature or from a
lower layer.
