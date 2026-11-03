# Music (#54)

One looping track per place, read by `scripts/music.gd` (any of .ogg, .mp3 or .wav; WAVs loop through their import settings and are compressed to QOA on export):

| File | Plays |
|---|---|
| `title.ogg` | Title screen |
| `cave.ogg` | Exploring the cave (floors 1–3, and the opening) |
| `fortress.wav` | The goblin fortress (floor 4) |
| `combat.wav` | Any fight |
| `camp.wav` | The relief camp |

A missing file means silence for that place. The owner chose free-licensed tracks (2026-10-18).

Floors 5/6 now select the separate original 72s candidate **Below the Sluice** in
`audio/galleries-v1/below-the-sluice.wav` (#167/#54, live since 2026-11-01). It is an
original offline composition (seed 16754; additive/modal synthesis) with no sampled
music or third-party performance, so no external track attribution is required. Its
source recipe is `tools/audio/build_galleries_audio.py`; its exact catalogue and
provenance are `audio/galleries-v1/catalog.json` and `CREDITS.md`. It awaits owner
listening review; the five approved tracks above and their licences are unchanged.
Combined listening hub: `art/concepts/field-audio-v1/inspector.html`.

## Licences

Record every track here before committing it: title, artist, source URL, licence (CC0 or CC-BY) and the attribution text to credit.

| File | Track | Artist | Source | Licence | Credit |
|---|---|---|---|---|---|
| `title.ogg` | The Rising Tide | HitCtrl | https://opengameart.org/node/113828 | CC-BY 3.0 | "The Rising Tide" by HitCtrl, CC-BY 3.0 (https://creativecommons.org/licenses/by/3.0/) — shown in Settings |
| `cave.ogg` | Dark Cavern Ambient (002, loop) | Paul Wortmann | https://opengameart.org/content/dark-cavern-ambient | CC0 | none required |
| `fortress.wav` | Horde War Drums loop | William Hector | https://opengameart.org/node/176112 | CC0 | none required |
| `combat.wav` | For the Black Lord (loop) | Ronhul Maggot | https://opengameart.org/node/141359 | CC-BY 4.0 | "For the Black Lord" by Ronhul Maggot, CC-BY 4.0 (https://creativecommons.org/licenses/by/4.0/) — shown in Settings |
| `camp.wav` | Medieval: The Bard's Tale (loop) | RandomMind | https://opengameart.org/content/medieval-the-bards-tale | CC0 | none required |

Downloaded 2026-10-18 from OpenGameArt; licences checked on each page that day. Files are unmodified apart from renaming. Owner approved the shortlist the same day, then chose The Rising Tide for the title (replacing Vampire's Piano).
