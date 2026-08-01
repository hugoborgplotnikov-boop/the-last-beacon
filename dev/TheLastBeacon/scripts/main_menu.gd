extends Control
## The main menu — the game boots here. One choice: START NEW GAME.
## (The shards shop is resting; its save plumbing lives on in run.gd.)

@onready var start_button: Button = $UI/StartButton


func _ready() -> void:
	start_button.grab_focus()


func _on_start_pressed() -> void:
	Run.init_run()
	get_tree().change_scene_to_file("res://scenes/captain_arena.tscn")
