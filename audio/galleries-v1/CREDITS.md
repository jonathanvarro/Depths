# Galleries foley and music (#167 / #54)

Ten designed effects/ambience assets, and **Below the Sluice**, an original
72-second deeper-cave music loop. Built offline for Depths on 2026-11-01.
No external audio-generation service or cloned voice was used.

| Source | Creator | Licence / retained evidence |
|---|---|---|
| [40 CC0 water / splash / slime SFX](https://opengameart.org/content/40-cc0-water-splash-slime-sfx) | rubberduck | CC0 1.0; original ZIP and captured primary page in `art/source/audio-galleries-v1` |
| [Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0 1.0; original ZIP/licence in `art/source/audio-dark-v1` |
| [RPG Audio](https://kenney.nl/assets/rpg-audio) | Kenney | CC0 1.0; original ZIP/licence in the same earlier source set |
| [Insect or alien scream](https://opengameart.org/content/insect-or-alien-scream) | qubodup | CC0 1.0; recorded balloon friction, source/evidence in the earlier set |
| [Mild Wind Background Noise](https://opengameart.org/content/mild-wind-background-noise) | Bashar3A | CC0 1.0; source/evidence in the earlier set |

[CC0 deed](https://creativecommons.org/publicdomain/zero/1.0/). Credits retained
although attribution is not required. The water pack includes authored sound
effects: these outputs are layered designs, not claimed to be new field
recordings. Source formats include lossy Ogg; PCM output is not a claim of
lossless original provenance.

`catalog.json` lists exact source members, pitch/filter/layer recipes, source
and output hashes, durations and measured levels. The source manifest verifies
every input before rebuilding. Effects are mono 44.1kHz PCM16, at least 6dB
headroom, faded zero endpoints. Ambience is a joined 24-second loop.

**Below the Sluice:** original composition and additive/modal synthesis by
ChatGPT for Depths, not a recording of an instrumental performance. D-centred
three-phrase score: low open fifth, restrained dissonant upper phrases and
sparse decaying struck-string voices. No borrowed melody, music sample or
third-party composer. The full score and exact synthesis are retained in
`tools/audio/build_galleries_audio.py`; no runtime synthesis. Delivered PCM16
with QOA engine compression, joined endpoints; existing approved music remains.
This new score is a first listening candidate, not owner-approved music.

Review: `art/concepts/galleries-audio-v1/inspector.html`. The gallery and audition
reel are excluded from Godot imports. Music follows **Music** volume, water and
warnings follow **Effects**; no automatic playback in the listening gallery.
