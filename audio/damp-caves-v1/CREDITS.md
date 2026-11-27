# Damp Caves sound library — #302 H/I

Twenty new mono 44.1kHz PCM16 WAVs: one 48s ambience loop, four wet steps,
puddle splash, wet wall contact, two passage sounds, three drips and hurt/death
reactions for the Pale Newt, Blind Crawler, Leech Swarm and Drowned Mother.

Retained verified **CC0-1.0** sources:

| Creator | Recording / pack | Retained source |
| --- | --- | --- |
| Kenney | [Impact Sounds](https://kenney.nl/assets/impact-sounds) | `art/source/audio-dark-v1/downloads/kenney-impact.zip` |
| Kenney | [RPG Audio](https://kenney.nl/assets/rpg-audio) | `art/source/audio-dark-v1/downloads/kenney-rpg.zip` |
| rubberduck | [40 water / splash / slime SFX](https://opengameart.org/content/40-cc0-water-splash-slime-sfx) | `art/source/audio-galleries-v1/water-splash-slime-sfx.zip` |
| Bashar3A | [Mild Wind Background Noise](https://opengameart.org/content/mild-wind-background-noise) | `art/source/audio-dark-v1/files/wind.wav` |
| qubodup | [Insect or alien scream](https://opengameart.org/content/insect-or-alien-scream), balloon friction | `art/source/audio-dark-v1/files/insect-scream.flac` |

The full `catalog.json` records each archive/recording hash, retained licence
evidence, exact input members, recipe, processing and output hash. Water HTML
was retained with CRLF; Git checks out LF. Validation permits **only** an exact
raw hash or an EOL-normalized equivalent, not changed licence content. All source
archives and recordings remain unchanged. Source alias `queen` is the earlier
library's internal ID for qubodup's balloon-friction recording, not a new actor.

Changes: offline trimming, rate/pitch conversion, band filtering, restrained
mixing, original seeded shaped noise, short reflections, fixed peak/RMS ceilings
and endpoint fades. The ambience uses sparse drips and low distant water/air,
without a musical or tonal bass layer. Creature reactions combine material
sounds and balloon friction; they are neither actor performances nor purported
animal recordings. There is no voice cloning or external speech service.

## Hookup and mix

All files use **Effects**, keeping Music independent. Imports disable normalize,
trim and lossy compression; only `ambience-damp.wav` loops forward. The scene's
existing ambience player gain is −10 dB: retain it once, not twice. Steps have
quiet fixed peaks; keep the current overall player/bus authority. Do not add
water cost, map.water cells, placement RNG or new creature rules from sound IDs.

These are unassigned listening candidates. All 117 earlier audio files,
including approved music and softened footsteps, are preserved byte for byte.
Headphone/physical-phone listening review and final gameplay mix remain.

## Rebuild and review

`tools/audio/build_damp_audio.py --deps E:/GitHub/Depths/build/audio-deps
--workspace E:/GitHub/Depths` uses the bundled Python 3.12 with NumPy/soundfile.
No runtime synthesis. Validate with `tools/audio/validate_damp_audio.py` using
the same arguments. After initial headless import, its `--configure-imports`
sets explicit loop/compression flags; import again. The builder preserves those
flags on later builds.

`tools/audio/check_damp_audio.gd -- <local-output-folder>` checks native WAV
decoding, true playback/seek/finish/loop/stop, Effects/Music separation and total
PCM memory. It mutes Master before playback and never loads owner settings or
Main. Run on the isolated desktop if using an actual audio device.

`tools/damp_caves/package_creatures_audio.py --workspace E:/GitHub/Depths`
packages a local listening desk and model gallery after both validations pass.
Local review: `build/local-damp-audio-v1/inspector.html`; separate short
`audition.wav` is a listening aid, not a live game asset. Nothing autoplays.
