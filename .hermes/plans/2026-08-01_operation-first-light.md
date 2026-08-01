# OPERATION FIRST LIGHT — the visual overhaul brief

*A self-challenge prompt for the agent. Paste this whole file into a fresh
session to run it. Written 2026-08-01 against commit 49c8492.*

---

## The situation (stated honestly, no flattery)

The Last Beacon **plays** well: three bosses with real state machines, a run
loop, a duel with parries and stamina, 12 automated tests, green CI. It also
looks like a programmer's whiteboard sketch. Exact current state, from the
files:

- **The hero is two rectangles.** `scenes/player.tscn`: `Body` = a 22×34
  cream quad, `Hood` = a grey slab on top of it. No head, no arms, no legs.
  **Zero animation** — no idle, no run cycle, no landing squash. He slides
  like a fridge. The greatsword is 4 polygons that rotate as one rigid unit.
- **Bosses are rectangles** with 2–3 decorative polygons and a 4×4 square
  for an eye.
- **Backgrounds**: one vertical gradient `TextureRect`, four flat-colour
  column polygons at `z_index -20`, and a 16-sided "glow" at 6% alpha. No
  parallax, no depth, no atmosphere, no motion.
- **The project contains zero**: particles, shaders, texture assets,
  `AnimationPlayer`s, custom UI themes, fonts. Every button is default Godot.
- All combat feedback is `modulate` flashes and a rotating polygon.

## The mission

Make it look like a game a stranger would pay for on Steam — with no artist,
without breaking a single test, and without making it dark.

---

## Non-negotiable constraints (this is what makes it hard)

1. **The suite stays green.** `bash tests/run_tests.sh` = 12/12 before and
   after every commit. Headless rules hold: no state reads before frame 5,
   `Engine.time_scale` tricks stay guarded by
   `DisplayServer.get_name() != "headless"`.
2. **Collision and hitboxes DO NOT CHANGE.** All art is a *cosmetic layer*
   parented over unchanged physics bodies. `AttackBox` stays 40×32 at
   (20, 0). The 5-swing grunt kill and every boss contract must still hold.
   If a hitbox moves to suit the art, the art is wrong.
3. **BRIGHT AND READABLE.** The user rejected darkness twice ("way too
   dark", fuel/lantern cut). Every telegraph — the red slam zone, the
   cocked-back blade, the amber eye — must be **more** legible afterwards,
   not less. Murk is not mood.
4. **GL Compatibility renderer** (`project.godot` line 56). 2D
   `WorldEnvironment` glow is NOT available — bloom must be faked with
   additive sprites. `CanvasItem` shaders, `CPUParticles2D` and `Light2D`
   are fair game, but **verify each one actually renders in Compatibility**
   before building on it. Do not assume.
5. **Free.** Procedural, code-generated, or FLUX-generated art only. No paid
   assets. Everything committed to the repo.
6. **60 fps at 1280×720**, the project's configured viewport.

---

## The bar, per area

### 1. THE HUMAN FIGURE — the headline
A real silhouette: head, torso, pelvis, two arms (upper + fore), two legs
(thigh + shin), and a cape that lags behind motion. Built as a parented
`Node2D` rig of polygons so code can pose it.

**Animated, all of it:** idle breathing · a run cycle with actual leg
alternation and counter-swinging arms · jump extend · fall tuck · landing
squash · roll as a ball tuck with spin · attack with anticipation → strike →
follow-through → recovery. The cape reacts to velocity.

> **Test:** freeze any frame at 200% zoom. A stranger can tell which way he
> faces, whether he's running or standing, and where his sword is — *without
> the sword being the only clue.*

### 2. BACKGROUNDS
Three or more parallax layers at different scroll factors. Painted depth
(FLUX-generated PNGs committed to the repo) or procedurally layered
silhouettes with atmospheric fade. A foreground occlusion layer. Subtle
motion: drifting motes, sway, distant flicker.

> **Test:** one screenshot, UI cropped off — you know which of the three
> arenas it is, instantly.

### 3. BOSSES — silhouette first
Each boss readable **in pure black at 64px**: the Captain reads as a
warlord, the Bastion as a wall, the Fallen Beacon as your own reflection.
Phase 2 must change the **silhouette**, not just a colour.

### 4. IMPACT — what sells combat
Sword trail following the arc · directional hit sparks · impact ring on
heavy hits · dust on landing, rolling, and boss footfalls · a light burst on
death · screen shake tuned per hit weight.

> **Test:** mute the game, watch a hit land, and it's unmistakable that it
> connected — and unmistakable how *hard*.

### 5. UI / HUD
A custom `Theme` resource — no default Godot buttons anywhere. Typography
with real hierarchy. HP as something better than the literal string
`"♥♥♥♥♥"`. Bars that lerp instead of snapping, with a damage-preview ghost
fill. A card panel that reads as a *choice*, not three grey buttons. A menu
that makes someone want to press START.

### 6. POLISH
Faked bloom on the beacon glow, the eye, the blade tip · a **subtle**
vignette (readability rule still applies) · a better hit-flash than plain
white · arena transitions (currently a hard cut).

---

## The method — mandated, because it's how you avoid fooling yourself

**You may not ship art you have not looked at.**

1. Build the change.
2. **Capture it.** Temporary Godot script, non-headless: load the scene,
   wait N frames, pose the moment you need (mid-run, mid-swing, phase 2),
   `get_viewport().get_texture().get_image().save_png()`, quit.
3. **Look at it** with `vision_analyze` and critique it *honestly* — as a
   stranger scrolling a Steam page who owes you nothing. Write the critique
   down in the reply.
4. If it misses the bar, fix and repeat. **Minimum two iterations per area**
   — the first attempt is never good enough.
5. Suite green → commit → next area.

---

## Anti-cheese clauses

Every way you will be tempted to fake this. Don't:

- ❌ "Added a placeholder for future art." No. Ship the finished look.
- ❌ Calling a rectangle with three more polygons "a character." The
  silhouette test decides, not you.
- ❌ Going dark to hide that nothing is drawn. Rejected twice already.
- ❌ Effects so busy they bury the telegraphs. If the slam zone is harder to
  see, the change made the game worse.
- ❌ Skipping the screenshot loop and asserting it looks good.
- ❌ Loosening a test so a visual change passes. If a test breaks, say
  plainly whether the change is wrong or the claim genuinely moved.
- ❌ Declaring "done" without a before/after the user can see.

---

## Definition of done

- All six areas cleared, each with a **before/after PNG pair** delivered to
  the user.
- Suite 12/12, CI green, pushed.
- Frame-rate check at 1280×720.
- A written self-critique per area, scored /10 — **nothing below 7 ships.**
- The user opens the game and says "oh."

## Staging — ship and commit in this order

1. **The hero rig + animation** ← the headline; biggest perceived jump
2. **Impact FX** ← makes combat feel expensive
3. **Backgrounds + parallax** ← makes the world exist
4. **Boss silhouettes + phase-2 reads**
5. **UI theme + menu**
6. **Polish, bloom, transitions**
