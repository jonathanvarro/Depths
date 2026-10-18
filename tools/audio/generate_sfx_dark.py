"""Darker procedural sound auditions, keeping v1 and all live audio intact.

Run with Python/NumPy: python tools/audio/generate_sfx_dark.py.
Shares only synthesis primitives with generate_sfx_samples.py; never runs v1.
"""
import hashlib
import json
import math
import wave

import numpy as np

from generate_sfx_samples import RATE, ROOT, time, shaped_noise, envelope, add, modes

OUT = ROOT / 'audio/samples-v2-dark'


def roughness(rng, t, interval=.018):
    knots = np.arange(0, t[-1] + interval * 2, interval)
    return np.interp(t, knots, rng.uniform(.18, 1, len(knots)))


def filtered(signal, low, high):
    frequencies = np.fft.rfftfreq(len(signal), 1 / RATE)
    gain = 1 / np.sqrt(1 + (frequencies / high) ** 8)
    if low:
        gain *= (frequencies / low) ** 2 / np.sqrt(1 + (frequencies / low) ** 4)
    return np.fft.irfft(np.fft.rfft(signal) * gain, n=len(signal))


def heartbeat(rng):
    y = np.zeros(len(time(.78)))
    t = time(.35)
    # Broad, muffled pressure pulses, without a pitched kick-drum glide.
    for at, gain in [(.025, 1), (.205, .64)]:
        pressure = shaped_noise(rng, .35, 32, 150)
        contact = shaped_noise(rng, .35, 95, 390)
        skin = shaped_noise(rng, .35, 200, 700)
        beat = pressure * envelope(t, .004, .039)
        beat += .40 * contact * envelope(t, .002, .024)
        beat += .055 * skin * envelope(t, .002, .032)
        add(y, beat, at, gain)
    return y


def club_hit(rng):
    y = np.zeros(len(time(1.05)))
    t = time(.115)
    # Little wind-up; most of the sound is actual contact, not a comic whoosh.
    add(y, shaped_noise(rng, .115, 180, 1450) * np.sin(np.pi * t / .115) ** 2, .02, .045)
    t = time(.32)
    pressure = shaped_noise(rng, .32, 38, 230) * envelope(t, .0014, .026)
    density = shaped_noise(rng, .32, 130, 740) * envelope(t, .0008, .019)
    cloth = shaped_noise(rng, .32, 280, 1700) * envelope(t, .001, .032)
    crack = shaped_noise(rng, .32, 600, 3200) * envelope(t, .00035, .0045)
    hit = 1.05 * pressure + .60 * density + .31 * cloth + .18 * crack
    # Low, rough saturation adds material density rather than a ringing note.
    hit = filtered(np.tanh(hit * 1.18) / 1.18, 28, 3300)
    add(y, hit, .125)
    for at, strength in [(.129, .11), (.139, .07), (.154, .035)]:
        grain = shaped_noise(rng, .07, 260, 2200) * envelope(time(.07), .0005, .005)
        add(y, grain, at, strength)
    # Brief, quiet room reflections; no long cinematic bass tail.
    add(y, filtered(hit, 60, 950), .153, .10)
    add(y, filtered(hit, 80, 650), .182, .045)
    return y


def shield_block(rng):
    y = np.zeros(len(time(1.20)))
    t = time(.38)
    wood = shaped_noise(rng, .38, 82, 470) * envelope(t, .0015, .045)
    splinter = shaped_noise(rng, .38, 380, 2700) * envelope(t, .0004, .010)
    strain = shaped_noise(rng, .38, 160, 1100) * envelope(t, .004, .055)
    add(y, wood + .40 * splinter + .22 * strain, .055)
    for at, strength in [(.063, .10), (.077, .075), (.102, .035)]:
        fitting = shaped_noise(rng, .12, 900, 3500) * envelope(time(.12), .0004, .012)
        add(y, fitting, at, strength)
    add(y, shaped_noise(rng, .23, 210, 1350) * envelope(time(.23), .009, .036), .14, .09)
    return y


