# The Last Beacon — Game Design Document v1 — RETIRED

> **RETIRED 2026-08-01 (user decision):** the lighthouse-keeper setting is
> gone — the game has nothing to do with it. This document is preserved as
> the historical autopsy of the v1 concept only. The live concept:
> design/03-boss-gauntlet-pitch.md — The Last Beacon = a HERO, the last
> line of defense for a falling world. (Hero + greatsword survived the
> pivot; keeper, lantern, embers, and the drowned world did not.)

*Status: v1 draft · 2026-08-01 · Companion to design/01-one-page-pitch.md · The playable slice (dev/TheLastBeacon) already proves the movement, combat, light, and death-loop pillars described here.*

---

## 1. Vision

A 2D souls-like about the last keeper of a lighthouse that has already gone out. The island drowned when the lamp died — the keeper descends into the sunken world to relight it, or to learn why it must never be lit again.

**The fantasy:** you are not a hero. You are a custodian walking into the dark with the only light left in the world. Every step is a decision about fire.

**The promise to the player:** punishing but fair combat, a world that descends with you, and a story told in whispers — item descriptions, half-drowned NPCs, and the silence of things that used to be above the water.

## 2. Player Fantasy & Core Loop

**Minute-to-minute:** explore a drowned space lit only by your lantern → find the threat in the dark → fight (attack / roll through attacks with i-frames / stamina management) → collect embers and light → decide: press on, or retreat to the Beacon to spend.

**Hour-to-hour:** descend one layer → meet its boss → die, learn, conquer → unlock the shortcut down → repeat.

**The loop is already real:** the slice has walk/jump/double-jump, roll (i-frames + stamina), lantern attack, grunts that chase and drop embers, darkness that only your light pushes back, and death → respawn at the Beacon with the world reset. The GDD grows this seed into the full game.

## 3. The Twist: Light Is Everything

> **PROTOTYPE RESULT (2026-08-01): CUT.** The first playtest rejected the
> fuel/darkness mechanic — *"way too dark, not a fan of the ember thing"* —
> and a second pass removed the lantern and embers entirely: **the keeper's
> weapon is now the greatsword.** This section survives as the design autopsy
> (the prototype did its job: killed a bad idea cheaply). The game is a
> straight souls-like: stamina gates combat.

