"""Original procedural audition effects for Depths; never replaces live audio.

Requires NumPy. Rebuild with Python tools/audio/generate_sfx_samples.py.
Each effect has a separate fixed seed. No recordings, models or external assets.
"""
from pathlib import Path
import hashlib
import json
import math
import wave

import numpy as np

RATE = 44100
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "audio/samples-v1"
TAU = 2 * math.pi


def time(seconds):
    return np.arange(round(seconds * RATE), dtype=np.float64) / RATE


def shaped_noise(rng, seconds, low, high):
    """Smooth spectral shoulders avoid the ringing of a brick-wall filter."""
    t = time(seconds)
    frequencies = np.fft.rfftfreq(len(t), 1 / RATE)
    spectrum = np.fft.rfft(rng.normal(size=len(t)))
    gain = 1 / np.sqrt(1 + (frequencies / high) ** 8)
    if low:
        gain *= (frequencies / low) ** 2 / np.sqrt(1 + (frequencies / low) ** 4)
    y = np.fft.irfft(spectrum * gain, n=len(t))
    return y / max(np.sqrt(np.mean(y * y)), 1e-12)


def envelope(t, attack, decay):
    return (1 - np.exp(-t / attack)) * np.exp(-t / decay)


def add(target, source, at, gain=1):
    start = round(at * RATE)
    count = min(len(source), len(target) - start)
    if count > 0:
        target[start:start + count] += source[:count] * gain


def modes(rng, seconds, frequencies, decays, attack=.0008):
    t = time(seconds)
    y = np.zeros_like(t)
    for i, (frequency, decay) in enumerate(zip(frequencies, decays)):
        phase = rng.uniform(-.3, .3)
        y += np.sin(TAU * frequency * t + phase) * envelope(t, attack, decay) / (1 + .45 * i)
    return y


def heartbeat(rng):
    y = np.zeros(len(time(.78)))
    t = time(.36)
    for at, pitch, gain in [(.025, 56, 1), (.205, 66, .60)]:
        frequency = pitch + 34 * np.exp(-t / .013)
        phase = TAU * np.cumsum(frequency) / RATE
        body = np.sin(phase) + .31 * np.sin(2 * phase + .12) + .10 * np.sin(3 * phase)
        skin = shaped_noise(rng, .36, 60, 600) * envelope(t, .003, .023)
        beat = body * envelope(t, .004, .045) + .16 * skin
        add(y, beat, at, gain)
    return y


def club_hit(rng):
    y = np.zeros(len(time(1.05)))
    t = time(.19)
    # Close cloth/air movement before the dense, dry wooden impact.
    swing = shaped_noise(rng, .19, 190, 2600) * np.sin(np.pi * t / .19) ** 2
    add(y, swing, .015, .10)
    t = time(.62)
    body = modes(rng, .62, [83, 139, 231, 387, 653], [.065, .045, .034, .022, .015])
    crush = shaped_noise(rng, .62, 130, 3400) * envelope(t, .0006, .014)
    cloth = shaped_noise(rng, .62, 220, 1600) * envelope(t, .002, .038)
    add(y, body + .55 * crush + .14 * cloth, .15)
    add(y, modes(rng, .20, [101, 187], [.03, .018]), .197, .12)
    return y


def shield_block(rng):
    y = np.zeros(len(time(1.20)))
    t = time(.72)
    wood = modes(rng, .72, [127, 213, 368, 604, 973], [.115, .083, .058, .038, .025])
    contact = shaped_noise(rng, .72, 350, 5300) * envelope(t, .0005, .009)
    add(y, wood + .38 * contact, .055)
    # Small iron fittings chatter; the shield is mostly rough timber.
    for at, gain in [(.071, .16), (.112, .09), (.174, .04)]:
        add(y, modes(rng, .35, [1760, 2937, 4211], [.07, .036, .019]), at, gain)
    add(y, shaped_noise(rng, .28, 120, 1300) * envelope(time(.28), .01, .055), .13, .07)
    return y


def coins(rng):
    y = np.zeros(len(time(1.85)))
    cloth = shaped_noise(rng, .65, 150, 1400) * envelope(time(.65), .035, .17)
    add(y, cloth, .02, .12)
    for i, at in enumerate([.12, .181, .253, .348, .467, .622, .806]):
        base = rng.uniform(1860, 2510)
        coin = modes(rng, .72, [base, base * 1.51, base * 2.09, base * 2.63], [.12, .083, .043, .024])
        impact = shaped_noise(rng, .72, 1100, 8200) * envelope(time(.72), .0003, .003)
        add(y, coin + .22 * impact, at, (.40 if i < 4 else .24) * rng.uniform(.75, 1))
    return y


def chest_open(rng):
    y = np.zeros(len(time(2.65)))
    add(y, modes(rng, .38, [581, 1457, 2513], [.04, .035, .022]), .055, .32)
    add(y, shaped_noise(rng, .12, 400, 4200) * envelope(time(.12), .001, .012), .067, .2)
    # Hinge friction wanders in pitch/amplitude rather than a clean oscillator.
    t = time(1.45)
    knots = rng.normal(size=90)
    wander = np.interp(t, np.linspace(0, t[-1], len(knots)), knots)
    frequency = 122 + 51 * t + 12 * np.sin(TAU * 6.7 * t) + 11 * wander
    phase = TAU * np.cumsum(frequency) / RATE
    hinge = np.sin(phase) + .32 * np.sin(2 * phase) + .18 * np.sin(3 * phase)
    friction = shaped_noise(rng, 1.45, 320, 2600)
    irregularity = np.clip(.45 + .23 * wander, .04, 1)
    shape = np.sin(np.pi * t / 1.45) ** 1.5
    add(y, (hinge * irregularity + .20 * friction) * shape, .28, .22)
    for at, gain in [(.37, .11), (.71, .075), (1.20, .06)]:
        add(y, modes(rng, .3, [94, 166, 312], [.055, .032, .019]), at, gain)
    add(y, modes(rng, .50, [108, 197, 421], [.10, .063, .029]), 1.76, .36)
    add(y, shaped_noise(rng, .40, 160, 1300) * envelope(time(.40), .02, .075), 1.87, .09)
    return y


