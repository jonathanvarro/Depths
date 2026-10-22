# Dark foley and ambience · Depths

Thirty edited game effects and looping layers, delivered for #96/#99.
These combine licensed CC0 foley/material recordings with original project
sound-design layers. They are not AI audio generation or newly recorded
performances by this assistant. Web spit/venom include original synthesized
wet/air layers; the drum body is designed from material impacts. No actor's
voice was cloned.

| Source and creator | Used for | Licence |
|---|---|---|
| [Impact Sounds — Kenney](https://kenney.nl/assets/impact-sounds) | Contact, shields, falls, gate timber/iron, drum body | CC0 1.0 |
| [RPG Audio — Kenney](https://kenney.nl/assets/rpg-audio) | Cloth, weapon air, coins, latch, hinge, flint-like click, UI | CC0 1.0 |
| [Fire Crackling — AntumDeluge](https://opengameart.org/content/fire-crackling/) | Fire/torch material | CC0 1.0 |
| [Mild Wind Background Noise — Bashar3A](https://opengameart.org/content/mild-wind-background-noise) | Wind around tents | CC0 1.0 |
| [Crowd Shouting/Speaking Ambience — StarNinjas](https://opengameart.org/content/crowd-shoutingspeaking-ambience) | Lowered, filtered distant camp murmur | CC0 1.0 |
| [Insect or alien scream — qubodup](https://opengameart.org/content/insect-or-alien-scream) | Lowered/filtered queen screech, recorded balloon-friction source | CC0 1.0 |
| [Heartbeat (single sound) — Independent.nu, submitted by qubodup](https://opengameart.org/content/heartbeat-single-sound) | One short lub-dub | CC0 1.0 |

[CC0 deed](https://creativecommons.org/publicdomain/zero/1.0/) ·
[CC0 legal text](https://creativecommons.org/publicdomain/zero/1.0/legalcode)

Credits are retained even though these sources do not require attribution.
The original downloads, SHA-256 hashes, exact archive members and captured
licence evidence are under `art/source/audio-dark-v1`; the two Kenney licences
are retained verbatim. `sources.json` records the primary pages/download URLs.
The existing project-authored cave bed is reused beneath the outskirts drums.
No music, paid library, non-commercial or share-alike recording is included.

## Format and editing

Runtime: mono 44.1kHz signed PCM16 WAV, uncompressed imports. One-shots have
faded zero endpoints and at least 6dB peak headroom; UI and camp murmur are
quieter. Loops have joined endpoints and explicit forward-loop import flags.
Original source formats include Vorbis and a FLAC file whose original filename
mentions MP3; the final WAV container does not imply lossless source provenance.

`catalog.json` records each asset's source members, derived layers, duration,
peak/RMS, output hash and intended use. The build script applies down-pitch,
filtering, layering, restrained saturation-free gain and short reflections.
There is no runtime synthesis. `tools/audio/build_dark_sound_library.py`
rebuilds offline with NumPy and soundfile; dependencies can be installed into
the ignored `build/audio-deps` directory. Earlier auditions and placeholders
are preserved.

## Review and scope

[Listening gallery](../../art/concepts/sound-v1/inspector.html) ·
[Complete audition reel](../../art/concepts/sound-v1/audition.wav) ·
[Integration and validation](../../docs/elves-and-sound-art.md)

Play at a comfortable level. The reel has brief gaps; loop extracts last four
seconds. Separate fire/wind/voice stems and the held-torch loop are supplied for
future mixing; the live camp uses the combined bed. Current music and the
owner's deliberately softened footsteps remain unchanged. #54's broader music
and movement-recording work is outside this delivery. Actual phone-speaker
listening and the owner's judgement still matter for final mix approval.
