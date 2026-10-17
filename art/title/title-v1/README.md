# Title and typography study

For #38. [Desktop](title-desktop.png), [phone](title-phone.png), [type specimen](title-specimen.png). Full direction: [title-screen-and-typography.md](../../../docs/title-screen-and-typography.md).

- `background.png`: original built-in image-generation output, opaque 1672 × 941 RGB, with no lettering. [Exact prompt and source](generation-manifest.json).
- `preview.tscn` / `preview.gd`: optional editable Godot layout; title/menu text uses [bundled font resources](../../fonts/README.md). Buttons intentionally have no game actions. Main scene/default game typography unchanged.
- `title-desktop.png`: 1280 × 720 Godot Mobile capture; `title-phone.png`: 1278 × 590 landscape composition; `title-specimen.png`: 1280 × 720 font-role examples on dark/paper surfaces.
- `tools/art/render_title_study.gd`: rerender with the project's Godot 4.7.2 using `--path` and `--script res://tools/art/render_title_study.gd`; requires the normal renderer. 168 font/glyph/bounds/target checks pass.
- [validation.json](validation.json): source-copy hash, PNG dimensions, font/provenance checks and review status.

Reviewed for title/menu readability and separation from the focal cave/lantern. Phone is a desktop-rendered composition, not real-device verification. The generated high-resolution master is not a final pixel-density/performance decision. Cinzel + Source Sans 3 is a proposal, and Depths is the working title. Preserve this version when iterating.
