# Depths sound auditions · darker second pass

Owner direction: darker, grittier and more serious, especially the club impact. Six original procedural revisions keep the rough material identities while reducing sustained musical resonance and clean, cartoon-like impact tones. The first set and all current game audio remain intact.

**Start with `club-comparison.wav`:** original at 0.25s, darker revision at 2.10s. Both clips have equal whole-clip RMS energy; the denser revision is attenuated by 3.781dB in this comparison. This helps compare texture without simply making the new one louder, though it is not a perceptual loudness calibration. The standalone revision retains its normal -6dBFS peak cap.

**`audition.wav` contains all six revisions** at the same timings as v1:

| Start | File | Length | Change |
| --- | --- | --- | --- |
| 0.25s | `heartbeat.wav` | 0.78s | Broad, muffled pressure and skin contact; removes the pitched drum-like glide. |
| 1.68s | `club-hit.wav` | 1.05s | Dense irregular thud, crushed cloth, abrupt wooden contact and short dark reflections; no sustained pitched impact body. |
| 3.38s | `shield-block.wav` | 1.20s | Strained timber, hard contact and dull short iron-fitting chatter. |
| 5.23s | `coin-pouch.wav` | 1.85s | Worn coins damped against rough leather, with shorter and less sparkling rings. |
| 7.73s | `chest-open.wav` | 2.65s | Heavy latch, abrasive hinge friction and dull lid; quieter tonal creak. |
| 11.03s | `torch-light.wav` | 3.50s | Coarse flint and irregular low crackle, with less airy hiss or periodic flutter. |

The club and shield are rebuilt mainly from filtered irregular contact noise rather than a set of ringing sine tones. No voices, gore, music or new combat rules are implied. These remain synthesized audition effects, not recorded foley or audio from a generative service. The sound direction still needs a listening judgement on headphones and phone speakers.

Eight lossless mono 44.1kHz PCM16 WAVs are supplied: six effects, the 15.18s reel and the 3.55s A/B comparison. Each has headroom, zero endpoints and no loop flag. `manifest.json` records the fixed seeds, peak/RMS levels, hashes, timings and comparison gains. Source is [`generate_sfx_dark.py`](../../tools/audio/generate_sfx_dark.py), which reuses synthesis primitives from [`generate_sfx_samples.py`](../../tools/audio/generate_sfx_samples.py). Rebuild with Python/NumPy; v1 is read only for the comparison and is never regenerated or overwritten.

Checks: deterministic WAV hashes on a second build, exact effect PCM segments in the reel, v1 hashes preserved, clipping/endpoint/format checks, and Godot 4.7.2 decoding of all eight resources with the correct rate, duration, mono PCM16 format and disabled looping. Technical checks do not confirm subjective quality. No live integration or physical-phone listening has been performed. #54/#96 sound replacement checkboxes remain unfinished; coin pouch is separate from the timed coin flip, and torch lighting is separate from a loop and burnout.
