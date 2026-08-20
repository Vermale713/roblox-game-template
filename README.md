# Roblox Game Template

A Roblox game starter built around Argon, Blink, ProfileStore, Charm, Vide, and a service/controller lifecycle.

## Setup

Install [Just](https://github.com/casey/just) and [LPM](https://luaupm.com/docs), then install the project's pinned dependencies and tools:

```sh
lpm install --locked
```

Start the development loop, which watches Blink networking and the Argon project:

```sh
just dev
```

## Commands

```sh
just format        # format handwritten and generated Luau
just lint          # lint handwritten Luau
just network       # generate Blink networking modules
just build         # generate networking and build out/Game.rbxl
just check         # check formatting, lint, generate networking, and build
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

## Structure

- `src/Server` maps to `ServerScriptService`.
- `src/Shared` maps to `ReplicatedStorage`.
- `src/Client` maps to `ReplicatedStorage.Client`.
- `packages/roblox` maps to `ReplicatedStorage.Packages`.
- `packages/server` maps to `ServerScriptService.ServerPackages`.

See `CLAUDE.md` for the detailed architecture and coding conventions.