def coin_pouch(rng):
    y = np.zeros(len(time(1.85)))
    t = time(.88)
    leather = shaped_noise(rng, .88, 115, 1250)
    add(y, leather * envelope(t, .018, .20) * roughness(rng, t, .035), .025, .22)
    for at, strength in [(.13, .35), (.174, .29), (.253, .24), (.367, .20), (.553, .13), (.72, .065)]:
        base = rng.uniform(1450, 2060)
        # Damped against leather rather than a long, bright treasure chime.
        ring = modes(rng, .27, [base, base * 1.47, base * 2.14], [.031, .016, .009])
        contact = shaped_noise(rng, .27, 700, 4100) * envelope(time(.27), .0004, .005)
        add(y, .64 * ring + .32 * contact, at, strength)
    return filtered(y, 75, 4600)


def chest_open(rng):
    y = np.zeros(len(time(2.65)))
    latch = shaped_noise(rng, .22, 180, 1800) * envelope(time(.22), .0006, .016)
    add(y, latch, .055, .48)
    add(y, modes(rng, .12, [482, 1169], [.009, .005]), .065, .08)
    t = time(1.48)
    scrape = shaped_noise(rng, 1.48, 210, 1750)
    wood = shaped_noise(rng, 1.48, 75, 460)
    stick_slip = roughness(rng, t, .012) ** 1.7
    shape = np.sin(np.pi * t / 1.48) ** 1.1
    # Friction dominates; irregular low creak is a small supporting layer.
    pitch = 96 + 26 * (roughness(rng, t, .031) - .5)
    phase = 2 * math.pi * np.cumsum(pitch) / RATE
    creak = np.sin(phase) + .15 * np.sin(2 * phase)
    hinge = (.30 * scrape * stick_slip + .11 * wood + .028 * creak) * shape
    add(y, hinge, .28)
    for at, strength in [(.43, .09), (.84, .06), (1.32, .08)]:
        add(y, shaped_noise(rng, .16, 110, 850) * envelope(time(.16), .0009, .027), at, strength)
    lid = shaped_noise(rng, .46, 58, 650) * envelope(time(.46), .0015, .047)
    lid += .18 * shaped_noise(rng, .46, 320, 2100) * envelope(time(.46), .0008, .011)
    add(y, lid, 1.80, .58)
    add(y, shaped_noise(rng, .39, 130, 1100) * envelope(time(.39), .012, .073), 1.88, .08)
    return y


def torch_light(rng):
    y = np.zeros(len(time(3.50)))
    for at, strength in [(.035, .12), (.17, .19)]:
        scrape = shaped_noise(rng, .14, 800, 4300) * envelope(time(.14), .002, .018)
        add(y, scrape, at, strength)
    t = time(2.85)
    shape = np.minimum(t / .16, 1) * np.minimum((2.85 - t) / .65, 1)
    draft = shaped_noise(rng, 2.85, 95, 1450)
    char = shaped_noise(rng, 2.85, 550, 3100)
    fire = (draft * .115 + char * .040) * roughness(rng, t, .024) * shape
    fire += .17 * shaped_noise(rng, 2.85, 90, 900) * envelope(t, .018, .125)
    for at in rng.uniform(.20, 2.47, 23):
        crack = shaped_noise(rng, .065, 400, rng.uniform(1700, 3400)) * envelope(time(.065), .0006, .005)
        add(fire, crack, at, rng.uniform(.012, .060))
    add(y, fire, .32)
    return y


