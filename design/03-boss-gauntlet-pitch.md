# One-Page Pitch v2 — "The Last Beacon" (boss-gauntlet roguelike)

> **Status:** Concept locked 2026-08-01. The v1 keeper/lighthouse setting is
> **retired** (user decision 2026-08-01 — the game has nothing to do with a
> lighthouse keeper): **The Last Beacon is the HERO — the last line of
> defense for a falling world.** Autopsies: design/01-one-page-pitch.md +
> design/02-game-design-doc.md. **v2 lesson:** mastery, not oppression.
> Readable arenas, no resource taxes. **Title kept** (user's call); hero +
> greatsword survive; keeper, lantern, embers, and the drowned world do not.

**One sentence:** A 2D boss-gauntlet roguelike where you are the last beacon
of a falling world — face the champions who fell before you, one boss at a
time; each victory offers an upgrade, each death restarts the gauntlet, and
only beating the Night at the end saves what's left of the light.

---

## The Essentials

- **Genre:** boss-rush roguelike — *Furi × Hades* (2D action, mastery combat)
- **Tone:** dark epic — dramatic, serious, readable but intense (*Sekiro*)
- **Platform:** PC (Steam) first; Steam Deck-friendly
- **Team:** solo dev, first game. **Engine:** Godot 4.7.1
- **Audience:** boss-fight and roguelike fans — Sekiro, Furi, Hades, Khazan

## The Loop

1. **Fight** — one boss, one clean arena. Every boss teaches one lesson
   (dodge · punish · patience · position)
2. **Win** — choose **1 of 3 upgrade cards** (damage, stamina, a new move,
   lifesteal, speed...). Your build stacks; fights change because *you* changed
3. **Advance** — next boss, next arena. Six trials, one gauntlet
4. **Die** — the gauntlet restarts, but **shards** (the meta-currency)
   persist — spend them at **the shop** on permanent unlocks (Hades-style
   "one more run")
5. **Beat the Night** — the last trial; the world keeps its light

## The Six Trials (the fallen champions)

1. **The Captain** — a warlord of the first line, taken by the dark; teaches
   watch → dodge → punish *(built)*
2. **The Bastion** — a colossus of stone and iron, the last wall that fell;
   teaches positioning *(built)*
3. **The Fallen Beacon** — the hero who held the light before you, fighting
   with YOUR moveset, one generation rustier; the mirror fight
4. **The Hollow Choir** — the voices of the fallen singing as one; multi-body,
   phase-shifting
5. **The Bell of the Last Hour** — the bell that tolled when the defense
   broke; the arena shifts in phases
6. **The Night** — the dark that takes the world; the reason the beacon
   exists at all

## Why It's Buildable (honest scope)

- No world to build, no NPCs, no exploration content — the content IS bosses
  + upgrades + arenas
- The combat core already exists and is tested: movement, double jump, roll
  (i-frames), stamina, greatsword attack, death loop
- Every boss is a state machine — the 9-test suite verifies them
- **Timeline:** 12–18 months. Milestone 1 done (2026-08-01): **the Captain
  and the Bastion are built** — arenas, phases, victory beats, lap scaling.
  Milestone 2 done same day: **the run loop** — 9 upgrade cards, shards,
  death-restart. Milestone 3 done same day: **the shards shop** — 5 permanent
  unlocks, save file, shop hub between runs. 10-test suite green.

## Risk (named honestly)

**Combat feel is the whole game** — if the Captain doesn't feel great, nothing
else matters. That's why the prototype stays: build the Captain first, alone,
before any other content.

## Budget Reality (€100–300/mo)

| Item | Cost |
|---|---|
| Godot 4, Krita, Git/GitHub | Free |
| Aseprite (pixel art) | ~$20 one-time |
| Steam Direct fee | $100 one-time (at store-page time) |
| Asset packs (itch.io) | €10–50 as needed |
| Commissioned music (later) | €100–300 per track pack |
