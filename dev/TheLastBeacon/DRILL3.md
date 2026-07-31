# Drill 3 — Camera & Bigger World

Goal: the world is now bigger than your screen. The keeper carries a camera
that follows her, and the cave extends far to the right — with a guarded
treasure waiting.

## What changed (done for you)

- **Camera2D** on the Player. The camera is the invisible eye of the game:
  it follows the keeper with gentle smoothing (`position_smoothing_speed = 6`)
  and stops at the cave edges (`limit_right = 2200`).
- **The cave grew**: the floor and right wall now extend to x=2200 (was 1280).
- **New area**: Platform4 at (1700, 500) — floor-reachable, just like your
  Platform3. On it: a treasure (Ember2) and a grunt (Enemy5) guarding it.

## Your tasks (tiny)

1. **Press F5.** Walk right — past the old wall, into the dark. Feel the
   camera glide behind you. Find the platform with the ember. Lure the guard
   off, grab the treasure. That's the whole Drill 3 experience.
2. **Tune the camera** (optional, 30 seconds): open `scenes/player.tscn`,
   select the **Camera2D** node (top-left Scene panel, under Player).
   Top-right Inspector → **Position Smoothing → Speed**: try 3 (dreamy) and
   12 (snappy). Pick what feels right.
3. **Leave your mark** (optional): drag another `ember.tscn` (or a platform)
   somewhere in the new area — anywhere you like. Press Ctrl+S to save.
   You're the level designer now.

## Verify & commit

I've already committed the camera + new area (the test suite runs it: 5/5).
If you made tweaks in task 2–3, commit them yourself:

```bash
cd ~/game-project
git add dev/TheLastBeacon
git commit -m "drill3: my camera tuning"
```

The pre-commit hook runs the test suite automatically. If it passes, your
changes are in. If it fails, it tells you exactly why — no guessing.
