# Field audio · #217

46 mono effects/ambience assets, designed offline for Depths, 2026-11-03.
These are edited CC0 material recordings and original procedural sound-design
layers. They are not newly recorded field performances, real animal cries,
spoken prayers or an external audio-generation service. No voice was cloned.

| Source | Creator | Licence / retained evidence |
|---|---|---|
| [Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0 1.0; exact ZIP, License.txt and hashes in `art/source/audio-dark-v1` |
| [RPG Audio](https://kenney.nl/assets/rpg-audio) | Kenney | CC0 1.0; exact ZIP, License.txt and hashes in `art/source/audio-dark-v1` |
| [Mild Wind Background Noise](https://opengameart.org/content/mild-wind-background-noise) | Bashar3A | CC0 1.0; original WAV, captured primary page and hashes in `art/source/audio-dark-v1` |
| [Insect or alien scream](https://opengameart.org/content/insect-or-alien-scream) | qubodup | CC0 1.0; recorded balloon-friction source, original FLAC/page/hash in `art/source/audio-dark-v1` |
| [40 CC0 water / splash / slime SFX](https://opengameart.org/content/40-cc0-water-splash-slime-sfx) | rubberduck | CC0 1.0; original ZIP, captured primary page and hash in `art/source/audio-galleries-v1` |

The primary source metadata, original licence evidence and archive members are
retained. `catalog.json` identifies exact members and processing for each output.
Prayers, warning/progress resonances and noise layers are original offline
modal/additive/noise synthesis (seed 21703). Creature reactions are explicitly
material-based designs; goblins/deep creatures are not imitations of an actor.

[CC0 deed](https://creativecommons.org/publicdomain/zero/1.0/) ·
[CC0 legal text](https://creativecommons.org/publicdomain/zero/1.0/legalcode)

## Delivery and level policy

Mono 44.1kHz PCM16 WAV. Effects have zero faded endpoints; four 40s ambience
loops use cyclic source crossfades and joined endpoints. At least 6dB headroom
is retained; most effects peak below -8dBFS. Steps are intentionally quieter
(ceiling -17dBFS, RMS target about -32dBFS). Do not normalize them on import.
All assets target Effects; the separately retained `Below the Sluice` score
targets Music. Do not alter the approved music, existing levels or gameplay
timing merely to connect these assets.

Rebuild with `tools/audio/build_field_audio.py` (NumPy/soundfile), then import
with Godot 4.7.2 and use `prepare_audio_asset_check.py --configure-imports` for
explicit loop/compression settings. No runtime synthesis is used. The listening
page and compact sampler are `art/concepts/field-audio-v1`; final owner/headphone/
physical-phone judgement and Claude's live hookup remain separate.
