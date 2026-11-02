[parallel]
dev: write process sourcemap serve

# serve:
#     rogen serve

serve:
    rojo serve .larvae/build.project.json

write:
    rogen write --watch

sourcemap:
    rojo sourcemap default.project.json -o sourcemap.json --watch

process:
    larvae process -w
