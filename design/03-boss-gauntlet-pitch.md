# One-Page Pitch v2 — "The Last Beacon" (boss-gauntlet roguelike)

> **Status:** Concept locked 2026-08-01 after two playtests of the v1 concept
> (open-world souls-like with a light/fuel mechanic) — cut: too dark, resource
> pressure not fun. The v1 autopsy lives in design/01-one-page-pitch.md.
> **v2 lesson:** mastery, not oppression. Readable arenas, no resource taxes.
> **Title kept** (user's call); the keeper + anchor + drowned world survive;
> the lantern and embers do not.

**One sentence:** A 2D boss-gauntlet roguelike where the last lighthouse
keeper descends the sunken tower one boss at a time — each victory offers an
upgrade, each death restarts the descent, and only beating the Leviathan at
the bottom relights the beacon.

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
3. **Descend** — next boss, next arena. Six bosses, one descent
4. **Die** — the descent restarts, but a **meta-currency** persists
   (Hades-style permanent unlocks) — "one more run"
5. **Relight the beacon** — beat the Leviathan; the run is complete

## The Six Bosses (the descent)

1. **The Captain** — first; drowned shipmaster; teaches watch → dodge → punish
2. **The Tidesworn** — coral-and-iron colossus; teaches positioning
3. **The Keeper of the Old Lamp** — the previous keeper, fighting with YOUR
   moveset, one generation rustier; the mirror fight
4. **The Drowned Choir** — a choir of hollow sailors; multi-body, phase-shifting
5. **The Bell of the Flood** — the bell that tolled the sea's rise; arena
   floods in phases
6. **The Leviathan** — beneath all; the thing the lamp was forged to hold

## Why It's Buildable (honest scope)

- No world to build, no NPCs, no exploration content — the content IS bosses
  + upgrades + arenas
- The combat core already exists and is tested: movement, double jump, roll
  (i-frames), stamina, greatsword attack, death loop
- Every boss is a state machine — the 7-test suite verifies them
- **Timeline:** 12–18 months. Milestone 1 done (2026-08-01): **the Captain
  and the Tidesworn are built** — arenas, phases, victory beats, lap scaling.
  Milestone 2 done same day: **the run loop** — 9 upgrade cards, salt,
  death-restart. 7-test suite green.

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
