# Navigation interface studies

Two interactive design alternatives for #37, documented in [the navigation guide](../../../../docs/navigation-interface-design.md). Current live game menus are unchanged.

| Proposal | Exploration | Pack |
| --- | --- | --- |
| Field kit | [Exploration](kit-exploration.png) | [Pack](kit-pack.png) |
| Field journal | [Exploration](journal-exploration.png) | [Pack](journal-pack.png) |

The interactive version is supplied in the owner's navigation-design chat. These stills preserve the overall layouts, material hierarchy and controls for Claude's handoff. They are browser-rendered UI studies, not game screenshots or finished texture assets. Buttons, text and navigation in the interactive study are real inspectable elements; the cave behind them is a captured game backdrop.

Reused project art:

- `cave-backdrop.png`: Godot 4.7.2 Mobile capture of the existing debug cave, seed 37, party at (7,1), all CanvasLayer UI hidden. Its environment is real project art; capture is background-only, not a new cave texture.
- Mara: `art/concepts/portraits/mara-layered-v1/preview.png`; current baked lighting retained, migration is #36.
- Map: `art/concepts/map/hero-map-v1.png`, a prior illustrative drawing, not the captured cave's accurate map.
- Item pictures: the three `art/items/pack-64-v1` icons.

No new AI-generated art or image prompts in this task. Code-authored interface layout and browser captures reuse the above art, with compressed copies only inside the in-chat preview. This folder is excluded from Godot import with `.gdignore`.

[validation.json](validation.json) records interaction/layout checks at four review widths for both alternatives. The checks cover item selection/action cancellation, Map/Party/Menu/Controls, Back/Escape/focus restoration, variant switching, script errors and overflow in visited screens. No physical phone, controller, game performance or live Godot menu integration is claimed. Style controls in the chat can adjust the active accent and frame wear without deciding a production theme.
