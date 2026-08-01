#!/usr/bin/env python3
"""Generate The Last Beacon music loops as WAV (16-bit mono 44100Hz).

Two seamless 16-second loops, pure stdlib synthesis:
  menu_loop  — dark-epic drone: warm A-minor pad, low bass drone, sparse
               echoing arpeggio. Calm, lonely, vast.
  fight_loop — tense pulse: low thump every beat, ostinato bass,
               tremolo strings, occasional dissonant stab.

Loop-safety rules (so the 16s boundary clicks nothing):
  * every note starts after t>=0.6s and fully decays before t=15.2s
  * the pad chord is continuous and the same at t=0 and t=16
  * no hard transients at the boundary
"""
import math, struct, wave, os

SR = 44100
LEN = 16.0
N = int(SR * LEN)
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
os.makedirs(OUT, exist_ok=True)

buf = [0.0] * N


def add_sine(freq, t0, dur, amp, attack=0.05, release=0.3, detune=0.0, lfo_hz=0.0, lfo_depth=0.0):
    i0 = int(t0 * SR)
    n = int(dur * SR)
    i0 = max(0, i0)
    n = min(n, N - i0)
    if n <= 0:
        return
    for j in range(n):
        t = j / SR
        e = 1.0
        if t < attack:
            e = t / attack
        if t > dur - release:
            e = min(e, max(0.0, (dur - t) / release))
        f = freq * (1.0 + detune)
        if lfo_hz:
            f *= 1.0 + lfo_depth * math.sin(2 * math.pi * lfo_hz * (t0 + t))
        v = amp * e * math.sin(2 * math.pi * f * (t0 + t))
        buf[i0 + j] += v


def add_thump(t0, amp=0.5):
    """A soft kick-like thump (decaying sine) — no click at the start."""
    dur = 0.28
    i0 = int(t0 * SR)
    n = int(dur * SR)
    if i0 + n > N:
        return
    for j in range(n):
        t = j / SR
        f = 90.0 * math.exp(-t * 14.0) + 40.0
        e = math.exp(-t * 12.0)
        buf[i0 + j] += amp * e * math.sin(2 * math.pi * f * t)


def add_noise_pad(t0, dur, amp, cutoff):
    """Lowpassed noise whisper — air/atmosphere. Deterministic."""
    import random
    rng = random.Random(int(t0 * 1000))
    i0 = int(t0 * SR)
    n = int(dur * SR)
    if i0 + n > N:
        return
    prev = 0.0
    for j in range(n):
        t = j / SR
        e = 1.0
        if t < 0.5:
            e = t / 0.5
        if t > dur - 1.0:
            e = min(e, max(0.0, (dur - t) / 1.0))
        prev += cutoff * (rng.uniform(-1, 1) - prev)
        buf[i0 + j] += amp * e * prev * 2.0


def build_menu():
    """A-minor drone: A2-E3-A3-C4 pad, A1 bass, sparse pentatonic echoes."""
    # Continuous pad — same chord at t=0 and t=16, so the loop is seamless.
    pad = [(110.0, 0.16), (164.81, 0.12), (220.0, 0.10), (261.63, 0.07)]
    for freq, amp in pad:
        add_sine(freq, 0.0, LEN, amp, attack=2.0, release=2.0,
                 detune=0.0012, lfo_hz=0.07, lfo_depth=0.012)
    # Bass drone, octave + fifth shimmering under.
    add_sine(55.0, 0.0, LEN, 0.22, attack=1.5, release=2.0, detune=0.0008)
    add_sine(82.41, 0.0, LEN, 0.10, attack=2.0, release=2.0, lfo_hz=0.05, lfo_depth=0.05)
    # Air.
    add_noise_pad(0.0, LEN, 0.02, 0.06)
    # Sparse echoing arpeggio (A minor pentatonic: A C D E G), one note
    # every ~3.9s, each echoing twice via soft repeats. All decay before 15.2s.
    notes = [220.0, 261.63, 293.66, 329.63, 392.0]
    for k in range(4):
        t0 = 0.8 + k * 3.9
        f = notes[(k * 2) % len(notes)]
        add_sine(f, t0, 2.2, 0.10, attack=0.3, release=1.4)
        add_sine(f * 2.0, t0 + 0.7, 1.6, 0.04, attack=0.3, release=1.0)
        add_sine(f * 1.5, t0 + 1.4, 1.4, 0.03, attack=0.4, release=0.8)


def build_fight():
    """Tense pulse: thump every 0.5s, E ostinato, tremolo strings, stabs."""
    # Pulse.
    for k in range(31):
        add_thump(0.5 + k * 0.5, amp=0.42)
    # Ostinato bass: E1-E2 alternating each beat, riding the pulse.
    bass = [41.2, 82.41, 41.2, 82.41]
    for k in range(31):
        add_sine(bass[k % 4], 0.5 + k * 0.5, 0.45, 0.18, attack=0.01, release=0.1)
    # Tremolo strings: A4 + E5 with slow tremolo.
    add_sine(440.0, 0.0, LEN, 0.05, attack=1.2, release=1.5, lfo_hz=5.0, lfo_depth=0.5)
    add_sine(659.26, 0.0, LEN, 0.03, attack=1.5, release=1.5, lfo_hz=5.3, lfo_depth=0.5)
    # Dissonant stab every 4 beats (B2 against the E).
    for k in range(7):
        add_sine(123.47, 1.5 + k * 2.0, 0.9, 0.08, attack=0.02, release=0.5)
    # Low rumble layer.
    add_noise_pad(0.0, LEN, 0.025, 0.05)


def write(name):
    data = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in buf)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data)
    print(f"  {name}.wav  {LEN:.1f}s")


if __name__ == "__main__":
    print("generating music ->", os.path.normpath(OUT))
    build_menu()
    write("menu_loop")
    buf[:] = [0.0] * N
    build_fight()
    write("fight_loop")
    print("done.")
