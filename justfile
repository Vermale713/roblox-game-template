[parallel]
dev: blink process sourcemap serve

format:
    larvae fmt

format-check:
    larvae fmt --check

lint:
    larvae lint

network:
    blink src/Network.blink -y

check: format-check lint

blink:
    blink dist/Network.blink -w

process:
    larvae process -w

sourcemap:
    argon sourcemap .larvae/build.project.json -o sourcemap.json -w

serve:
    argon serve .larvae/build.project.json

sync:
    git diff --quiet && git diff --cached --quiet || git stash && \
    git fetch template && \
    git merge template/main && \
    git stash list | grep -q "stash@{0}" && git stash pop
