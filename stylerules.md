# Roblox Luau Style Guide

> Single Script Architecture · Module-Heavy · Strict Luau

---

## Table of Contents

1. [Overview](#1-overview)
2. [Project Structure & Folders](#2-project-structure--folders)
3. [File Naming](#3-file-naming)
4. [Formatting](#4-formatting)
5. [Naming Conventions](#5-naming-conventions)
6. [Type Annotations](#6-type-annotations-strict-mode)
7. [Module Structure](#7-module-structure)
8. [Functions](#8-functions)
9. [Comments](#9-comments)
10. [Error Handling](#10-error-handling)
11. [Remotes — Blink](#11-remotes--blink)
12. [SSA-Specific Conventions](#12-ssa-specific-conventions)
13. [Quick Reference](#13-quick-reference)

---

## 1. Overview

This document defines coding style and conventions for all Roblox projects built on a Single Script Architecture (SSA) with topological module loading. Following these rules ensures every module feels like it came from the same author, makes onboarding easy, and keeps the codebase refactorable.

> **These rules are non-negotiable.** If a pattern is not covered here, default to the spirit of the guide: explicit, typed, and consistent.

---

## 2. Project Structure & Folders

### 2.1 Folder Naming

All folders use `camelCase`. This deliberately distinguishes folders from files — if you see `PascalCase` it's a file (ModuleScript), if you see `camelCase` it's a folder.

```
✅  services/
✅  utilities/
✅  combat/
❌  Services/
❌  combat_systems/
❌  utils/
```

### 2.2 Top-Level Layout

The `src/` root is split into three contexts that map to Roblox's security boundaries. Nothing crosses these boundaries except through Blink or `ReplicatedStorage`.

```
src/
├── server/               →  ServerScriptService
├── client/               →  StarterPlayerScripts
├── shared/               →  ReplicatedStorage
└── Network.blink
```

### 2.3 Inside Each Context — Feature + Type

Organise by **feature first**, then by **type** inside each feature. This keeps everything related to a system in one place while still making the role of each file obvious.

```
src/
├── server/
│   ├── Main.server.luau          ← SSA entry point (requires loader)
│   ├── combat/
│   │   ├── services/
│   │   │   └── DamageService.luau
│   │   └── utilities/
│   │       └── HitboxUtil.luau
│   └── inventory/
│       └── services/
│           └── InventoryService.luau
│
├── client/
│   ├── Main.client.luau          ← SSA entry point (requires loader)
│   ├── combat/
│   │   └── controllers/
│   │       └── CombatController.luau
│   └── ui/
│       └── controllers/
│           └── HudController.luau
│
├── shared/
│   ├── utilities/                ← stateless helpers, no dependencies
│   │   ├── TableUtil.luau
│   │   └── MathUtil.luau
│   ├── types/                    ← shared exported types only, no logic
│   │   └── GameTypes.luau
│   └── constants/
│       └── GameConstants.luau
│
└── Network.blink
```

### 2.4 Type Subfolder Names

Use these exact names for typed subfolders — consistency matters more than creativity here.

| Folder         | Contains                                        |
| -------------- | ----------------------------------------------- |
| `services/`    | Server-side stateful logic                      |
| `controllers/` | Client-side stateful logic                      |
| `utilities/`   | Stateless pure functions, no side effects       |
| `types/`       | Shared type definitions only — no runtime logic |
| `constants/`   | Shared constant values only                     |

### 2.5 Rules

- A feature folder with only one subfolder type doesn't need the subfolder — just put the file directly in the feature folder
- `shared/` only contains things genuinely needed on both sides. When in doubt, keep it server-side
- Never create a folder just to hold one file indefinitely — if a feature grows to 2+ files, then introduce the folder
- No deeply nested feature folders — if you need `combat/ranged/hitscan/`, your feature needs splitting

---

## 3. File Naming

### 2.1 ModuleScripts

Always `PascalCase`. The module table returned inside must match the filename exactly.

```
CoinService.luau
PlayerData.luau
WeaponConfig.luau
```

### 2.2 Scripts & LocalScripts

`PascalCase` with a suffix that describes their role. This makes it immediately obvious what context they run in.

| Suffix   | Example                  | Context       |
| -------- | ------------------------ | ------------- |
| `Server` | `MainServer.server.luau` | Server Script |
| `Client` | `MainClient.client.luau` | LocalScript   |
| _(none)_ | `CoinService.luau`       | ModuleScript  |

> If your toolchain (e.g. Rojo) uses `.server.luau` / `.client.luau` extensions to distinguish script types, use those. If not, the suffix convention above still applies to the Instance name.

### 2.3 Blink Schema Files

`PascalCase`, grouped by system if large. Keep all definitions in one file unless the project is very large.

```
Network.blink
```

### 2.4 Avoid

- `snake_case` or `camelCase` filenames — names map to module tables which are `PascalCase`
- Generic names like `Module`, `Handler`, `Manager` with no context
- Abbreviations in filenames — `CoinService` not `CoinSvc`

---

## 4. Formatting

### 3.1 Indentation

Use a single **tab** per indent level. Configure your editor to display tabs at **8 spaces** — this makes deep nesting visually obvious and encourages you to keep functions shallow. Never use spaces.

```lua
-- ✅ correct (tabs, displayed at 8-space width)
local function doThing()
	local x = 1
	if x > 0 then
		return x
	end
end

-- ❌ wrong (spaces)
local function doThing()
    local x = 1
end
```

### 3.2 Line Length

Soft limit of **100 characters**. Hard limit of **120**. Break long chains or argument lists across lines, aligning to the opening parenthesis.

```lua
-- ✅ break long argument lists
local result = someModule.doComplexOperation(
	firstArgument,
	secondArgument,
	thirdArgument
)
```

### 3.3 Blank Lines

- 1 blank line between functions inside a module
- 2 blank lines between major sections (requires, types, module body)
- No trailing blank lines at end of file

### 3.4 Semicolons

Never. Luau does not require them and they add noise.

---

## 5. Naming Conventions

| Pattern           | Used for                                                     |
| ----------------- | ------------------------------------------------------------ |
| `camelCase`       | Local variables, function parameters, module functions       |
| `PascalCase`      | Types, type aliases, module tables, class-like constructors  |
| `SCREAMING_SNAKE` | True constants — values that never change at runtime         |
| `_camelCase`      | Private module-level variables (underscore signals internal) |

Functions always start with a **verb**: `get`, `set`, `on`, `handle`, `create`, `update`, `apply`, etc.

```lua
-- ✅ naming examples
local MAX_PLAYERS: number = 10           -- constant
local _cache: {[string]: any} = {}       -- private module var

type PlayerData = {                      -- PascalCase type
	userId: number,
	coins: number,
}

local function getPlayerData(userId: number): PlayerData  -- verb + camelCase
	...
end

local CoinService = {}                   -- module table = PascalCase
return CoinService
```

### 4.1 Avoid Abbreviations

Write names out in full unless the abbreviation is universally understood (`id`, `ui`, `hp`, `npc`).

| ❌ Avoid | ✅ Use instead |
| -------- | -------------- |
| `plr`    | `player`       |
| `char`   | `character`    |
| `dmg`    | `damage`       |
| `cfg`    | `config`       |
| `mgr`    | `manager`      |

---

## 6. Type Annotations (Strict Mode)

Every file must begin with `--!strict`. All function parameters, return values, and non-trivial local variables must carry explicit type annotations.

### 5.1 File Header

```lua
--!strict
-- ModuleName.luau
-- Brief one-line description of what this module does.
```

### 5.2 Function Signatures

```lua
-- ✅ fully typed
local function applyDamage(character: Model, amount: number): boolean
	...
end

-- ✅ multiple return values
local function getPosition(part: BasePart): (number, number, number)
	local cf = part.CFrame
	return cf.X, cf.Y, cf.Z
end

-- ❌ missing annotations
local function applyDamage(character, amount)
	...
end
```

### 5.3 Type Aliases

Define shared types at the top of each module (after requires). Export them when other modules need them.

```lua
export type WeaponConfig = {
	name: string,
	damage: number,
	fireRate: number,
	isAutomatic: boolean,
}

type _InternalState = {
	equipped: boolean,
	lastFiredAt: number,
}
```

### 5.4 When to use `any`

Avoid entirely unless bridging an untyped Roblox API that cannot be narrowed. When you must, add a comment explaining why, and cast to a known type immediately.

```lua
-- Roblox RemoteEvent args are untyped at the API boundary
remoteEvent.OnServerEvent:Connect(function(player: Player, rawData: any)
	local data = rawData :: PlayerData  -- cast immediately
end)
```

---

## 7. Module Structure

Every ModuleScript follows the same top-to-bottom layout.

```lua
--!strict
-- CoinService.luau
-- Manages player coins: loading, saving, and awarding.


-- 1. SERVICES & ROBLOX APIS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


-- 2. IMPORTED MODULES
local DataStore = require(script.Parent.DataStore)
local Logger    = require(script.Parent.Logger)


-- 3. CONSTANTS
local STARTING_COINS: number = 100
local SAVE_INTERVAL:  number = 30


-- 4. TYPES
export type CoinData = {
	coins: number,
	lastSaved: number,
}


-- 5. PRIVATE STATE
local _coinCache: {[number]: CoinData} = {}


-- 6. PRIVATE FUNCTIONS
local function loadCoinData(userId: number): CoinData
	...
end


-- 7. MODULE TABLE (public API)
local CoinService = {}

function CoinService.getCoins(userId: number): number
	...
end

function CoinService.awardCoins(userId: number, amount: number): ()
	...
end


return CoinService
```

### 6.1 Module Naming

- Name the module table the same as the file (`CoinService.luau` → `local CoinService = {}`)
- Return exactly one table — never a function or a primitive
- Never pollute `_G` or `shared`

### 6.2 Dependency Rules

The SSA loader resolves dependencies via topological sort. To keep the graph acyclic:

- Modules must never require each other in a cycle
- If two modules need each other, extract the shared logic into a third module
- Utilities (stateless helpers) sit at the bottom of the dependency graph and may be required freely

Layer hierarchy — lower layers must not depend on higher ones:

```
Utilities  →  no dependencies
Data       →  Utilities only
Services   →  Utilities, Data
Controllers →  Services (never the reverse)
```

---

## 8. Functions

### 7.1 Size & Responsibility

- A function should do one thing
- If a function exceeds ~30 lines, consider splitting it
- Favour early returns (guard clauses) over deep nesting

```lua
-- ✅ guard clauses
local function rewardPlayer(player: Player, coins: number): ()
	if not player or not player.Parent then return end
	if coins <= 0 then return end
	CoinService.awardCoins(player.UserId, coins)
end

-- ❌ deep nesting
local function rewardPlayer(player: Player, coins: number): ()
	if player then
		if player.Parent then
			if coins > 0 then
				CoinService.awardCoins(player.UserId, coins)
			end
		end
	end
end
```

### 7.2 Event Handlers

Prefix all event handlers with `on`. Keep them thin — delegate real logic to named functions.

```lua
-- ✅ thin handler
local function onPlayerAdded(player: Player): ()
	loadPlayerData(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- ❌ anonymous handler with inline logic
Players.PlayerAdded:Connect(function(player)
	-- 40 lines of logic...
end)
```

---

## 9. Comments

### 8.1 When to Comment

Write comments that explain **why**, not **what**. The code should speak for itself.

```lua
-- ✅ explains WHY
-- Roblox clamps DataStore keys to 50 chars; hash long user IDs to be safe
local key = hashUserId(userId)

-- ❌ explains WHAT (redundant)
-- Set key to the hashed user ID
local key = hashUserId(userId)
```

### 8.2 Section Headers

Use uppercase section headers inside modules to aid navigation (see Section 6 layout).

### 8.3 TODO & FIXME

```lua
-- TODO: replace polling with a signal-based approach once available
-- FIXME: this breaks if the player leaves mid-tween
```

---

## 10. Error Handling

### 9.1 Promises

Use Promises for all async work and any operation that can fail. Never use raw `pcall` for async error handling — Promises give composable, typed error paths.

```lua
local function loadPlayerData(userId: number): Promise<PlayerData>
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function(): PlayerData
			return DataStore:GetAsync(tostring(userId))
		end)
		if success then
			resolve(result or defaultData)
		else
			reject(result)
		end
	end)
end

-- consuming
loadPlayerData(player.UserId)
	:andThen(function(data: PlayerData)
		applyData(player, data)
	end)
	:catch(function(err: string)
		Logger.warn(`Failed to load data for {player.UserId}: {err}`)
		applyData(player, defaultData)
	end)
```

### 9.2 Promise Chaining

Chain with `:andThen` / `:catch`. Keep each callback single-purpose. Use `:finally` for cleanup that must run regardless of outcome.

```lua
-- ✅ flat chain
fetchConfig()
	:andThen(function(config) return applyConfig(config) end)
	:andThen(function() return notifyReady() end)
	:catch(function(err) Logger.error(err) end)
	:finally(function() setLoading(false) end)

-- ❌ nested (Promise hell)
fetchConfig():andThen(function(config)
	applyConfig(config):andThen(function()
		notifyReady()
	end)
end)
```

### 9.3 Assertions

Use `assert()` for synchronous precondition checks. Not a substitute for Promise error handling.

```lua
local function setHealth(character: Model, hp: number): ()
	assert(hp >= 0 and hp <= 100, `hp must be in [0, 100], got {hp}`)
	...
end
```

---

## 11. Remotes — Blink

All client-server communication goes through Blink. Never create raw `RemoteEvent` or `RemoteFunction` instances.

### 10.1 Defining Events

Declare all events in a single `Network.blink` schema file. Group by system. Use `PascalCase` verb+noun names.

```
event ApplyDamage {
	from: Server,
	type: Reliable,
	data: {
		targetId: u32,
		amount:   f32,
	},
}

event PurchaseItem {
	from: Client,
	type: Reliable,
	data: {
		itemId:   string,
		quantity: u8,
	},
}
```

### 10.2 Naming

| ❌ Avoid     | ✅ Use instead   |
| ------------ | ---------------- |
| `CoinUpdate` | `UpdateCoins`    |
| `Damage`     | `ApplyDamage`    |
| `Data`       | `LoadPlayerData` |
| `Event1`     | `PurchaseItem`   |

### 10.3 Server Authority

Blink enforces direction (`from: Client` / `from: Server`) and validates types, but **the server is still always the source of truth**. Always validate business logic server-side.

```lua
Network.PurchaseItem.SetCallback(function(player: Player, data)
	-- Blink handled types; still validate business rules
	if data.quantity <= 0 or data.quantity > MAX_STACK then return end
	if not Inventory.hasItem(player, data.itemId) then return end
	Shop.processPurchase(player, data.itemId, data.quantity)
end)
```

---

## 12. SSA-Specific Conventions

### 11.1 Lifecycle Hooks

Modules that need lifecycle callbacks expose a standard interface. The loader calls these in dependency order.

```lua
local MyService = {}

-- Called once after all modules are loaded
-- Do not call other services here
function MyService.init(): ()
	...
end

-- Called after all init() calls complete
-- Safe to call other services here
function MyService.start(): ()
	...
end

return MyService
```

### 11.2 No Circular Dependencies

Design your dependency graph before writing code for any new system. If two modules depend on each other, extract shared logic into a third.

---

## 13. Quick Reference

| Rule                  | Short version                                                         |
| --------------------- | --------------------------------------------------------------------- |
| Indentation           | Tabs, displayed at 8 spaces                                           |
| Line length           | Soft 100, hard 120 chars                                              |
| Semicolons            | Never                                                                 |
| Variables & functions | `camelCase`; functions always start with a verb                       |
| Types & module tables | `PascalCase`                                                          |
| Constants             | `SCREAMING_SNAKE`                                                     |
| Private module vars   | `_camelCase` prefix                                                   |
| File names            | `PascalCase`; match the module table name                             |
| Script suffixes       | `.server.luau` / `.client.luau` / `.luau`                             |
| File header           | `--!strict` + one-line description comment                            |
| Type annotations      | Every parameter, return, and non-trivial local                        |
| `any`                 | Avoid; cast to known type immediately; comment why                    |
| Module layout         | Services → Requires → Constants → Types → Private → Public → `return` |
| Event handlers        | Prefix `on`, keep thin, delegate to named functions                   |
| Comments              | Explain WHY not WHAT                                                  |
| Error handling        | Promises for async; `assert` for sync preconditions                   |
| Remotes               | Blink only; no raw `RemoteEvent`; `PascalCase` verb+noun              |
| Server trust          | Blink handles types; you validate business logic                      |
| Lifecycle             | `init()` for setup; `start()` for cross-module calls                  |
| Dependencies          | No cycles; follow the layer hierarchy                                 |
