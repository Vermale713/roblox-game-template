[parallel]
dev: rogen process sourcemap serve

process:
    larvae process -w

rogen:
    rogen watch

sourcemap:
    rojo sourcemap default.project.json -o sourcemap.json --watch

serve:
    rojo serve .larvae/build.project.json
