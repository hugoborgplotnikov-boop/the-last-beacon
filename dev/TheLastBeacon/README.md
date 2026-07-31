# The Last Beacon — Drill 1: Movement & the Lantern

The first playable slice: a keeper, a dark cave, drowned grunts, and a lantern.

## How to run

1. Open Godot (`C:\Users\hugob\tools\godot\Godot_v4.7.1-stable_win64.exe`)
2. **Import** → browse to `C:\Users\hugob\game-project\dev\TheLastBeacon\project.godot`
3. Press **F5** (or the Play button)

## Controls

| Key | Action |
|---|---|
| WASD / Arrows | Move |
| Space | Jump · Space (mid-air) — double jump |
| Shift | Roll (i-frames — dodge through attacks) |
| J | Attack with the lantern (costs stamina) |
| — | Embers heal you — the seed of the souls economy |

## What this drill teaches

- Movement feel: acceleration, jump arc, gravity — the foundation of combat feel
- The light twist: the lantern is the keeper's identity — a warm glow in a
  visible drowned world (pure atmosphere; no fuel pressure)
- Stamina tension: every attack and roll costs — the souls resource loop
- The death loop: die → **YOU DIED** → respawn, enemies reset (the bonfire rhythm)

## Drill goals (try these!)

1. Kill all three grunts without taking a hit
2. Roll *through* a grunt's attack (i-frames)
3. Lure a grunt off the platform — gravity is your ally
4. Spend stamina to zero, then survive 5 seconds without attacking

## Next

Drill 2: open the editor, learn the node tree, and build your own cave.

---

## Testing

Headless behavioral tests simulate real playthroughs and assert the core
systems. Run from this folder:

	bash tests/run_tests.sh        # or: ./tests/run_tests.sh

- Every `tests/test_*.gd` runs in its own headless Godot process — it loads
  the real `world.tscn`, presses the same inputs a player would, and checks
  the results (exit 0 = pass).
- The shared `tests/harness.gd` tracks checks and prints the summary.
- **Add a test:** copy an existing `test_*.gd`, rename it, write a new input
  schedule and `h.check(...)` assertions — the runner picks it up
  automatically.
- Godot is auto-detected; override with
  `GODOT_BIN=/path/to/godot bash tests/run_tests.sh` if needed.
- **Pre-commit hook:** `bash scripts/install-hooks.sh` (repo root) installs a
  hook that runs the suite automatically whenever game files are staged;
  doc-only commits skip it. The GitHub Actions workflow
  (`.github/workflows/test.yml`) runs the same suite on push/PR once the repo
  is pushed to GitHub.
