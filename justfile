[parallel]
dev: blink sourcemap serve

blink:
    blink src/Network.blink -w

sourcemap:
    argon sourcemap -o sourcemap.json -w

serve:
    argon serve