def write(name, signal, peak_db=None):
    assert np.isfinite(signal).all()
    if peak_db is not None:
        signal = signal - np.mean(signal)
        count = min(round(.008 * RATE), len(signal) // 2)
        ramp = np.sin(np.linspace(0, math.pi / 2, count)) ** 2
        signal[:count] *= ramp
        signal[-count:] *= ramp[::-1]
        signal *= 10 ** (peak_db / 20) / max(np.max(np.abs(signal)), 1e-12)
    assert np.max(np.abs(signal)) < 1
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
    return pcm.astype(np.float64) / 32767, {
        'file': path.name, 'seconds': round(len(pcm) / RATE, 4),
        'peak_dbfs': round(20 * np.log10(np.max(np.abs(decoded))), 2),
        'rms_dbfs': round(20 * np.log10(np.sqrt(np.mean(decoded ** 2))), 2),
        'clipped_samples': 0, 'boundary_samples': [int(pcm[0]), int(pcm[-1])],
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def read(path):
    with wave.open(str(path), 'rb') as stream:
        assert (stream.getnchannels(), stream.getsampwidth(), stream.getframerate()) == (1, 2, RATE)
        return np.frombuffer(stream.readframes(stream.getnframes()), dtype='<i2').astype(np.float64) / 32767


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    effects = [
        ('heartbeat', heartbeat, -9, 'Muffled pressure and skin; removes the pitched drum-like glide.'),
        ('club-hit', club_hit, -6, 'Dense irregular thud, crushed cloth and abrupt wooden contact; no ringing body.'),
        ('shield-block', shield_block, -7, 'Strained rough timber, hard contact and short dull fitting chatter.'),
        ('coin-pouch', coin_pouch, -10, 'Damped worn coins against creased leather; less sparkle and shorter rings.'),
        ('chest-open', chest_open, -9, 'Heavy latch, abrasive hinge friction and dull wooden lid; less tonal squeak.'),
        ('torch-light', torch_light, -10, 'Coarser flint, uneven low fire and dry charcoal crackles; less airy hiss.')]
    records = []
    clips = {}
    reel = [np.zeros(round(.25 * RATE))]
    cursor = .25
    for i, (name, generate, peak_db, description) in enumerate(effects):
        audio, record = write(name, generate(np.random.default_rng(960542 + i)), peak_db)
        record.update({'description': description, 'seed': 960542 + i, 'reel_start_seconds': round(cursor, 3)})
        records.append(record)
        clips[name] = audio
        reel.extend([audio, np.zeros(round(.65 * RATE))])
        cursor += len(audio) / RATE + .65
    _, audition = write('audition', np.concatenate(reel))
    # A/B compares timbre at equal whole-clip RMS. Attenuate only, never boost.
    old = read(ROOT / 'audio/samples-v1/club-hit.wav')
    new = clips['club-hit'].copy()
    energy = [np.sqrt(np.mean(a * a)) for a in [old, new]]
    target = min(energy)
    gains = [target / e for e in energy]
    comparison = np.concatenate([np.zeros(round(.25 * RATE)), old * gains[0],
                                 np.zeros(round(.80 * RATE)), new * gains[1], np.zeros(round(.4 * RATE))])
    _, ab = write('club-comparison', comparison)
    ab.update({'order': ['v1 original', 'v2 dark'], 'start_seconds': [.25, 2.10],
               'comparison_gain_db': [round(20 * np.log10(g), 3) for g in gains],
               'matching': 'Equal whole-clip RMS; not a perceptual loudness calibration.'})
    manifest = {
        'date': '2026-10-18', 'issues': [54, 96], 'status': 'Owner-requested darker synthesized auditions; live replacements undecided.',
        'direction': 'Dense contact, rough material friction, short damped resonance; avoid cartoon pitch glides or musical ringing.',
        'method': 'Original filtered-noise synthesis, subdued modal metal and irregular friction. No recordings or AI audio service.',
        'python_source': 'tools/audio/generate_sfx_dark.py', 'shared_primitives': 'tools/audio/generate_sfx_samples.py',
        'numpy_version': np.__version__, 'sample_rate': RATE, 'channels': 1, 'pcm_bits': 16, 'looped': False,
        'checks': 'Finite samples, PCM round-trip, format, headroom, zero endpoints and SHA-256.',
        'effects': records, 'audition': audition, 'club_comparison': ab}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'effects': len(records), 'audition_seconds': audition['seconds'],
                      'comparison_seconds': ab['seconds'], 'comparison_gain_db': ab['comparison_gain_db'],
                      'levels': {r['file']: [r['peak_dbfs'], r['rms_dbfs']] for r in records}}, indent=2))


if __name__ == '__main__':
    main()
