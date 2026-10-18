"""Generates the placeholder sounds in audio/placeholder/.

Everything is synthesised here from noise and sine waves, so the files are
original to this project and carry no third-party licence. They are meant to
be replaced by real recordings later.

Re-run to rebuild (output is identical every run, thanks to the fixed seed):
    python tools/make_placeholder_audio.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "audio" / "placeholder"
rng = random.Random(1234)


def write(name, samples, peak=0.8):
    loudest = max(1e-9, max(abs(s) for s in samples))
    scale = peak / loudest
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(frames)
    print(f"{name}: {len(samples) / RATE:.2f}s")


def seconds(s):
    return int(s * RATE)


def noise(n):
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(x, cutoff):
    a = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    y = 0.0
    out = []
    for s in x:
        y += a * (s - y)
        out.append(y)
    return out


def highpass(x, cutoff):
    return [s - l for s, l in zip(x, lowpass(x, cutoff))]


def decay(i, attack, length):
    """Envelope: linear rise over `attack` seconds, then exponential fall."""
    t = i / RATE
    rise = min(1.0, t / attack) if attack > 0 else 1.0
    return rise * math.exp(-t / length)


def mix_into(target, source, start, gain=1.0):
    for i, s in enumerate(source):
        if 0 <= start + i < len(target):
            target[start + i] += s * gain


def footstep(variant):
    """Boot on gritty stone: a low thump plus a short crunch, then a softer scuff."""
    n = seconds(0.25)
    out = [0.0] * n
    for hit, (delay, gain) in enumerate([(0.0, 1.0), (0.055 + 0.01 * variant, 0.45)]):
        grit = lowpass(highpass(noise(n), 150), 1600 + 350 * variant)
        freq = 72 + 9 * variant
        sound = [grit[i] * decay(i, 0.002, 0.03) + 0.7 * math.sin(2 * math.pi * freq * i / RATE) * decay(i, 0.003, 0.045)
                 for i in range(n)]
        mix_into(out, sound, seconds(delay), gain)
    return out


def bump():
    """Dull thud of a body against rock, with a trickle of grit."""
    n = seconds(0.45)
    out = []
    phase = 0.0
    dust = lowpass(noise(n), 400)
    for i in range(n):
        freq = 95 * math.exp(-i / RATE / 0.08) + 42
        phase += 2 * math.pi * freq / RATE
        out.append(math.sin(phase) * decay(i, 0.004, 0.09) + 0.6 * dust[i] * decay(i, 0.002, 0.06))
    trickle = highpass(noise(n), 2500)
    mix_into(out, [trickle[i] * 0.12 * decay(i, 0.05, 0.12) for i in range(n)], seconds(0.03))
    return out


def web_tear():
    """Sticky strands snapping in quick, irregular bursts."""
    n = seconds(0.6)
    hiss = lowpass(highpass(noise(n), 1800), 7000)
    out = []
    gate = 0.0
    hold = 0
    for i in range(n):
        if hold <= 0:
            gate = 1.0 if rng.random() < 0.55 else 0.15
            hold = seconds(rng.uniform(0.004, 0.018))
        hold -= 1
        t = i / RATE
        shape = min(1.0, t / 0.12) * math.exp(-max(0.0, t - 0.12) / 0.18)
        out.append(hiss[i] * gate * shape)
    for _ in range(5):  # a few individual strands snapping
        snap = [rng.uniform(-1, 1) * decay(i, 0.0, 0.004) for i in range(seconds(0.02))]
        mix_into(out, snap, seconds(rng.uniform(0.05, 0.4)), 0.9)
    return out


def door_creak():
    """Rough, wobbling creak of an old hinge."""
    n = seconds(0.9)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        freq = 170 + 140 * (t / 0.9) + 25 * math.sin(2 * math.pi * 7 * t) + rng.uniform(-15, 15)
        phase += 2 * math.pi * freq / RATE
        saw = 2 * ((phase / (2 * math.pi)) % 1.0) - 1
        roughness = 0.6 + 0.4 * rng.random()
        out.append(saw * roughness * min(1.0, t / 0.05) * min(1.0, (0.9 - t) / 0.15))
    return lowpass(highpass(out, 250), 2500)


def drip(pitch):
    n = seconds(0.06)
    out = []
    phase = 0.0
    for i in range(n):
        phase += 2 * math.pi * pitch * (1 - 0.3 * i / n) / RATE
        out.append(math.sin(phase) * decay(i, 0.001, 0.015))
    return out


def ambience(length, drips, hum):
    """Low rumble that breathes slowly, occasional echoing drips, optional hum.
    The end is crossfaded into the start so it loops without a click."""
    fade = seconds(2.0)
    n = seconds(length)
    total = n + fade
    brown = []
    level = 0.0
    for s in noise(total):
        level = level * 0.995 + s * 0.05  # leaky integration: deep, rumbling noise
        brown.append(level)
    rumble = lowpass(brown, 250)
    out = [rumble[i] * (0.65 + 0.35 * math.sin(2 * math.pi * i / RATE / (length / 2))) for i in range(total)]
    if hum:
        for i in range(total):
            out[i] += 0.04 * math.sin(2 * math.pi * 55 * i / RATE) * (0.7 + 0.3 * math.sin(2 * math.pi * i / RATE / length))
    for _ in range(drips):
        start = seconds(rng.uniform(1.0, length - 2.5))
        sound = drip(rng.uniform(1300, 2300))
        gain = rng.uniform(0.25, 0.5)
        for echo_delay, echo_gain in [(0.0, 1.0), (0.13, 0.35), (0.29, 0.15)]:
            mix_into(out, sound, start + seconds(echo_delay), gain * echo_gain)
    looped = out[:n]
    for i in range(fade):
        w = i / fade
        looped[i] = out[i] * w + out[n + i] * (1 - w)
    return looped


def heartbeat():
    """One heartbeat: a deep "lub" then a softer "dub"."""
    n = seconds(0.5)
    out = [0.0] * n
    for delay, freq, gain in [(0.0, 52, 1.0), (0.17, 60, 0.6)]:
        thump = []
        phase = 0.0
        for i in range(seconds(0.22)):
            f = freq * (1.0 + 0.6 * math.exp(-i / RATE / 0.02))  # a little pitch drop gives it punch
            phase += 2 * math.pi * f / RATE
            thump.append(math.sin(phase) * decay(i, 0.006, 0.05))
        mix_into(out, lowpass(thump, 300), seconds(delay), gain)
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for v in range(3):
        write(f"footstep_{v + 1}.wav", footstep(v), 0.7)
    write("bump.wav", bump(), 0.8)
    write("web_tear.wav", web_tear(), 0.6)
    write("door_creak.wav", door_creak(), 0.5)
    write("ambience_cave.wav", ambience(24, 7, False), 0.5)
    write("ambience_stone.wav", ambience(24, 3, True), 0.5)
    write("heartbeat.wav", heartbeat(), 0.9)


if __name__ == "__main__":
    main()
