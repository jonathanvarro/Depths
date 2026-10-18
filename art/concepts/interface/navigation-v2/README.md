# Simplified exploration HUD (#62)

Backpack just right of the portraits; Settings gear near the map; a compact lantern/torch indicator with visible remaining fuel/life. [Design and integration guide](../../../../docs/exploration-hud-design.md).

- `source.fragment.html`: exploration, light meter, settings/controls/map and the outer navigation controller.
- `hero-panels.fragment.html`: locally adapted copy of the accepted #61 Pack/Equipment/Status source, connected through local panel events. The earlier study is preserved.
- `navigation-hud.html`: review fragment with embedded art/fonts, expecting the supplied Lucide/Tweak helpers where available.
- `assets/cave.jpg`, `assets/map.jpg`: compressed copies of existing project art.
- `assets/{backpack,settings,forward,back,turn-left,turn-right}.svg`: 32px exports from the provided Lucide runtime; parchment stroke `#e6dac1`, width 1.75. Keep `LUCIDE-LICENSE.txt` with them. The checker regenerates these from the rendered library icons; no SVG paths were drawn by hand.
- `manifest.json`: sources/hashes, including reused #61 art/fonts. Font OFL notices are embedded; original WOFF assets/notices remain in #61's assets folder.
- `*-hud.png`, `*-pack.png`, `*-oil-*.png`, `*-torch-*.png`, `desktop-settings.png`: review captures.
- `validation.json`: 419 passing browser assertions, no runtime errors.

Rebuild with `tools/art/build_navigation_hud_study.py`, optionally passing `--inline-path` for the thread's durable review. Wrap using the visualization skill's `scripts/render.py` and pass that wrapper to `tools/art/check_navigation_hud_study.cjs` (Node, Playwright and Chrome). It renders/captures five viewport shapes and exports the Lucide SVGs.

The frame is 570px tall in landscape reviews, with additional side/home-bar spacing in the wide phone case. The 320px review stacks controls; landscape-only gameplay remains unchanged. No physical phone or real dungeon movement is simulated. The source-aware indicator should bind to the actual light source on integration; the exhausted-torch comparison intentionally does not auto-fallback to a carried lantern. Live game scripts remain untouched. `.gdignore` isolates this design study from runtime resource imports.
