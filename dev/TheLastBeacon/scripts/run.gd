extends Node

## Run — the gauntlet's brain (autoload). Holds the run state (lap, shards,
## buffs), the boss rotation, the upgrade-card pool, and the meta layer
## (the shards shop + the save file). Arenas read the run state in _ready
## and report victories and deaths back here.

const BOSS_ROTATION: Array[String] = [
	"res://scenes/captain_arena.tscn",
	"res://scenes/bastion_arena.tscn",
	"res://scenes/fallen_beacon_arena.tscn",
	"res://scenes/choir_arena.tscn",
	"res://scenes/bell_arena.tscn",
	"res://scenes/night_arena.tscn",
]

const SHOP_SCENE := "res://scenes/shop.tscn"
const SAVE_PATH := "user://beacon_save.cfg"

## Card pool: id -> {title, desc, buffs} — buffs accumulate per run and are
## applied to the hero by the arena's _ready.
const CARDS := {
	"tempered_steel": {"title": "Tempered Steel", "desc": "+1 damage per swing", "buffs": {"damage": 1}},
	"heros_vigor": {"title": "Hero's Vigor", "desc": "+1 max health", "buffs": {"hp": 1}},
	"stamina_well": {"title": "Stamina Well", "desc": "+25 max stamina", "buffs": {"stamina": 25.0}},
	"second_wind": {"title": "Second Wind", "desc": "attacks cost 5 less stamina", "buffs": {"stamina_discount": 5.0}},
	"lifeleech": {"title": "Lifeleech", "desc": "every hit heals 1 HP", "buffs": {"lifesteal": 1}},
	"swift": {"title": "Swift", "desc": "+15% move speed", "buffs": {"speed": 33.0}},
	"lighter_blade": {"title": "Lighter Blade", "desc": "swings 0.08s faster", "buffs": {"cooldown": 0.08}},
	"deep_breath": {"title": "Deep Breath", "desc": "+50% stamina regen", "buffs": {"regen": 0.5}},
	"giants_reach": {"title": "Giant's Reach", "desc": "+20% attack range", "buffs": {"reach": 0.2}},
	"veterans_grip": {"title": "Veteran's Grip", "desc": "+1 damage, swings cost 2 less", "buffs": {"damage": 1, "stamina_discount": 2.0}},
	"iron_will": {"title": "Iron Will", "desc": "+1 max health, +10 stamina", "buffs": {"hp": 1, "stamina": 10.0}},
	"flurry": {"title": "Flurry", "desc": "swings 0.04s faster, +5% speed", "buffs": {"cooldown": 0.04, "speed": 11.0}},
	"juggernaut": {"title": "Juggernaut", "desc": "+1 max health, +5% speed", "buffs": {"hp": 1, "speed": 11.0}},
	"titan_slayer": {"title": "Titan Slayer", "desc": "+1 damage, +10% reach", "buffs": {"damage": 1, "reach": 0.1}},
	"blood_rush": {"title": "Blood Rush", "desc": "lifesteal 1, +10% speed", "buffs": {"lifesteal": 1, "speed": 22.0}},
	"unbroken": {"title": "Unbroken", "desc": "+15 stamina, +20% regen", "buffs": {"stamina": 15.0, "regen": 0.2}},
	"precision": {"title": "Precision", "desc": "swings 0.04s faster, +10% reach", "buffs": {"cooldown": 0.04, "reach": 0.1}},
	"war_dance": {"title": "War Dance", "desc": "swings cost 3 less, +10 speed", "buffs": {"stamina_discount": 3.0, "speed": 22.0}},
	"last_stand": {"title": "Last Stand", "desc": "+2 max health, -0.04s cooldown", "buffs": {"hp": 2, "cooldown": 0.04}},
	"reapers_edge": {"title": "Reaper's Edge", "desc": "+1 damage, lifesteal 1", "buffs": {"damage": 1, "lifesteal": 1}},
}

