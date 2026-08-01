extends SceneTree
## test_shop.gd — the meta-layer contract (the shop UI is resting; the
## wallet, purchases, persistence, and run-folding logic live on in run.gd
## for when the shop returns): affordability and caps are enforced, the
## wallet persists to disk, and init_run folds permanent unlocks into every
## fresh run. The game currently boots into the main menu.
## Deterministic: starts from a wiped save file.

const HARNESS = preload("res://tests/harness.gd")
const SAVE := "user://beacon_save.cfg"

var frames := 0
var h: RefCounted
var run: Node
var menu: Control


func _initialize() -> void:
	h = HARNESS.new("shop")
	run = get_root().get_node("Run")
	# Clean slate: wipe the save so the test is deterministic.
	var cfg := ConfigFile.new()
	cfg.save(SAVE)
	run.load_game()
	run.shards = 0
	run.meta_unlocks = {}
	run.save_game()
	# Purchases spend the wallet and enforce affordability.
	h.check(run.purchase("fortitude") == false, "can't buy with 0 shards")
	run.shards = 12
	h.check(run.purchase("fortitude"), "heart bought (6)")
	h.check(run.purchase("fortitude"), "heart bought again (6)")
	h.check(run.shards == 0, "wallet spent down (0)")
	h.check(run.purchase("fortitude") == false, "can't buy what you can't afford")
	h.check(run.meta_unlocks.get("fortitude", 0) == 2, "unlock count recorded (2)")
	# One-time items cap at 1.
	run.shards = 100
	h.check(run.purchase("memory"), "warrior's memory bought")
	h.check(run.purchase("memory") == false, "one-time item capped")
	# Persistence: a fresh load sees the same wallet and unlocks.
	run.shards = 7
	run.save_game()
	run.shards = 0
	run.meta_unlocks = {}
	run.load_game()
	h.check(run.shards == 7, "wallet survives reload (7)")
	h.check(run.meta_unlocks.get("fortitude", 0) == 2, "unlocks survive reload (2)")
	# init_run folds unlocks into the run (plus the memory starter card;
	# seeded so the random draw is deterministic — seed 7 draws Lifeleech).
	seed(7)
	run.init_run()
	h.check(run.buffs.get("hp", 0) >= 2, "meta hp buff in the run (>=2)")
	h.check(run.buffs.get("lifesteal", 0) == 1, "starter card folded in (Lifeleech)")
	# Deep Pockets: +3 shards per victory on top of the base 3.
	run.shards = 8
	h.check(run.purchase("pockets"), "deep pockets bought")
	run.shards = 0
	run.record_victory()
	h.check(run.shards == 6, "pockets victory pays 6 (3+3)")
	# The main menu exists and exposes its controls.
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	menu = menu_scene.instantiate()
	root.add_child(menu)
	print("TEST shop: wallet+purchases+persistence+meta ok — checking the menu")


func _physics_process(_delta: float) -> bool:
	frames += 1
	match frames:
		5:
			h.check(menu.get_node("UI/StartButton") != null, "menu has the start button")
			h.check(menu.get_node("Title") != null, "menu has the title")
			h.check(menu.get_node("UI/StartButton").text == "START NEW GAME",
				"start button says START NEW GAME")
			quit(0 if h.summary() else 1)
	return false