One resource, three hungers — **fuel** (the lantern's oil) is:

1. **Sight** — your light radius IS your vision. Low fuel = a small island of fire around you; the dark closes in.
2. **Weapon** — attacks spend fuel (the flame lashes out). Out of fuel, you fight with a dead lantern: slow, weak, desperate.
3. **Vigor** — healing drinks fuel. (Equivalent: healing = light you'll never see again.)

**Design consequence:** the classic souls dilemma (do I heal or save?) becomes *thematic* (do I see or do I fight or do I live?). It's the same coin as the pitch: light is life, and life is scarce.

**Recovery:** Beacons refill fuel fully (like bonfires — also respawn enemies). Killed enemies drop **light motes** (small, refill fuel a little) and **embers** (currency — do NOT refill fuel). Keeper decisions: dive deeper with a half-tank, or retreat and refuel at the cost of the world resetting.

## 4. World: The Descent

One interconnected world, four main layers, connected by shortcuts (doors you unlock, ladders you drop, grates you kick). Souls-style: layers loop back on each other so the descent feels like one place, not levels.

| # | Layer | Character | The feeling |
|---|-------|-----------|-------------|
| 1 | **The Beacon's Crown** (surface) | storm-wracked cliffs, the dead lighthouse, first steps | tutorial of absence — the lamp is out |
| 2 | **The Sunken Stair** (sea caves) | flooded tunnels, tide pools, the first drowned | claustrophobia; the Captain waits below |
| 3 | **The Drowned City** | rooftops of a town that sank whole; bell towers, market squares | awe and grief — a civilization underwater |
| 4 | **The Deep** | the wreck of the old world; the place the lamp was forged | cosmic dread; the Leviathan beneath all |

**The Through-Line:** every layer is a question the keeper answers by descending — *who let the lamp die?* The answer is always the same: *the last keeper did.* (Including you, eventually.)

## 5. Systems & Progression

**Embers (currency):** dropped by enemies, found in the world. Spent at Beacons on the classic ladder: **Heart** (HP), **Lungs** (stamina), **Grip** (attack), **Crucible** (max fuel).

**Death (the souls contract):** die → drop your carried embers where you fell → respawn at the last Beacon, world reset. One run back to recover. Die again on the way → embers are gone. (Proven in the slice: death → respawn at beacon with world reset already works.)

**Pickups — CUT by playtest (2026-08-01):** embers are gone entirely; the
souls-currency (name TBD) will arrive with the leveling system. See §3.

**Beacons (bonfires):** refill fuel, respawn enemies, level up, rest. The lighthouse lamp itself is the first Beacon; relit lamps along the descent become the others. *Mechanic and story are the same object.*

## 6. Combat & Enemies

**Feel goals (the make-or-break):** weighty but responsive — every swing is a commitment, every roll is an answer, every death is earned. The slice's 5-test suite guards the core rules (combat, roll i-frames, movement, death loop, platform reachability) so feel changes can't silently break rules.

**Keeper moveset (current + planned):**
- Walk / run / jump / **double jump** (flame flare) — done
- **Roll** with i-frames, stamina-gated — done
- **Greatsword attack** (stamina-costing, heavy swing) — done
- *Planned:* charged greatsword swing, parry/riposte (high risk, high reward)

**Enemy families** (grunt-style chasers are done; each family adds one new behavior):
- **Grunts** — the drowned masses; chase + contact damage (done)
- **Heralds** — ranged; throw drowned fire; keep distance
- **Wardens** — armored; block; punish greedy combos; teach patience
- **Motes** — ambient threats that drift in the dark; teach *looking*

## 7. The Six Bosses

Six, per the scope guardrail (6–8). One-sentence designs — full move lists are prototype work, not GDD work:

1. **The Captain** — first boss; a drowned shipmaster who refuses to abandon his wreck; teaches *watch → dodge → punish*. The gatekeeper of the descent.
2. **The Tidesworn** — a colossus of coral, iron, and tide; slow, devastating; teaches *positioning and arena awareness*.
3. **The Keeper of the Old Lamp** — the previous keeper, who tried and failed; fights with YOUR moveset, one generation rustier; the mirror boss — *the emotional gut-punch*.
4. **The Drowned Choir** — a choir of hollow sailors singing the tide up the walls; multi-body, phase-shifting; *the midpoint crest*.
5. **The Bell of the Flood** — the great bell that tolled the sea's rise; rings the arena into flood phases; *the final lesson in patience*.
6. **The Leviathan** — beneath all; the thing the lamp was forged to hold; the reason the island drowned; *the last Beacon's true purpose*.

## 8. Story & Tone

**No cutscenes.** Story via: item descriptions (souls-style), 2–3 NPCs (a half-drowned sailor, a ghost of the old keeper, a child's echo), and the world itself (a schoolroom with the desks bolted to the ceiling; a wedding ring in a bell tower).

**The keeper is a guardian, not a survivor** ("last resort / last line of defense"): the game's final beat should make the player choose what "relighting the lamp" means — and the guardrail is that the tragedy (every previous keeper failed) is *earned by the player's own deaths*.

## 9. Art Direction

- **Silhouette-first 2D** (Godot 4.7.1, polygons — no external art needed yet).
- **The palette rule:** everything is deep blue-black except **fire**. Amber is the only saturated color in the game. If it glows, it matters.
- **Why this works for a solo beginner:** night, fog, and firelight hide amateur art mistakes; the player's eye goes where the light goes; the light is the mechanic, so the art IS the gameplay.
- Tools: Krita (free) + Aseprite (~$20, one-time) when sprites arrive; the slice's polygon style can carry the whole game.

## 10. Audio Direction

- **The rule: the dark is silent.** Sound design is light: footsteps that echo differently when the tide is high; the grunt's breathing before you see him (audio is a *second sense* — the game is played with ears when fuel is low).
- Music: sparse, tidal — long swells, then silence. Budget line: commissioned soundtrack €100–300 in production; free/CC0 placeholders now.

## 11. Technical Pillars

- Godot 4.7.1, GDScript, 2D — proven by the slice.
- **Verification culture:** headless behavioral test suite (`bash tests/run_tests.sh`, 7 tests), pre-commit hook, CI workflow live on GitHub. Every new system gets a test (combat rules, death contract, boss state machines, run loop).
- Performance headroom: 2D + light is cheap; the whole game can run on modest hardware — good for Steam Deck and low-spec wishlists.

## 12. Scope Guardrails & Risks

**Locked guardrails:** one interconnected world · 6–8 bosses (6 chosen) · no cutscenes · solo dev · budget €100–300/mo · 12–24 month timeline.

**Risks, named honestly:**
1. **Combat feel** (the whole game) — mitigated: prototype = one boss that feels great (the Captain) before anything else gets built. If the Captain doesn't feel good, nothing else matters.
2. **Fuel economy tuning** — the twist is only fun if it's a choice, not a tax. Prototype will test: is "fight in the dark" a tragedy or a chore?
3. **Scope creep on the Drowned City** (the most visually rich layer) — guardrail: each layer gets ONE signature set-piece; everything else is corridors.
4. **Burnout** — the 12–24 month reality; milestones are small and shippable (the slice is already a shippable tech demo).

## 13. What's Already Proven (slice inventory)

Walk/jump/double-jump · roll + i-frames + stamina · greatsword attack (swing animation) · grunt AI (chase/contact/knockback/respawn) · death → respawn, world reset · bright visible cave · camera follow with cave limits · platforms with honest collision · **the run loop: 9 upgrade cards + shards + lap scaling (run.gd)** · **three bosses: the Captain (lunge/slam/sweep, phase 2), the Bastion (eruption/sweep/charge, phase 2), and the Fallen Beacon (greatsword chop + i-frame roll, phase 2 counters)** · hit-stop + screen shake · **the shards shop: 5 permanent unlocks + save file, shop hub between runs (shop.gd)** · 12-test automated suite + hook.

**Next build step:** boss #4 — the Hollow Choir (multi-body, phase-shifting).

## 14. Open Design Questions (deferred — not blockers)

- ~~Exact fuel numbers and cost curve~~ (moot — mechanic cut by playtest, see §3).
- Stat names/curves (Heart/Lungs/Grip/Crucible — placeholder).
- Whether the final beat offers a choice (relight vs. let it stay dark) or is fixed — *deliberately not decided yet*; the story needs the prototype's combat feel to land first.
- **ANSWERED (2026-08-01):** the fuel/light resource is cut by playtest — see §3. The remaining open question is the ending choice above.
- NPC roster details (the sailor, the ghost, the child) — v2 after prototype.
