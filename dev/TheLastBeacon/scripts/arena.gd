extends Node2D

## The Captain's arena — the first fight of the descent. HUD, death reset
## (the fight restarts when the keeper falls), and the victory beat.

@onready var player: CharacterBody2D = $Player
@onready var captain: CharacterBody2D = $Captain
@onready var hp_label: Label = $UI/HP
@onready var stamina_fill: ColorRect = $UI/StaminaBG/Fill
@onready var death_label: Label = $UI/DeathLabel
@onready var victory_label: Label = $UI/VictoryLabel


func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.died.connect(_on_player_died)
	captain.died.connect(_on_captain_died)
	_on_health_changed(player.health)
	_on_stamina_changed(player.stamina)
	# The arena is 0..1400 — clamp the keeper's camera to it.
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_right = 1400
	cam.limit_top = 0
	cam.limit_bottom = 720


func _on_health_changed(hp: int) -> void:
	hp_label.text = "♥".repeat(maxi(hp, 0)) + "♡".repeat(maxi(player.max_health - hp, 0))


func _on_stamina_changed(value: float) -> void:
	stamina_fill.size.x = 200.0 * clampf(value / player.max_stamina, 0.0, 1.0)


func _on_player_died() -> void:
	death_label.visible = true
	await get_tree().create_timer(2.0).timeout
	captain.reset_state()
	player.reset()
	death_label.visible = false


func _on_captain_died() -> void:
	victory_label.visible = true
