# Pack design preview (#39)

Open `preview.tscn` in Godot and press F6. This is an isolated, interactive design preview using a disposable party and the existing supply rules. It does not replace the live Pack.

- `pack_view.gd`: layout, selection, actual item effects/costs and unavailable states.
- `preview_host.gd`: sample setup, background and return/reopen behaviour.
- `desktop-*.png`, `phone-*.png`: Godot captures of four items and a post-use state.
- `clean-dressing.png`: 64×64 export of the approved starter dressing; preview fallback only, not assigned to the live item.
- `manifest.json`: source/export provenance and hashes.
- `validation.json`: results from `tools/art/check_pack_design.gd` (1087 assertions, zero failures at three viewport sizes).

See [the design guide](../../../docs/pack-screen-design.md) for rules, fonts, limitations and integration handoff. Simulated phone only; Mara still uses existing baked-lit artwork (#36).
