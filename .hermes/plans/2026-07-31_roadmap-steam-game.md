# Steam Game Journey — Roadmap & Hermes Setup

**Goal:** Design, build, and launch a game on Steam.

**Status:** Phase 0 (Foundation) — in progress. Game concept not yet chosen.

---

## The Journey at a Glance

| Phase | What happens | Exit criteria | Typical duration |
|---|---|---|---|
| **0. Foundation** | Pick concept, scope, engine, tools; set up workspace | One-page pitch agreed; engine chosen | 1–2 weeks |
| **1. Design** | Game Design Document (GDD): core loop, systems, art direction, scope budget | GDD v1 written; scope locked | 2–4 weeks |
| **2. Prototype** | Build the *core loop* only — placeholder art, one mechanic | Fun is proven; prototype playable end-to-end | 2–6 weeks |
| **3. Vertical Slice** | One polished slice: real art style, one full level/segment, UI, audio | Slice demoable to strangers; art style locked | 1–2 months |
| **4. Production** | Build content at scale; systems complete; milestones every 2–4 weeks | Feature-complete; content done | 3–12+ months |
| **5. Playtest & Polish** | Closed playtests, bug bashes, balance, Steam Deck check, accessibility | Release candidate; bug list near zero | 1–2 months |
| **6. Steam Store** | Steamworks setup, store page live, capsule art, demo for Next Fest, wishlist campaign | 5,000–10,000+ wishlists before launch | 3–6 months before launch (starts EARLY) |
| **7. Launch** | Release day checklist, patch cadence, community, post-launch updates | Game out; first patch shipped | Launch week + ongoing |

**Golden rule: marketing (Phase 6) starts at Phase 3, not after the game is done.** Wishlists are the #1 predictor of Steam launch success.

---

## Steam Facts to Plan Around (verified, stable)

- **Steam Direct fee:** $100 per game, recoupable after the game earns $1,000 in sales.
- **Revenue split:** 70/30 (Valve takes 30%). Improves to 75/25 above $10M lifetime earnings.
- **Store page can go live long before the game is finished** — early page + wishlists = launch-day visibility.
- **Steam Next Fest** (3×/year) is the single biggest wishlist driver for small games; requires a playable demo.
- **Steam Deck verification** is worth targeting — a huge, underserved audience for indie games.
- Non-US sellers must complete tax forms (W-8BEN) when setting up the Steamworks account.

---

## Hermes Setup (how we work together)

- **Desktop Project:** `Steam Game Project` anchored at `C:\Users\hugob\game-project` — this chat is now its workspace.
- **Folders:**
  - `design/` — GDD, pitches, concept docs, reference art
  - `dev/` — engine project, code, builds
  - `marketing/` — store page copy, capsule art briefs, screenshots, wishlist tracking
  - `docs/` — research, Steam checklist, launch runbook
  - `.hermes/plans/` — milestone plans (this file lives here)
- **Memory:** durable facts (scope, engine, decisions) persist across sessions — you never re-explain.
- **Session history:** `session_search` lets us resume any past session ("where did we leave off?").
- **Cron:** optional weekly progress check-in / Steam marketing reminders once we're in Phase 6.
- **Delegation:** I can spawn parallel research agents (competitor store pages, tag analysis, market research) without flooding this chat.
- **Skills:** we'll codify recurring workflows (e.g., a `steam-store-page` skill, a `game-design-doc` skill) as we learn them.

---

## Buzz Integration (Block's agent workspace)

**What it is (verified from Block's announcement, July 2026):** Buzz is a free, open-source (Apache-2.0) collaboration platform from Block (Jack Dorsey's company) — available at buzz.xyz, source at github.com/block/buzz. It's a Slack-style workspace (channels, threads, DMs, voice, media, code repos, automated workflows) built on the Nostr protocol, where **humans and AI agents work side by side**. Every participant — human or agent — has a cryptographic identity that is portable across Nostr-compatible systems. Agents have defined permissions, can post, review code, run approved automations, and join audio huddles. It's model- and agent-agnostic (works with Claude Code, Codex, goose, or custom agents). Self-hostable or Block-hosted. Mobile apps exist.

**Why it fits this project:** we're already running an agent-first workflow (Hermes). Buzz gives the project an owned, open collaboration layer where agents participate as first-class members — and later, a home for playtesters and community that isn't locked to a proprietary platform.