def torch_light(rng):
    y = np.zeros(len(time(3.50)))
    for at, gain in [(.035, .16), (.17, .23)]:
        scrape = shaped_noise(rng, .18, 1300, 7500) * envelope(time(.18), .003, .024)
        add(y, scrape, at, gain)
    t = time(2.85)
    wind = shaped_noise(rng, 2.85, 90, 1900)
    hiss = shaped_noise(rng, 2.85, 800, 7000)
    shape = np.minimum(t / .18, 1) * np.minimum((2.85 - t) / .65, 1)
    # Low catch of flame, then a quiet dry burn with uneven crackles.
    catch = shaped_noise(rng, 2.85, 45, 680) * envelope(t, .018, .18)
    flutter = .60 + .13 * np.sin(TAU * 8.3 * t) + .08 * np.sin(TAU * 17.7 * t)
    fire = (wind * .095 * flutter + hiss * .018) * shape + .26 * catch
    for at in rng.uniform(.22, 2.48, 19):
        crack = shaped_noise(rng, .045, 700, rng.uniform(3400, 7300)) * envelope(time(.045), .0005, .003)
        add(fire, crack, at, rng.uniform(.015, .065))
    add(y, fire, .32)
    return y


def write(name, signal, peak_db):
    assert np.isfinite(signal).all()
    if peak_db is not None:
        signal = signal - np.mean(signal)
        # Declick every file boundary, including the quiet end of resonance tails.
        count = min(round(.008 * RATE), len(signal) // 2)
        ramp = np.sin(np.linspace(0, math.pi / 2, count)) ** 2
        signal[:count] *= ramp
        signal[-count:] *= ramp[::-1]
        signal *= 10 ** (peak_db / 20) / max(np.max(np.abs(signal)), 1e-12)
    pcm = np.rint(signal * 32767).astype('<i2')
    assert pcm[0] == pcm[-1] == 0 and np.max(np.abs(pcm.astype(int))) < 32767
    path = OUT / (name + '.wav')
    with wave.open(str(path), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(pcm.tobytes())
    with wave.open(str(path), 'rb') as stream:
        assert (stream.getnchannels(), stream.getsampwidth(), stream.getframerate(), stream.getnframes()) == (1, 2, RATE, len(pcm))
        assert stream.readframes(len(pcm)) == pcm.tobytes()
    decoded = pcm.astype(np.float64) / 32768
    return pcm.astype(np.float64) / 32767, {'file': path.name, 'seconds': round(len(pcm) / RATE, 4),
                     'peak_dbfs': round(20 * np.log10(np.max(np.abs(decoded))), 2),
                     'rms_dbfs': round(20 * np.log10(np.sqrt(np.mean(decoded ** 2)))),
                     'clipped_samples': 0, 'boundary_samples': [int(pcm[0]), int(pcm[-1])],
                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    effects = [('heartbeat', heartbeat, -9, 'Muffled two-part pulse; one cycle, no alarm tone.'),
               ('club-hit', club_hit, -6, 'Heavy dull impact, close cloth movement, short wooden body.'),
               ('shield-block', shield_block, -7, 'Rough wooden shield with a little iron fitting chatter.'),
               ('coin-pouch', coins, -10, 'A few worn coins settling in leather; small treasure or payment.'),
               ('chest-open', chest_open, -9, 'Latch, dragging hinge and wooden lid settling; no treasure fanfare.'),
               ('torch-light', torch_light, -10, 'Two scratches, flame catch and brief dry crackle fading out.')]
    records = []
    reel = [np.zeros(round(.25 * RATE))]
    cursor = .25
    for i, (name, generate, peak_db, description) in enumerate(effects):
        audio, record = write(name, generate(np.random.default_rng(96054 + i)), peak_db)
        record.update({'description': description, 'seed': 96054 + i, 'reel_start_seconds': round(cursor, 3)})
        records.append(record)
        reel.extend([audio, np.zeros(round(.65 * RATE))])
        cursor += len(audio) / RATE + .65
    # Preserve individual playback levels in the reel; avoid another gain change.
    _, review = write('audition', np.concatenate(reel), None)
    manifest = {'date': '2026-10-18', 'issues': [54, 96], 'status': 'procedural audition samples; not approved live replacements',
                'method': 'Original NumPy modal synthesis and filtered noise; no recordings or model-generated audio.',
                'python_source': 'tools/audio/generate_sfx_samples.py', 'numpy_version': np.__version__,
                'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16, 'looped': False,
                'checks': 'Finite samples, PCM round-trip, format, no clipping, zero boundary samples and SHA-256.',
                'effects': records, 'audition': review}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'effects': len(records), 'audition_seconds': review['seconds'], 'clipped_samples': 0,
                      'levels': {r['file']: {'peak_dbfs': r['peak_dbfs'], 'rms_dbfs': r['rms_dbfs']} for r in records}}, indent=2))


if __name__ == '__main__':
    main()
