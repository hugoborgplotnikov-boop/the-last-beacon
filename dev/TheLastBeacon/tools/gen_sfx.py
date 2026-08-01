#!/usr/bin/env python3
"""Generate The Last Beacon SFX as WAV files (16-bit mono 44100Hz).

Pure stdlib (wave + math) — no numpy needed. Every sound is synthesized:
  swing    — noise sweep down (blade cutting air)
  hit      — metallic clang: decaying harmonics + noise burst
  hurt     — low thud + downward pitch blip
  roll     — short soft noise puff
  jump     — quick upward blip
  death    — descending minor chord, slow decay (hero falls)
  victory  — rising major arpeggio (boss falls)
  bell     — deep bell: low sine + inharmonic partials, long decay
  note     — choir note: soft sine with vibrato (projectile)
  click    — UI tick
  select   — UI confirm (two ticks)
  roar     — low growl: detuned saws + noise (boss intro)
"""
import math, struct, wave, os

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
os.makedirs(OUT, exist_ok=True)


def write(name, samples):
    # clamp + 16-bit PCM
    data = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data)
    print(f"  {name}.wav  {len(samples)/SR:.2f}s")


def env(n, a=0.005, r=0.1, curve=3.0):
    """Attack/release envelope over n samples."""
    out = []
    for i in range(n):
        t = i / n
        if t < a / (a + r):
            k = t / (a / (a + r))
            e = k ** 0.5
        else:
            k = (t - a / (a + r)) / (r / (a + r))
            e = (1 - k) ** curve
        out.append(e)
    return out


def noise(n, seed=0):
    import random
    rng = random.Random(seed)
    return [rng.uniform(-1, 1) for _ in range(n)]


def lowpass(sig, k=0.25):
    out = [sig[0]]
    for i in range(1, len(sig)):
        out.append(out[-1] + k * (sig[i] - out[-1]))
    return out


def highpass(sig, k=0.25):
    out = [0.0]
    prev = sig[0]
    for i in range(1, len(sig)):
        out.append(k * (out[-1] + sig[i] - prev))
        prev = sig[i]
    return out


def sine(freq, n, phase=0.0):
    return [math.sin(2 * math.pi * freq * i / SR + phase) for i in range(n)]


def sweep_noise(n, f0=2200, f1=300, seed=3):
    """Noise whose brightness sweeps f0 -> f1 (a whoosh)."""
    nz = noise(n, seed)
    # crude spectral sweep: apply progressive lowpass strength
    out = []
    prev = 0.0
    for i in range(n):
        t = i / n
        k = 0.05 + 0.9 * (1 - t)  # start bright, end dark
        prev = prev + k * (nz[i] - prev)
        out.append(prev)
    return out


