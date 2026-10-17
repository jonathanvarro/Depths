# Typography proposal — title study #38

Two bundled, unmodified variable-font files provide the actual lettering used in the title study. These are reusable Godot resources, not lettering painted by the image generator. This proposal does not change the project's default font or existing menus.

| Role | Resource | Face / weight | Treatment |
| --- | --- | --- | --- |
| Large title | `res://art/fonts/title-cinzel.tres` | Cinzel 600 | 5px extra glyph spacing in the large title only |
| Page/section heading | `res://art/fonts/heading-cinzel.tres` | Cinzel 600 | Normal spacing; short labels rather than body paragraphs |
| Reading text | `res://art/fonts/body-source-sans.tres` | Source Sans 3 400 | Sentence case, no added tracking |
| Actions/status emphasis | `res://art/fonts/action-source-sans.tres` | Source Sans 3 600 | Clear labels, names and numbers |

See [the rendered specimen](../title/title-v1/title-specimen.png) and [design guide](../../docs/title-screen-and-typography.md). Use these resources in a shared Godot Theme after owner review. Do not spread ad-hoc system-font fallbacks through the UI. The FontVariation resources use the numeric OpenType `wght` tag (2003265652) so the requested weights render correctly in this Godot version.

## Source and licence

- **Cinzel**, Natanael Gama / The Cinzel Project Authors: [Google Fonts distribution](https://github.com/google/fonts/tree/main/ofl/cinzel), [upstream project](https://github.com/NDISCOVER/Cinzel). Distributed file `Cinzel[wght].ttf`, saved locally as `cinzel/Cinzel-Variable.ttf`; font bytes unchanged. Accompanying notice/licence: [cinzel/OFL.txt](cinzel/OFL.txt).
- **Source Sans 3**, Paul D. Hunt / Adobe: [Google Fonts distribution](https://github.com/google/fonts/tree/main/ofl/sourcesans3), [upstream project](https://github.com/adobe-fonts/source-sans). Distributed file `SourceSans3[wght].ttf`, saved locally as `source-sans-3/SourceSans3-Variable.ttf`; font bytes unchanged. Accompanying notice/licence: [source-sans-3/OFL.txt](source-sans-3/OFL.txt).

Both files are supplied under SIL Open Font License 1.1; keep the accompanying copyright/licence files with redistributed fonts. The notices above identify the font authors, not contributors to the game. No font-outline editing or conversion was performed. [manifest.json](manifest.json) records download URLs, date, sizes and SHA-256 hashes.

The built-in image tool generated only the background scene. It did not invent the fonts or generate a new font file. This pair remains a recommendation until the owner reviews title and phone-size examples; it is not an approved release logo or a finished multilingual type system.
