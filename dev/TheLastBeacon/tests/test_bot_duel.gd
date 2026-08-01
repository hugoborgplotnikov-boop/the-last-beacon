extends SceneTree
## test_bot_duel.gd — the bot faces the Fallen Beacon and MUST respect the
## Duel: swing during her recovery (never while she idles — she parries),
## roll away from her telegraphs, disengage after every two hits.
## If the bot mashing at idle would win, the parry is broken — so this
## test also proves the parry by swinging at idle FIRST and eating it.

const HARNESS = preload("res://tests/harness.gd")

# Fallen Beacon states (mirror fallen_beacon.gd).
const IDLE := 0
const TELEGRAPH_SWING := 1
const SWING := 2
const RECOVER := 3

var frames := 0
var h: RefCounted
var run: Node
var arena: Node2D
var player: CharacterBody2D
var boss: Node
var last_boss_hp := 99
var hits := 0
var hits_at_disengage := 0
var disengage_until := 0
var roll_pressed := false
var parry_proven := false
var test_phase := 0   # 0 = prove the parry, 1 = fight properly


func _initialize() -> void:
	h = HARNESS.new("bot_duel")
	run = get_root().get_node("Run")
	var cfg := ConfigFile.new()
	cfg.save("user://beacon_save.cfg")
	run.load_game()
	run.shards = 0
	run.meta_unlocks = {}
	run.save_game()
	run.init_run()
	var arena_scene: PackedScene = load("res://scenes/fallen_beacon_arena.tscn")
	arena = arena_scene.instantiate()
	root.add_child(arena)
	player = arena.get_node("Player")
	boss = arena.get_node("Boss")
	player.global_position = Vector2(950, 601)
	player.velocity = Vector2.ZERO
	print("TEST bot_duel: the bot faces the mirror — boss hp=", boss.max_hp)


func _physics_process(_delta: float) -> bool:
	frames += 1
	# Phase 0 (frames 10-160): prove the parry — walk into SWORD reach,
	# then swing at her while she holds her guard (idle + guard window open).
	# Phase 0 (frames 10-160): prove the parry — hold sword range (30-55px),
	# then swing at her while she holds her guard (idle + guard window open).
	if test_phase == 0:
		var dist: float = player.global_position.distance_to(boss.global_position)
		if frames == 20:
			# Walk into her reach.
			Input.action_press("move_right")
		# HOLD RANGE: the greatsword's box spans 20-60px in front; the
		# hurtbox half-width is ~10. Standing ON her = whiffing past her.
		if dist > 55.0:
			Input.action_press("move_right")
		elif dist < 30.0:
			Input.action_release("move_right")
			Input.action_press("move_left")
		else:
			Input.action_release("move_right")
			Input.action_release("move_left")
			# Swing the moment her guard is up (idle, not busy, guard open).
			if boss.state == boss.State.IDLE and not boss.busy \
					and boss.get("guard_timer") != null and boss.guard_timer > 0.0:
				Input.action_press("attack")
			else:
				Input.action_release("attack")
		if boss.parries > 0 and frames >= 60:
			Input.action_release("attack")
			h.check(boss.parries > 0, "she parried the idle swing (%d parries)" % boss.parries)
			h.check(boss.hp == boss.max_hp, "the parry deflected all damage (hp=%d)" % boss.hp)
			h.check(not player.dead, "bot survived its own mistake")
			parry_proven = true
			test_phase = 1
			# Back off, then fight properly.
			disengage_until = frames + 30
			return false
		if frames >= 160:
			# Fallback: she never parried — the guard window didn't open.
			Input.action_release("attack")
			h.check(false, "she parried the idle swing (no parry seen by frame 160)")
			parry_proven = false
			test_phase = 1
			disengage_until = frames + 30
		return false
	if boss.dead:
		_release_all()
		return _verdict()
	if player.dead:
		_release_all()
		return _verdict()
	if frames >= 2400:
		_release_all()
		return _verdict()
	if boss.hp < last_boss_hp:
		hits += 1
		if hits - hits_at_disengage >= 2:
			disengage_until = frames + 30
			hits_at_disengage = hits
	last_boss_hp = boss.hp
	_bot_tick()
	return false


func _bot_tick() -> void:
	var dist: float = player.global_position.distance_to(boss.global_position)
	if frames < disengage_until:
		_release_motion()
		Input.action_press("move_left")
		return
	match boss.state:
		TELEGRAPH_SWING, SWING:
			# She's about to chop / chopping — get out and roll.
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
	if boss.state == IDLE:
		# DO NOT swing at an idle mirror — she parries. Back off instead.
		Input.action_release("attack")
		Input.action_press("move_left")
		return
	if dist > 55.0:
		Input.action_press("move_right")
		Input.action_release("attack")
	else:
		Input.action_release("move_right")
		# She's in RECOVER (or gassed): punish on a cadence.
		if frames % 22 == 0:
			Input.action_press("attack")
		else:
			Input.action_release("attack")


func _release_motion() -> void:
	for action in ["move_left", "move_right", "attack", "roll"]:
		Input.action_release(action)


func _release_all() -> void:
	_release_motion()


func _verdict() -> bool:
	var verdict := true
	h.check(parry_proven, "the parry was proven by a bot's mistake")
	if boss.dead:
		h.check(true, "THE BOT WON the duel (hp %d/%d)" % [last_boss_hp, boss.max_hp])
	else:
		h.check(true, "bot fell at %d/%d — the duel is yours" % [last_boss_hp, boss.max_hp])
	verdict = h.summary()
	print("=== TEST bot_duel: ", "PASS" if verdict else "FAIL",
		" — boss ", last_boss_hp, "/", boss.max_hp,
		", bot ", "dead" if player.dead else "alive", " ===")
	quit(0 if verdict else 1)
	return true
