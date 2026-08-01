extends Control
## The main menu — the game boots here. One choice: START NEW GAME.
## (The shards shop is resting; its save plumbing lives on in run.gd.)

@onready var start_button: Button = $UI/StartButton
@onready var cleared_label: Label = $ClearedLabel


func _ready() -> void:
	Music.play("menu")
	start_button.grab_focus()
	# The world remembers: a cleared gauntlet is written on the menu.
	var clears: int = Run.meta_unlocks.get("clears", 0)
	if clears > 0:
		cleared_label.text = "GAUNTLET CLEARED × %d" % clears
		cleared_label.visible = true


func _on_start_pressed() -> void:
	Sfx.play("select", -6.0)
	Run.init_run()
	Fx.transition_to("res://scenes/captain_arena.tscn")
