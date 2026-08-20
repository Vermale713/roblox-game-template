[parallel]
dev: blink sourcemap serve

format:
    stylua src

format-check:
    stylua --check src

lint:
    selene src

network:
    blink src/Network.blink -y

build: network
    mkdir -p out
    argon build default.project.json -o out/Game.rbxl -y

check: format-check lint build

blink:
    blink src/Network.blink -w

sourcemap:
    argon sourcemap -o sourcemap.json -w

serve:
    argon serve

sync:
    git diff --quiet && git diff --cached --quiet || git stash && \
    git fetch template && \
    git merge template/main && \
    git stash list | grep -q "stash@{0}" && git stash pop
