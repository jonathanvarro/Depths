# Depths sound auditions · v1

Six original synthesized effects for the owner to hear, supporting #54/#96. These are designed from resonant tones, filtered noise and irregular material transients. They are procedural samples, not recorded foley or output from an AI sound-generation service. No third-party recordings or external assets are used.

**Listen to `audition.wav`** for all six, separated by short silences. The effects are intended to feel close, rough and understated, without a musical reward sting.

| Start in reel | File | Length | Direction |
| --- | --- | --- | --- |
| 0.25s | `heartbeat.wav` | 0.78s | One muffled lub-dub; a repeated gameplay cue would control its own timing. |
| 1.68s | `club-hit.wav` | 1.05s | Short movement, dull heavy impact and a little cloth/crunch. |
| 3.38s | `shield-block.wav` | 1.20s | Wooden body with small iron fittings rattling. |
| 5.23s | `coin-pouch.wav` | 1.85s | A few coins settling against leather; payment or small treasure, not the coin-flip animation. |
| 7.73s | `chest-open.wav` | 2.65s | Latch, rough hinge, lid settling. |
| 11.03s | `torch-light.wav` | 3.50s | Scratch, flame catching, short crackling burn fading out. |

All files are mono 44.1kHz, 16-bit PCM WAVs with lossless imports and no loop flag. Peak levels have headroom (-6 to -10 dBFS); endpoints are zero, with short fades to prevent boundary clicks. The audition reel preserves the individual sample levels. These checks confirm the files, not subjective sound quality; listen on headphones and the target phone before selecting or mixing them.

The existing game audio, references, buses and playback volumes are unchanged. None of the #96 sound replacement boxes should be marked complete from this audition alone. In particular, `coin-pouch.wav` is not a replacement for the timed flip/flick/landing sound, and `torch-light.wav` is neither a seamless burning loop nor a burnout effect. Camp ambience, voices, web/venom, miss/stumble/UI cues and other variations remain separate work.

Source: [`tools/audio/generate_sfx_samples.py`](../../tools/audio/generate_sfx_samples.py), requiring Python and NumPy. Rebuilding is deterministic for the recorded NumPy version and seeds. `manifest.json` records each seed, description, duration, PCM checks, measured levels and SHA-256. Seven WAVs (six effects plus reel) also pass Godot 4.7.2 import and decoded-resource checks for mono PCM16, rate, duration and disabled looping. No live integration or physical-device listening has been performed.

Suggested next step: select useful timbres after listening, refine them and create several variations for repeated actions; only then replace the appropriate live placeholders under #54/#96.
