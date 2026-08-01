extends SceneTree
## test_fallen_beacon.gd — boss #3's fight contract, the MIRROR fight:
## she fights autonomously with her greatsword (a real arc hitbox that
## damages the hero), she ROLLS like the hero — with real i-frames (her
## hurtbox goes dormant mid-roll), she enters phase 2 at half health, and
## she dies into the victory beat (shards + cards). Seed 8: her first
## attack is the roll, observed live. Deterministic.

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var player: CharacterBody2D
var boss: Node
var arena: Node2D
var h: RefCounted
var run: Node
var roll_iframes_seen := false


func _initialize() -> void:
	h = HARNESS.new("fallen_beacon")
	run = get_root().get_node("Run")
	# Clean slate: wipe the save so the test is deterministic.
	var cfg := ConfigFile.new()
	cfg.save("user://beacon_save.cfg")
	run.load_game()
	run.shards = 0
	run.meta_unlocks = {}
	run.save_game()
	run.init_run()
	seed(8)
	var arena_scene: PackedScene = load("res://scenes/fallen_beacon_arena.tscn")
	arena = arena_scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")
	print("TEST fallen_beacon: the mirror awakens — boss hp=", boss.max_hp, " at ", boss.global_position)


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		10:
			# Close enough for her to engage (she attacks within 180).
			player.global_position = Vector2(1050, 601)
			player.velocity = Vector2.ZERO
		40:
			# Seed 8: her first attack is the ROLL (the mirror dodge).
			h.check(boss.attack_count == 1, "she engaged on her own (%d attacks)" % boss.attack_count)
			h.check(boss.roll_count == 1, "her first move is the roll (mirror dodge)")
		90:
			# Feed her a clean approach: park the hero in front of her.
			player.global_position = Vector2(boss.global_position.x - 90, 601)
			player.velocity = Vector2.ZERO
		250:
			h.check(boss.attack_count >= 2, "she fights autonomously (%d attacks)" % boss.attack_count)
			h.check(player.health < 5, "her greatsword lands real hits (hero %d/5)" % player.health)
			h.check(roll_iframes_seen, "her roll has i-frames (hurtbox dormant mid-roll)")
		260:
			# Direct-damage contract: phase 2 at half health, death at zero.
			boss.take_damage(99, boss.global_position + Vector2(10, 0))
		290:
			h.check(boss.phase == 2, "she entered phase 2 as she fell below half")
			h.check(boss.dead, "she fell to the hero's greatsword")
			h.check(not boss.body.visible, "her body hidden after death")
			h.check(arena.victory_label.visible, "victory beat shown")
			h.check(run.shards == 3, "victory granted 3 shards (shards=%d)" % run.shards)
			h.check(arena.card_panel.visible, "upgrade cards offered")
			h.check(not arena.boss_bar_bg.visible, "boss bar hides on death")
		300:
			# REGRESSION: a second lethal hit must not double-award.
			boss.take_damage(1, boss.global_position + Vector2(10, 0))
		315:
			h.check(boss.dead, "still dead after the second hit")
			h.check(run.shards == 3, "no double award (shards=%d)" % run.shards)
			quit(0 if h.summary() else 1)
	# Live observation: catch her mid-roll and verify the mirror i-frames.
	if boss.state == boss.State.ROLL and not roll_iframes_seen:
		roll_iframes_seen = not boss.hurt_box.monitoring
	return false
