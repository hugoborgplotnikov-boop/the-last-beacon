extends Node

## Run — the gauntlet's brain (autoload). Holds the run state (lap, salt,
## buffs), the boss rotation, and the upgrade-card pool. Arenas read the run
## state in _ready and report victories/deaths back here.

const BOSS_ROTATION: Array[String] = [
	"res://scenes/captain_arena.tscn",
	"res://scenes/tidesworn_arena.tscn",
]

## Card pool: id -> {title, desc, buffs} — buffs accumulate per run and are
## applied to the keeper by the arena's _ready.
const CARDS := {
	"tempered_steel": {"title": "Tempered Steel", "desc": "+1 damage per swing", "buffs": {"damage": 1}},
	"keepers_vigor": {"title": "Keeper's Vigor", "desc": "+1 max health", "buffs": {"hp": 1}},
	"stamina_well": {"title": "Stamina Well", "desc": "+25 max stamina", "buffs": {"stamina": 25.0}},
	"second_wind": {"title": "Second Wind", "desc": "attacks cost 5 less stamina", "buffs": {"stamina_discount": 5.0}},
	"lifeleech": {"title": "Lifeleech", "desc": "every hit heals 1 HP", "buffs": {"lifesteal": 1}},
	"swift": {"title": "Swift", "desc": "+15% move speed", "buffs": {"speed": 33.0}},
	"lighter_blade": {"title": "Lighter Blade", "desc": "swings 0.08s faster", "buffs": {"cooldown": 0.08}},
	"deep_breath": {"title": "Deep Breath", "desc": "+50% stamina regen", "buffs": {"regen": 0.5}},
	"giants_reach": {"title": "Giant's Reach", "desc": "+20% attack range", "buffs": {"reach": 0.2}},
}

var lap := 1
var salt := 0
var boss_index := 0
var buffs: Dictionary = {}
var run_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func init_run() -> void:
	lap = 1
	boss_index = 0
	buffs = {}
	run_active = true


func current_arena() -> String:
	return BOSS_ROTATION[boss_index]


func record_victory() -> void:
	salt += 3


func record_death() -> void:
	run_active = false


func advance() -> void:
	boss_index += 1
	if boss_index >= BOSS_ROTATION.size():
		boss_index = 0
		lap += 1
	get_tree().change_scene_to_file(current_arena())


func restart_run() -> void:
	init_run()
	get_tree().change_scene_to_file(BOSS_ROTATION[0])


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
