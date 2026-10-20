"""Softer footsteps (owner request, 2026-10-20): a muffled heel-toe scuff
of a boot on gritty stone, replacing the harder placeholder steps in
audio/placeholder/footstep_1-3.wav. Same filenames, so the themes and
main.gd pick them up unchanged.

Pure Python (no numpy): wave + math + random, fixed seed, so every run
gives identical files. Mono 44.1 kHz PCM16, peaks near -12 dBFS, silent
first and last samples, no sharp click.

    python tools/audio/generate_soft_footsteps.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
PEAK = 0.25  # about -12 dBFS
OUT = Path(__file__).resolve().parents[2] / "audio" / "placeholder"


def lowpass(x, cutoff):
    a = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    y = 0.0
    out = []
    for s in x:
        y += a * (s - y)
        out.append(y)
    return out


def envelope(n, attack, length):
    """Smooth rise over `attack` seconds, then an exponential fall."""
    out = []
    for i in range(n):
        t = i / RATE
        rise = 0.5 - 0.5 * math.cos(math.pi * min(1.0, t / attack)) if attack > 0 else 1.0
        out.append(rise * math.exp(-t / length))
    return out


def contact(rng, n, cutoff, attack, length, thump_hz, thump_gain):
    """One part of the foot meeting stone: soft filtered noise plus a low,
    quickly fading body thump."""
    raw = [rng.uniform(-1.0, 1.0) for _ in range(n)]
    soft = lowpass(lowpass(raw, cutoff), cutoff * 1.4)  # two passes: muffled
    env = envelope(n, attack, length)
    thump_env = envelope(n, attack * 1.5, length * 1.3)
    phase = rng.uniform(0, math.tau)
    return [soft[i] * env[i] * 2.6 + math.sin(phase + math.tau * thump_hz * i / RATE) * thump_env[i] * thump_gain
            for i in range(n)]


def grit(rng, n, density, gain):
    """A few faint grains of grit crunching under the sole."""
    out = [0.0] * n
    for _ in range(int(density * n / RATE)):
        at = rng.randrange(0, max(1, n - 400))
        size = rng.randint(80, 260)
        level = rng.uniform(0.3, 1.0) * gain
        for i in range(size):
            out[at + i] += rng.uniform(-1.0, 1.0) * level * math.exp(-i / (size * 0.3))
    return lowpass(out, 2600)


def footstep(variant):
    rng = random.Random(9100 + variant * 31)
    length = int(rng.uniform(0.27, 0.33) * RATE)
    sound = [0.0] * length
    heel_at = int(0.004 * RATE)
    toe_at = heel_at + int(rng.uniform(0.065, 0.095) * RATE)
    heel = contact(rng, int(0.16 * RATE), rng.uniform(520, 700), 0.006, 0.028, rng.uniform(72, 92), 0.55)
    toe = contact(rng, int(0.13 * RATE), rng.uniform(650, 850), 0.005, 0.022, rng.uniform(95, 120), 0.3)
    for i, s in enumerate(heel):
        if heel_at + i < length:
            sound[heel_at + i] += s
    for i, s in enumerate(toe):
        if toe_at + i < length:
            sound[toe_at + i] += s * 0.7
    # A short scuff as the weight rolls forward, and a little grit.
    scuff_env = envelope(length - heel_at, 0.03, 0.06)
    scuff = lowpass(lowpass([rng.uniform(-1.0, 1.0) for _ in range(length - heel_at)], 1100), 1500)
    crunch = grit(rng, length - heel_at, rng.uniform(18, 30), 0.05)
    for i in range(length - heel_at):
        sound[heel_at + i] += scuff[i] * scuff_env[i] * 0.9 + crunch[i] * scuff_env[i] * 1.6
    # Fade the last 15 ms so it ends in silence.
    fade = int(0.015 * RATE)
    for i in range(fade):
        sound[length - fade + i] *= 1.0 - i / fade
    sound[0] = 0.0
    sound[-1] = 0.0
    return sound


def write(name, samples):
    loudest = max(1e-9, max(abs(s) for s in samples))
    scale = PEAK / loudest
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(frames)
    print(f"{name}: {len(samples) / RATE:.2f}s, peak {20 * math.log10(PEAK):.1f} dBFS")


if __name__ == "__main__":
    for v in range(3):
        write(f"footstep_{v + 1}.wav", footstep(v))