**Integration roadmap (honest about maturity — Buzz is brand new):**

| When | What we do with Buzz |
|---|---|
| Phase 0–1 (now) | **Pilot:** create a Buzz community (hosted or self-hosted), set up channels (design / dev / marketing / build-log). Keep `C:\Users\hugob\game-project` + git as the source of truth — Buzz is the collaboration layer, not the vault. |
| Phase 2–4 (production) | **Dev workflow:** agents post build logs, review code, triage playtest bug reports in Buzz; connect codebase/db access with permissions. **Git hosting in Buzz is officially "still early"** — keep the repo on GitHub/local until stable, then evaluate moving repos in. |
| Phase 5–7 (community/launch) | **Community & marketing:** public Buzz community for devlogs, wishlist campaign chatter, playtester coordination; agents handle Q&A triage and feedback aggregation. |

**Open decisions:** hosted (buzz.xyz) vs self-hosted instance; whether Hermes should join the Buzz workspace as an agent (it's agent-agnostic, so that's compatible) or whether Buzz is only for other tools/people.

**Risks:** brand-new platform, early Git integration, Nostr relay reliability — mitigated by keeping GitHub + local files canonical.

---

## Concept Brief (Phase 0 — locked decisions)

- **Genre:** 2D action RPG, souls-like — PVE, leveling/progression, bosses, story. No multiplayer.
- **Team:** solo. **Experience:** none (first game ever).
- **Budget:** €100–300/month available; free tools first, spend only where it matters (art tools, asset packs, music, Steam Direct fee).
- **Engine (recommended):** **Godot 4** — free, open source, no revenue share, excellent 2D tooling, GDScript is beginner-friendly. Not yet installed.
- **Scope guardrails (non-negotiable for a solo first-timer):**
  - One interconnected world — not sprawling; 6–8 bosses max
  - Story via NPCs + item descriptions (souls-style) — minimal cutscenes (they're expensive)
  - Placeholder art in prototype; final style locked at vertical slice
  - Realistic timeline: 12–24 months; **prototype decides viability first** (combat feel is the #1 risk)
- **References to study:** Hollow Knight, Blasphemous, Salt & Sanctuary, Death's Door, Grime.

---

## Open Questions (remaining)

1. **Setting / hook — v1 PARKED (2026-08-01):** "Lighthouse Keeper" open-world souls-like ("The Last Beacon") — light/flame twist cut by two playtests (too dark, resource pressure not fun). Autopsy: design/01-one-page-pitch.md + design/02-game-design-doc.md.
2. **CONCEPT v2 LOCKED (2026-08-01):** "The Last Beacon" — **boss-gauntlet roguelike** (Furi × Hades), dark epic tone, readable arenas. **The hero is the last world defence** (keeper/lighthouse lore retired same day by user decision — nothing keeper-related remains). Hero + greatsword + title kept. Bosses: the Captain, the Bastion, the Fallen Beacon, the Hollow Choir, the Bell of the Last Hour, the Night. Currency: shards. Pitch: design/03-boss-gauntlet-pitch.md.
3. Buzz: hosted or self-hosted? Should Hermes join your Buzz workspace as an agent, or is Buzz for other people/agents only?

---

## Next Steps

- [x] Answer Phase 0 questions (genre, team, experience, scope, budget)
- [x] Pick concept direction (hook) → one-page pitch complete (design/01-one-page-pitch.md)
- [x] Install Godot 4.7.1 + git, `dev/` repo set up (C:\Users\hugob\tools\godot)
- [ ] Create Buzz pilot community + channels (Phase 0/1)
- [x] Engine drills: [x] Drill 1 (playable slice) · [x] Drill 2 (editor — build your cave, dev/TheLastBeacon/DRILL2.md) · [x] Drill 3 (camera + bigger world, dev/TheLastBeacon/DRILL3.md)
- [x] Permanent headless test suite (dev/TheLastBeacon/tests/ — `bash tests/run_tests.sh`, 7 tests: captain, combat, death_loop, movement, platforms, roll, run)
- [x] Pre-commit hook installed (`bash scripts/install-hooks.sh`) + GitHub Actions workflow — **verified green on first push** (repo: github.com/hugoborgplotnikov-boop/the-last-beacon, 2026-08-01)
- [x] Write GDD v1 (design/02-game-design-doc.md — 6 bosses, 4 layers, fuel system, scope guardrails)
- [ ] Prototype: combat feel → first boss
