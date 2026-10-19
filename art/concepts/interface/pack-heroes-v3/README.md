# Physical Pack / Equipment review · #109

Open `pack-heroes.html` in a browser from a full repository checkout. The page references existing sibling/project art and fonts; it makes no network requests and changes only its isolated demonstration state.

[Design and implementation boundary](../../../../docs/physical-pack-and-equipment.md) · [Generation prompts](../../../source/pack-heroes-v3/generation-manifest.json) · [Asset provenance](manifest.json) · [Checks](validation.json)

The shell art is generated; the controls, labels and existing item icons are separate. `physical.css` is editable. Rebuild with `tools/art/build_physical_pack_study.py`, then check with `tools/art/check_physical_pack_study.cjs` using the available Playwright runtime. Neither script changes shipping Godot screens or game data.
