# Pack / hero window study (#61)

The owner requested image-only Pack slots with hover/touch details, plus a hero Equipment/Status window. Equipment opens by default; portraits switch heroes. [Design guide and implementation boundary](../../../../docs/pack-and-hero-window-design.md).

- `source.fragment.html`: editable layout, styles and interactions, with asset placeholders.
- `pack-heroes.html`: self-contained interactive fragment for the design review; no network resources.
- `assets/`: small exports of existing item/portrait art, a compressed backdrop, and WOFF-compressed project fonts with their OFL notices.
- `manifest.json`: sources, output hashes and conversion details.
- `desktop-*.png`, `phone-*.png`, `compact-*.png`, `narrow-*.png`: Equipment, Status, Pack and pinned item detail at four review widths.
- `validation.json`: 146 passing browser assertions; no runtime errors.

Rebuild with `tools/art/build_pack_hero_study.py`; optionally pass `--inline-path` pointing to the thread's durable review HTML. For browser checks, wrap the fragment with the visualization skill's `scripts/render.py`, then pass that wrapper's absolute path to `tools/art/check_pack_hero_study.cjs` (requires Node, Playwright and Chrome).

The study uses the already accepted fonts. WOFF conversion only compresses the original SFNT tables: glyphs, names, metrics and variation axes are unchanged. Both font notices are included in the fragment and alongside the font assets. The original TTF files in `art/fonts` are untouched. No image generation was needed; the image exports use existing approved art and retain source transparency.

Twelve bag cells and six equipment regions are layout proposals, not capacity/equipment rules. Hero II/III are examples with placeholders, not actual recruits. Demonstration gear is not a start-inventory grant. Use/equip actions change local review state only; lantern/health readouts are sample values. The live Godot interface is unchanged, and Mara's lighting work remains #36. `.gdignore` keeps this browser study separate from game resources.
