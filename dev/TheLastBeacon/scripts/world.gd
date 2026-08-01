extends Node2D

## The training cave — where the hero first learned to fight.

@onready var player: CharacterBody2D = $Player
@onready var hp_label: Label = $UI/HP
@onready var stamina_fill: ColorRect = $UI/StaminaBG/Fill
@onready var death_label: Label = $UI/DeathLabel
@onready var enemies: Array[Node] = [$Enemy1, $Enemy2, $Enemy3, $Enemy4, $Enemy5]


func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.died.connect(_on_player_died)
	_on_health_changed(player.health)
	_on_stamina_changed(player.stamina)


func _on_health_changed(hp: int) -> void:
	hp_label.text = "♥".repeat(maxi(hp, 0)) + "♡".repeat(maxi(player.max_health - hp, 0))


func _on_stamina_changed(value: float) -> void:
	stamina_fill.size.x = 200.0 * clampf(value / player.max_stamina, 0.0, 1.0)


func _on_player_died() -> void:
	death_label.visible = true
	await get_tree().create_timer(2.0).timeout
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.reset_state()
	player.reset()
	death_label.visible = false
