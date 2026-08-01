extends SceneTree
## test_fallen_beacon.gd — boss #3's DUEL contract: she rolls with real
## i-frames, she PARSIES idle swings (and counters), she spends stamina and
## GASES when spent (wide open), she speaks, and she dies into the victory
## beat with her death line. Seed 8: her first attack is the roll.
## Deterministic: state-reacted pokes (no blind timing on the parry/kill).

const HARNESS = preload("res://tests/harness.gd")

var frames := 0
var player: CharacterBody2D
var boss: Node
var arena: Node2D
var h: RefCounted
var run: Node
var roll_iframes_seen := false
var parry_done := false
var gas_set := false
var killed := false
var regressed := false
var check_frame := -1


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
			h.check(arena.get_node_or_null("UI/DialogueLabel") != null, "she speaks before the duel")
		130:
			# Feed her a clean approach: park the hero in front of her.
			player.global_position = Vector2(boss.global_position.x - 90, 601)
			player.velocity = Vector2.ZERO
		150:
			h.check(boss.parries == 1, "she parried the idle swing")
			h.check(boss.hp == boss.max_hp, "the parry took no damage")
			h.check(roll_iframes_seen, "her roll has i-frames (hurtbox dormant mid-roll)")
			h.check(arena.boss_stamina_fill != null, "the duel shows her stamina bar")
		160:
			# Whiff her dry: force the gas and watch her stand wide open.
			boss.stamina = 5.0
			gas_set = true
		200:
			h.check(boss.stamina < 25.0, "she never swung while gassed (stam %.0f)" % boss.stamina)
		240:
			h.check(player.health < 5, "her greatsword lands real hits (hero %d/5)" % player.health)
			h.check(boss.attack_count >= 2, "she fights autonomously (%d attacks)" % boss.attack_count)
			h.check(arena.boss_stamina_fill.size.x < 296.0, "her stamina bar drains as she swings")
	# State-reacted poke: the parry needs her IDLE, the hero in reach.
	if not parry_done and frames > 50 and boss.state == boss.State.IDLE and not boss.busy \
			and boss.global_position.distance_to(player.global_position) < 180.0:
		parry_done = true
		boss.take_damage(1, boss.global_position + Vector2(10, 0))
		h.check(boss.parries == 1, "the idle swing was deflected")
		h.check(boss.state == boss.State.TELEGRAPH_SWING, "she counters immediately")
	# State-reacted kill: only strike during her recovery (the duel lesson).
	if not killed and frames > 260 and boss.state == boss.State.RECOVER:
		killed = true
		check_frame = frames + 20
		boss.take_damage(99, boss.global_position + Vector2(10, 0))
	if killed and frames >= check_frame and not regressed:
		h.check(boss.phase == 2, "she entered phase 2 as she fell below half")
		h.check(boss.dead, "she fell to the hero's greatsword")
		h.check(not boss.body.visible, "her body hidden after death")
		h.check(arena.victory_label.visible, "victory beat shown")
		h.check(arena.victory_label.text == "She nods. The light is yours now.",
			"her death line lands")
		h.check(run.shards == 3, "victory granted 3 shards (shards=%d)" % run.shards)
		h.check(arena.card_panel.visible, "upgrade cards offered")
		h.check(not arena.boss_bar_bg.visible, "boss bar hides on death")
		h.check(not arena.boss_stamina_bg.visible, "her stamina bar hides on death")
		# REGRESSION: a second lethal hit must not double-award.
		boss.take_damage(1, boss.global_position + Vector2(10, 0))
		regressed = true
		return false
	if killed and regressed and frames >= check_frame + 15:
		h.check(boss.dead, "still dead after the second hit")
		h.check(run.shards == 3, "no double award (shards=%d)" % run.shards)
		quit(0 if h.summary() else 1)
		return false
	# Live observation: catch her mid-roll and verify the mirror i-frames.
	if boss.state == boss.State.ROLL and not roll_iframes_seen:
		roll_iframes_seen = not boss.hurt_box.monitoring
	return false
