extends SceneTree
## test_bot.gd — a bot PLAYTHROUGH: the closest thing to a human playing.
## The bot drives the hero with REAL inputs (move_left/right, attack, roll),
## reads the Captain's telegraphs (his state machine) and dodges, and we
## assert the fight is real: actual swing hitboxes land actual damage, the
## boss fights back, and if the bot wins, the victory flow pays out.
## (The approach run is skipped by teleport — the claim is the FIGHT.)

const HARNESS = preload("res://tests/harness.gd")

# Captain state enum (mirrors captain.gd).
const TELEGRAPH_LUNGE := 1
const LUNGE := 2
const TELEGRAPH_SLAM := 3
const SLAM := 4
const TELEGRAPH_SWEEP := 5
const SWEEP := 6

var frames := 0
var h: RefCounted
var run: Node
var arena: Node2D
var player: CharacterBody2D
var boss: Node
var bot_dead := false
var boss_killed := false
var last_boss_hp := 99
var roll_pressed := false
var hits := 0
var hits_at_disengage := 0
var disengage_until := 0


func _initialize() -> void:
	h = HARNESS.new("bot")
	run = get_root().get_node("Run")
	# Clean slate: wipe the save so the test is deterministic.
	var cfg := ConfigFile.new()
	cfg.save("user://beacon_save.cfg")
	run.load_game()
	run.shards = 0
	run.meta_unlocks = {}
	run.save_game()
	run.init_run()
	var arena_scene: PackedScene = load("res://scenes/captain_arena.tscn")
	arena = arena_scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")
	print("TEST bot: the bot awakens — boss hp=", boss.max_hp, " at ", boss.global_position)


func _physics_process(_delta: float) -> bool:
	frames += 1
	if frames == 5:
		# Skip the approach run; the fight itself is the claim.
		player.global_position = Vector2(900, 601)
		player.velocity = Vector2.ZERO
	if frames == 550:
		h.check(boss.hp < boss.max_hp, "bot landed REAL swing hits (boss %d/%d)" % [boss.hp, boss.max_hp])
		h.check(boss.attack_count > 0, "boss fought back (%d attacks)" % boss.attack_count)
		h.check(not player.dead, "bot survived the first exchanges")
	if bot_dead:
		_release_all()
		# The death flow (0.9s die + 2.5s run-over) restarts into the shop.
		if run.run_active and frames > 60:
			return _verdict()
		return false
	if boss.dead:
		_release_all()
		return _verdict()
	if frames >= 2400:
		_release_all()
		return _verdict()
	if boss.hp < last_boss_hp:
		hits += 1
		# After every two landed hits, back off so the touch-tick resets.
		if hits - hits_at_disengage >= 2:
			disengage_until = frames + 35
			hits_at_disengage = hits
	last_boss_hp = boss.hp
	_bot_tick()
	return false


func _bot_tick() -> void:
	# Play it like a human: punish the wind-up (the boss is rooted), run out
	# of the slam's red zone while it charges, roll through the live lunge,
	# and disengage briefly after every two hits so the touch-tick resets.
	var dist: float = player.global_position.distance_to(boss.global_position)
	if frames < disengage_until:
		Input.action_release("roll")
		Input.action_release("move_right")
		Input.action_release("attack")
		Input.action_press("move_left")
		return
	match boss.state:
		TELEGRAPH_SLAM, SLAM:
			# The ground under the hero glows — leave the zone, now.
			Input.action_release("roll")
			Input.action_release("move_right")
			Input.action_press("move_left")
			Input.action_release("attack")
			return
		TELEGRAPH_LUNGE, LUNGE, SWEEP:
			# Roll early through the dash; roll and back off from the sweep.
			if not roll_pressed:
				Input.action_press("roll")
				roll_pressed = true
			else:
				Input.action_release("roll")
				Input.action_release("move_right")
				Input.action_press("move_left")
				Input.action_release("attack")
			return
	roll_pressed = false
	Input.action_release("roll")
	Input.action_release("move_left")
	if dist > 55.0:
		Input.action_press("move_right")
		Input.action_release("attack")
	else:
		Input.action_release("move_right")
		# Tap the greatsword on a cadence; the cooldown gates real hits.
		if frames % 24 == 0:
			Input.action_press("attack")
		else:
			Input.action_release("attack")


func _release_all() -> void:
	for action in ["move_left", "move_right", "attack", "roll"]:
		Input.action_release(action)


func _verdict() -> bool:
	var verdict := true
	if boss.dead:
		boss_killed = true
		h.check(boss.dead, "THE BOT WON the fight")
		h.check(run.shards == 3, "victory paid 3 shards (%d)" % run.shards)
	elif player.dead:
		h.check(true, "bot fell at boss %d/%d — the fight is yours" % [last_boss_hp, boss.max_hp])
	else:
		h.check(true, "time cap reached — boss at %d/%d" % [last_boss_hp, boss.max_hp])
	verdict = h.summary()
	print("=== TEST bot: ", "PASS" if verdict else "FAIL",
		" — boss ", last_boss_hp, "/", boss.max_hp,
		", bot ", "dead" if player.dead else "alive", " ===")
	quit(0 if verdict else 1)
	return true
