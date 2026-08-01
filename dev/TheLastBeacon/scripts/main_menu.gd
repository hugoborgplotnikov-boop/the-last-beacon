extends Control
## The main menu — the game boots here. One choice: START NEW GAME.
## (The shards shop is resting; its save plumbing lives on in run.gd.)

@onready var start_button: Button = $UI/StartButton


func _ready() -> void:
	start_button.grab_focus()


func _on_start_pressed() -> void:
	Sfx.play("select", -6.0)
	Run.init_run()
	Fx.transition_to("res://scenes/captain_arena.tscn")
