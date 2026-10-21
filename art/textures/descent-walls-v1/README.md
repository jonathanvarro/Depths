# Descent wall library · #126

Six standalone 128px/32-colour wall PNGs and reusable Godot materials. [Catalogue](catalog.json) lists exact source/texture hashes and material paths. [Overview](../../concepts/descent-walls-v1/wall-families.png) · [full handoff](../../../docs/descent-wall-library.md).

- `worked-cave.tres`: fractured worked rock.
- `goblin-hold.tres`: patched rough masonry.
- `drowned-masonry.tres`: damp mineral-stained slate.
- `fungal-stone.tres`: subdued moss/fungal crust over old stone.
- `buried-city.tres`: dressed limestone and plaster remnants.
- `sealed-temple.tres`: large recessed basalt courses.

Each `.tres` references its same-named opaque PNG, with nearest repeat sampling and roughness 1. No normal maps, glow or custom shader. Existing themes are untouched: assign the desired material to a future theme's wall and variant-wall slots when integrating it. [Matching floor/ceiling materials](../descent-surfaces-v1/README.md) and separate dressing are now delivered in #139; structural variants/transitions remain separate work.

Built-in ImageGen masters/prompts are preserved in [source](../../source/cave-walls-v1/README.md). Rebuild with `tools/art/build_descent_walls.py`; test with `tools/art/check_descent_walls.gd` in Godot 4.7.2. Opposite edge pixels match after a small wrap-apron correction; see repeated sheets for geometric joins and recurring motifs.
