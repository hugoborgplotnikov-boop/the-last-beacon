extends Control
## The shards shop — the hub between runs. The hero's permanent unlocks
## live here: spend shards on them, then begin the gauntlet again.

@onready var balance_label: Label = $UI/BalanceLabel
@onready var item_list: VBoxContainer = $UI/ItemList


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	balance_label.text = "Shards: %d" % Run.shards
	for child in item_list.get_children():
		child.queue_free()
	for id in Run.SHOP:
		var item: Dictionary = Run.SHOP[id]
		var owned: int = Run.meta_unlocks.get(id, 0)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(560, 52)
		btn.text = "%s — %s — %d ◆" % [item["title"], item["desc"], item["cost"]]
		if owned > 0:
			btn.text += " (owned %d)" % owned
		if owned >= item["max"]:
			btn.text += " — MAXED"
			btn.disabled = true
		elif Run.shards < item["cost"]:
			btn.disabled = true
		btn.pressed.connect(_on_item_pressed.bind(id))
		item_list.add_child(btn)


func _on_item_pressed(id: String) -> void:
	if Run.purchase(id):
		_refresh()


func _on_begin_pressed() -> void:
	Run.init_run()
	get_tree().change_scene_to_file("res://scenes/captain_arena.tscn")
