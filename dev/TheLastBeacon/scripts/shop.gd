extends Control
## The shards shop — the between-runs hub. Spend shards on permanent
## unlocks (they persist in the save file and fold into every fresh run),
## then start the gauntlet again. Death returns here; START returns to it.

@onready var balance_label: Label = $UI/BalanceLabel
@onready var unlock_buttons: Array[Button] = [
	$UI/Panel/Grid/Unlock1,
	$UI/Panel/Grid/Unlock2,
	$UI/Panel/Grid/Unlock3,
	$UI/Panel/Grid/Unlock4,
	$UI/Panel/Grid/Unlock5,
]
@onready var begin_button: Button = $UI/BeginButton

const UNLOCK_ORDER: Array[String] = ["fortitude", "blade", "stamina", "memory", "pockets"]


func _ready() -> void:
	if not Run.run_active:
		Run.load_game()
	Music.play("menu")
	_run_label()
	for i in UNLOCK_ORDER.size():
		var id: String = UNLOCK_ORDER[i]
		var item: Dictionary = Run.SHOP[id]
		var owned: int = Run.meta_unlocks.get(id, 0)
		var maxed: bool = owned >= item["max"]
		unlock_buttons[i].text = "%s — %s (%d/%d)\n%s" % [
			item["title"], str(item["cost"]), owned, item["max"], item["desc"]]
		unlock_buttons[i].disabled = maxed or Run.shards < item["cost"]
		unlock_buttons[i].pressed.connect(_on_unlock_pressed.bind(id))
	begin_button.grab_focus()


func _run_label() -> void:
	balance_label.text = "SHARDS: %d" % Run.shards


func _on_unlock_pressed(id: String) -> void:
	if Run.purchase(id):
		Sfx.play("select", -6.0)
		_run_label()
		# Refresh button states (a purchase can unlock affordability).
		for i in UNLOCK_ORDER.size():
			var item: Dictionary = Run.SHOP[UNLOCK_ORDER[i]]
			var owned: int = Run.meta_unlocks.get(UNLOCK_ORDER[i], 0)
			unlock_buttons[i].disabled = owned >= item["max"] or Run.shards < item["cost"]


func _on_begin_pressed() -> void:
	Sfx.play("select", -6.0)
	Run.init_run()
	Fx.transition_to(Run.current_arena())
