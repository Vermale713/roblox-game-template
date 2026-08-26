# Roblox Game Template

A Roblox game starter built around Argon, Blink, ProfileStore, Charm, Vide, and Vow,
with a service/controller lifecycle, CharmSync data replication, a combat and
status-effect system, a Conch dev console, and an Iris debug overlay.

## Setup

Install [Just](https://github.com/casey/just) and [LPM](https://luaupm.com/docs), then install the project's pinned dependencies and tools:

```sh
lpm install --locked
```

This installs the Luau packages *and* the pinned toolchain declared in `lpm.toml`
(`blink`, `argon`, `larvae`, `luau-lsp`) — there is no separate toolchain step.

Start the development loop, which watches Blink networking and the Argon project:

```sh
just dev
```

## Commands

```sh
just format        # format handwritten Luau (larvae fmt)
just format-check  # check formatting without writing
just lint          # lint handwritten Luau (larvae lint)
just network       # generate Blink networking modules
just build         # generate networking and build out/Game.rbxl
just check         # check formatting, lint, generate networking, and build
```

Individual watchers, if you'd rather not run the whole `just dev` loop:

```sh
just blink         # watch src/Network.blink and regenerate on change
just process       # watch src/ and rewrite requires into dist/
just sourcemap     # watch and write sourcemap.json (powers luau-lsp)
just serve         # argon serve, for syncing into Studio
```

Formatting and linting are both `larvae`, configured in `larvae.toml`. It also serves
those to an editor over stdio with `larvae lsp`, alongside `luau-lsp` for types.

There is also `just sync`, which merges upstream template changes. It expects a git
remote named `template`, which you add yourself:

```sh
git remote add template <template-repo-url>
```

This template intentionally does not include an automated test suite. Run `just check` before committing and use the smoke test below for runtime changes.

## Manual smoke test

Open the generated place or connect Studio with `just dev`, then verify the areas affected by your change:

- Join and leave with player data loading and saving successfully.
- Spawn, die, and respawn without duplicate characters or runtime errors.
- Change player data on the server and confirm the client receives it.
- Confirm guests cannot run privileged Conch commands and configured admins can.
- Open the main UI at common desktop and mobile viewport sizes.
- Trigger reliable, unreliable, sustained, and stopped VFX.
- Process a developer-product receipt twice and confirm its reward is granted once.
- Toggle the Iris debug overlay with `F3` in Studio, or as a UserId listed in `src/Shared/Data/Admins/AdminUserIds.luau`.
- Apply a `PersistOnDeath` status effect, then die and rejoin, and confirm it is restored with the remaining duration.

## Structure

- `src/Server` maps to `ServerScriptService`.
- `src/Shared` maps to `ReplicatedStorage`.
- `src/Client` maps to `ReplicatedStorage.Client`.
- `packages/roblox` maps to `ReplicatedStorage.Packages`.
- `packages/server` maps to `ServerScriptService.ServerPackages`.

See `CLAUDE.md` for the detailed architecture and coding conventions.
