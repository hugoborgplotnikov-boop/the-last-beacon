# The Last Beacon

A boss-gauntlet roguelike. You are the last beacon of a falling world —
fight the champions who fell before you, pick upgrade cards between
fights, and each lap the roster comes back meaner. Die, and the gauntlet
starts again (shards survive).

## The Roster (6/6 built)

1. **The Captain** — lunge, slam, sweep; phase 2 below half HP. Teaches *watch → dodge → punish*.
2. **The Bastion** — ground-eruption telegraphs, sweep, charge; the wall. Teaches *patience*.
3. **The Fallen Beacon** — the mirror fight: *your* moveset, one generation rustier. Parries idle swings, spends stamina, gasps when spent. Teaches *rhythm*.
4. **The Hollow Choir** — four singers, one shared HP pool, weaving notes that home in phase 2. Teaches *position*.
5. **The Bell of the Last Hour** — shockwave rings you must jump, debris from above. Teaches *timing*.
6. **The Night** — teleports, shadow strikes, phase 2 faster. Everything you've learned.

## The Loop

- **START NEW GAME** → Captain → Bastion → Fallen Beacon → Hollow Choir → Bell → Night → lap 2 (scaled).
- Victory → pick **1 of 3 upgrade cards** (20-card pool).
- Death → **YOU DIED** → back to the menu. Shards survive in the save file.

## Main Menu & Shop

The game boots to **START NEW GAME**. The shards shop is resting — its
wallet, unlocks, and save plumbing (`run.gd`) are live and tested, and it
can return anytime as the between-runs hub.

## Controls

| Key | Action |
|---|---|
| WASD / Arrows | Move |
| Space | Jump · Space (mid-air) — double jump |
| Shift | Roll (i-frames — dodge through attacks) |
| J | Attack with the greatsword (costs stamina) |

## How to run

1. Open Godot (`C:\Users\hugob\tools\godot\Godot_v4.7.1-stable_win64.exe`)
2. **Import** → browse to `C:\Users\hugob\game-project\dev\TheLastBeacon\project.godot`
3. Press **F5** (or the Play button) — you land on the main menu

The old training cave still exists as `scenes/world.tscn` (open it in the
editor and F6 to play that scene directly).

## Testing

Headless behavioral tests simulate real playthroughs and assert the core
systems. Run from this folder:

```bash
bash tests/run_tests.sh        # or: ./tests/run_tests.sh
```

- **15 tests**: movement, combat, roll, death loop, platforms, Captain,
  Bastion, Fallen Beacon, Choir, Bell, Night, run loop, shards shop,
  end-to-end soak (full 6-boss lap), and a **bot** that plays the Captain
  with real inputs.
- Every `tests/test_*.gd` runs in its own headless Godot process — it loads
  the real scenes, presses the same inputs a player would, and checks the
  results (exit 0 = pass).
- The shared `tests/harness.gd` tracks checks and prints the summary.
- **Add a test:** copy an existing `test_*.gd`, rename it, write a new input
  schedule and `h.check(...)` assertions — the runner picks it up
  automatically.
- Godot is auto-detected; override with
  `GODOT_BIN=/path/to/godot bash tests/run_tests.sh` if needed.
- **Pre-commit hook:** `bash scripts/install-hooks.sh` (repo root) installs a
  hook that runs the suite automatically whenever game files are staged;
  doc-only commits skip it. The GitHub Actions workflow
  (`.github/workflows/test.yml`) runs the same suite on push/PR.
