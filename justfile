[parallel]
dev: blink sourcemap serve

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

test:
    lune run test
