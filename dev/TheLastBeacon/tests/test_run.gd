extends SceneTree
## test_run.gd — the roguelike contract: the card pool, draws, buff
## accumulation and application, salt, lap scaling, and the run restart on
## death (salt survives). Deterministic: logic-level checks + arena
## instantiations (no input simulation).

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var h: RefCounted
var run: Node
var arena1: Node2D
var arena2: Node2D
var player1: CharacterBody2D


func _initialize() -> void:
	h = HARNESS.new("run")
	run = get_root().get_node("Run")
	run.init_run()
	h.check(run.CARDS.size() >= 9, "card pool has >= 9 cards (%d)" % run.CARDS.size())
	var picks: Array = run.draw_cards(3)
	h.check(picks.size() == 3, "draw gives 3 cards")
	var distinct: Dictionary = {}
	for p in picks:
		distinct[p] = true
	h.check(distinct.size() == 3, "drawn cards are distinct")
	h.check(run.card_info(picks[0]).has("title") and run.card_info(picks[0]).has("desc"),
		"cards carry title + description")
	# Buffs accumulate per run.
	run.apply_card("tempered_steel")
	run.apply_card("keepers_vigor")
	h.check(run.buffs.get("damage") == 1 and run.buffs.get("hp") == 1, "buffs recorded")
	# Salt accumulates per victory.
	run.record_victory()
	h.check(run.salt == 3, "victory grants 3 salt")
	print("TEST run: pool+draws+buffs+salt ok — spawning arenas")


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			# The arena applies the run state: keeper buffs + boss lap scaling.
			var arena_scene: PackedScene = load("res://scenes/captain_arena.tscn")
			arena1 = arena_scene.instantiate()
			root.add_child(arena1)
			player1 = arena1.get_node("Player")
			var boss1: Node2D = arena1.get_node("Boss")
			h.check(player1.attack_damage == 2, "keeper's damage buff applied (+1 -> %d)" % player1.attack_damage)
			h.check(player1.max_health == 6, "keeper's vigor applied (+1 -> %d)" % player1.max_health)
			h.check(player1.health == player1.max_health, "buffs heal to the new max")
			h.check(boss1.max_hp == 10, "lap-1 boss is unscaled (hp=%d)" % boss1.max_hp)
			h.check(arena1.run_label.text.contains("Lap 1"), "HUD shows the lap")
		20:
			# Lap 2: the boss scales up.
			run.lap = 2
			var arena_scene: PackedScene = load("res://scenes/captain_arena.tscn")
			arena2 = arena_scene.instantiate()
			root.add_child(arena2)
			var boss2: Node2D = arena2.get_node("Boss")
			h.check(boss2.max_hp == 12, "lap-2 captain is scaled (+2 hp -> %d)" % boss2.max_hp)
		40:
			# Death ends the run and restarts it fresh; salt survives.
			# (die() is deferred ~0.9s, then 2.5s run-over -> restart ~245.)
			player1.take_damage(99, player1.global_position + Vector2(10, 0))
		300:
			h.check(run.run_active, "run restarted after death")
			h.check(run.lap == 1, "restart resets to lap 1")
			h.check(run.buffs.is_empty(), "restart clears the run buffs")
			h.check(run.salt == 3, "salt survived the death")
			quit(0 if h.summary() else 1)
	return false
