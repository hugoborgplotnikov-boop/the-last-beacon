# Drill 2 — Meet Your Game: The Editor, the Node Tree, and Your First Cave

~30 minutes. Goal: understand the editor well enough to *change things yourself*,
and make your first edits to the world. No new code — this is all point-and-click.

---

## Part 1 — The editor tour (5 min)

Open Godot (`C:\Users\hugob\tools\godot\Godot_v4.7.1-stable_win64.exe`) and open
the project if it isn't already. You should see your cave.

Four areas matter:

| Where | What it is |
|---|---|
| **Center** | The 2D viewport — your cave, live |
| **Top-left (Scene dock)** | The **node tree** — every object in the current scene |
| **Right (Inspector)** | Properties of whatever is selected — the knobs and dials |
| **Bottom-left (FileSystem)** | All the project's files |

Hotkeys: **Q** select · **W** move · **E** rotate · **S** scale · **F** focus on
selection · **Ctrl+S** save · **F5** play · **Esc** stop.

## Part 2 — Read the node tree (5 min)

Open `scenes/world.tscn` (double-click it in the FileSystem). Click nodes and
watch the Inspector. The tree reads like a sentence:

```
World          <- the whole level; world.gd script is attached here
├─ Darkness    <- CanvasModulate: the dark filter over everything
├─ Floor       <- StaticBody2D: solid ground (CollisionShape2D = the physics, Visual = what you see)
├─ WallLeft / WallRight
├─ Platform1 / Platform2      <- floating platforms, same recipe
├─ Player      <- an *instance* of player.tscn (double-click to edit the original)
├─ Enemy1/2/3  <- instances of enemy.tscn
├─ Ember1
└─ UI          <- CanvasLayer: HP hearts, stamina bar, embers counter
```

Then open `scenes/player.tscn` and click around:

- **Body + Hood** — Polygon2D: the robe you see
- **CollisionShape2D** — the invisible physics body (dashed outline)
- **Lantern + Flame** — PointLight2D: *your* light in the dark
- **AttackBox / HitZone** — Area2D: the sword and the shield (invisible)

**The big idea:** nodes are building blocks. Scenes are reusable groups of nodes.
Scripts add behavior. Everything in this game is that simple.

## Part 3 — Build (15 min)

**Task 1 — add a platform.**
Right-click `Platform1` → **Duplicate** (or Ctrl+D). With **W** (move), drag the
new `Platform1` copy up and right — the Inspector numbers update as you drag.
Try landing on it: **F5**.

**Task 2 — place a grunt.**
In the FileSystem, drag `scenes/enemy.tscn` into the viewport, onto your new
platform. Move him so he stands on the surface. F5, walk near him, lure him off
the edge — gravity is your ally. (Right-click an Enemy node → **Rename** if you
want tidier names.)

**Task 3 — feel the difference (the important one).**
Click `Player` in the tree. In the Inspector, under the script's exported
settings: change `speed` from 220 to **300**, and `jump_velocity` from -420 to
**-520**. F5. Feel how the keeper moves now. This is game feel — and it's yours
to tune.

**Task 4 — make the dark scarier.**
Click `Enemy1`. In the Inspector: `speed` 55 → **90**, `aggro_range` 340 →
**500**. F5 — they hunt you from much further away now.

Save everything: **Ctrl+S** (or Ctrl+Shift+S to save all).

## Part 4 — Verify & commit (5 min)

Your edits can't break the test suite (it plays its own scripted game), but this
is the ritual you'll use forever:

```bash
cd ~/game-project
git add dev/TheLastBeacon
git commit -m "drill2: my first cave edits"
```

The pre-commit hook runs the headless suite automatically — **tests pass =
nothing broke**. If you want proof first:

```bash
bash dev/TheLastBeacon/tests/run_tests.sh
```

## Done? Ping me

Tell me: what did the faster jump / faster grunts *feel* like? Any node in the
tree you're curious about? Then we do **Drill 3** — a camera that follows the
keeper, and a cave that's actually yours.