## The shop: id -> {title, desc, cost, max} — permanent unlocks bought with
## shards between runs. Effects fold into every fresh run via init_run.
const SHOP := {
	"fortitude": {"title": "Heart of the First Line", "desc": "+1 max health", "cost": 6, "max": 5},
	"blade": {"title": "Tempered Heritage", "desc": "+1 damage", "cost": 8, "max": 3},
	"stamina": {"title": "Endurance of the Fallen", "desc": "+25 max stamina", "cost": 6, "max": 3},
	"memory": {"title": "Warrior's Memory", "desc": "start each run with a free card", "cost": 10, "max": 1},
	"pockets": {"title": "Deep Pockets", "desc": "+3 shards per victory", "cost": 8, "max": 1},
}

var lap := 1
var shards := 0
var boss_index := 0
var buffs: Dictionary = {}
var run_active := false
var meta_unlocks: Dictionary = {}
var run_started_at := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


func init_run() -> void:
	lap = 1
	boss_index = 0
	buffs = {}
	run_active = true
	run_started_at = Time.get_ticks_msec()
	# Permanent unlocks fold into the run's buffs (applied by the arena).
	for id in meta_unlocks:
		var n: int = meta_unlocks[id]
		match id:
			"fortitude":
				buffs["hp"] = buffs.get("hp", 0) + n
			"blade":
				buffs["damage"] = buffs.get("damage", 0) + n
			"stamina":
				buffs["stamina"] = buffs.get("stamina", 0) + 25.0 * n
			"memory":
				if n > 0:
					apply_card(_starter_card())


func current_arena() -> String:
	return BOSS_ROTATION[boss_index]


func record_victory() -> void:
	shards += 3
	if meta_unlocks.get("pockets", 0) > 0:
		shards += 3
	save_game()


func record_death() -> void:
	run_active = false
	save_game()


func advance() -> void:
	boss_index += 1
	if boss_index >= BOSS_ROTATION.size():
		boss_index = 0
		lap += 1
	Fx.transition_to(current_arena())


## The last boss stands at the end of the rotation.
func is_final_boss() -> bool:
	return boss_index == BOSS_ROTATION.size() - 1


## The gauntlet is broken: the run ends in victory, the save remembers.
func clear_gauntlet() -> void:
	meta_unlocks["clears"] = int(meta_unlocks.get("clears", 0)) + 1
	run_active = false
	save_game()


## How long this run has been going, in seconds.
func run_time_seconds() -> int:
	return int((Time.get_ticks_msec() - run_started_at) / 1000.0)


## The run is over: back to the main menu with the wallet intact.
func restart_run() -> void:
	init_run()
	save_game()
	Fx.transition_to(SHOP_SCENE)


func draw_cards(count := 3) -> Array[String]:
	var ids: Array[String] = []
	for id in CARDS:
		ids.append(id)
	ids.shuffle()
	return ids.slice(0, count)


func card_info(id: String) -> Dictionary:
	return CARDS[id]


func apply_card(id: String) -> void:
	var card_buffs: Dictionary = CARDS[id]["buffs"]
	for key in card_buffs:
		buffs[key] = buffs.get(key, 0) + card_buffs[key]


func _starter_card() -> String:
	var ids: Array[String] = draw_cards(1)
	return ids[0]


func purchase(id: String) -> bool:
	if not SHOP.has(id):
		return false
	var item: Dictionary = SHOP[id]
	if meta_unlocks.get(id, 0) >= item["max"]:
		return false
	if shards < item["cost"]:
		return false
	shards -= item["cost"]
	meta_unlocks[id] = meta_unlocks.get(id, 0) + 1
	save_game()
	return true


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "shards", shards)
	cfg.set_value("meta", "unlocks", meta_unlocks)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	shards = cfg.get_value("meta", "shards", 0)
	meta_unlocks = cfg.get_value("meta", "unlocks", {})