def main():
    print("generating sfx ->", os.path.normpath(OUT))

    # swing: whoosh down 0.18s
    n = int(SR * 0.18)
    w = sweep_noise(n, 2600, 250, seed=5)
    e = env(n, 0.01, 0.17, 2.0)
    write("swing", [w[i] * e[i] * 0.9 for i in range(n)])

    # hit: metallic clang — 3 inharmonic partials + noise burst
    n = int(SR * 0.35)
    clang = [0.0] * n
    for freq, amp, decay in [(1240, 0.6, 0.09), (1870, 0.4, 0.06), (2620, 0.25, 0.04), (3700, 0.15, 0.03)]:
        s = sine(freq, n, phase=freq * 0.1)
        for i in range(n):
            clang[i] += amp * s[i] * math.exp(-i / (SR * decay))
    nz = lowpass(noise(n, seed=7), 0.35)
    for i in range(n):
        clang[i] += 0.5 * nz[i] * math.exp(-i / (SR * 0.02))
    e = env(n, 0.001, 0.1)
    write("hit", [clang[i] * e[i] * 0.85 for i in range(n)])

    # hurt: thud + downward blip 0.25s
    n = int(SR * 0.25)
    thud = [0.0] * n
    for freq, amp in [(160, 0.8), (95, 0.5)]:
        s = sine(freq, n)
        for i in range(n):
            thud[i] += amp * s[i] * math.exp(-i / (SR * 0.08))
    blip = sine(420, n)
    for i in range(n):
        blip[i] *= math.exp(-i / (SR * 0.06)) * math.sin(2 * math.pi * (1 - i / n) * 4) ** 2
    e = env(n, 0.002, 0.12)
    write("hurt", [(thud[i] * 0.8 + blip[i] * 0.35) * e[i] for i in range(n)])

    # roll: soft noise puff 0.2s
    n = int(SR * 0.2)
    nz = lowpass(noise(n, seed=11), 0.3)
    e = env(n, 0.03, 0.17, 2.5)
    write("roll", [nz[i] * e[i] * 0.5 for i in range(n)])

    # jump: quick upward blip 0.15s
    n = int(SR * 0.15)
    s = sine(300, n)
    for i in range(n):
        t = i / n
        s[i] *= math.sin(2 * math.pi * (0.5 + t * 0.5) * 3) ** 2
    e = env(n, 0.005, 0.12, 2.0)
    write("jump", [s[i] * e[i] * 0.4 for i in range(n)])

    # death: descending minor chord, 1.4s
    n = int(SR * 1.4)
    death = [0.0] * n
    for freq, amp in [(220, 0.5), (261.6, 0.35), (311.1, 0.25)]:  # A minor
        s = sine(freq, n)
        for i in range(n):
            death[i] += amp * s[i] * math.exp(-i / (SR * 0.5))
    e = env(n, 0.01, 0.5)
    write("death", [death[i] * e[i] * 0.7 for i in range(n)])

    # victory: rising major arpeggio 0.9s
    n = int(SR * 0.9)
    vict = [0.0] * n
    notes = [261.6, 329.6, 392.0, 523.3]  # C E G C
    seg = n // 4
    for k, freq in enumerate(notes):
        s = sine(freq, n, phase=0)
        start = k * seg
        for i in range(start, min(start + seg * 2, n)):
            j = i - start
            amp = 0.5 * min(1.0, j / (SR * 0.02)) * math.exp(-j / (SR * 0.35))
            vict[i] += amp * s[i]
    write("victory", [vict[i] * 0.7 for i in range(n)])

    # bell: deep bell 2.2s — fundamental + inharmonic partials
    n = int(SR * 2.2)
    bell = [0.0] * n
    for freq, amp, dec in [(130.8, 0.8, 0.9), (196, 0.35, 0.55), (261.6, 0.2, 0.35), (392, 0.12, 0.2)]:
        s = sine(freq, n)
        for i in range(n):
            bell[i] += amp * s[i] * math.exp(-i / (SR * dec))
    e = env(n, 0.002, 0.6)
    write("bell", [bell[i] * e[i] * 0.9 for i in range(n)])

    # note: choir note — soft sine with vibrato 0.6s
    n = int(SR * 0.6)
    note = []
    for i in range(n):
        t = i / SR
        vib = math.sin(2 * math.pi * 5.5 * t) * 0.06
        s = math.sin(2 * math.pi * (440 + 220 * vib) * t) * 0.5
        s += 0.25 * math.sin(2 * math.pi * 660 * t)
        note.append(s)
    e = env(n, 0.03, 0.25, 2.0)
    write("note", [note[i] * e[i] * 0.5 for i in range(n)])

    # click: UI tick 0.05s
    n = int(SR * 0.05)
    s = sine(1200, n)
    e = env(n, 0.001, 0.04, 1.5)
    write("click", [s[i] * e[i] * 0.4 for i in range(n)])

    # select: double tick 0.12s
    n = int(SR * 0.12)
    sel = [0.0] * n
    for start, freq in [(0, 900), (int(SR * 0.05), 1400)]:
        s = sine(freq, n - start)
        for i in range(start, n):
            j = i - start
            sel[i] += 0.4 * s[j] * math.exp(-j / (SR * 0.03))
    write("select", sel)

    # roar: detuned saws + noise, 0.7s (boss intro)
    n = int(SR * 0.7)
    roar = [0.0] * n
    for i in range(n):
        t = i / SR
        saw = (2 * (t * 75 % 1) - 1) + (2 * (t * 77 % 1) - 1)
        roar[i] = 0.3 * saw + 0.3 * noise(1, seed=i)[0]
    nz = lowpass(roar, 0.2)
    e = env(n, 0.08, 0.5, 2.0)
    write("roar", [nz[i] * e[i] * 0.8 for i in range(n)])

    print("done.")


if __name__ == "__main__":
    main()
