extends Area2D

## An ember — a fragment of drowned light. Pick it up: it heals and counts toward
## your embers. This is the seed of the souls-style currency.

var t := 0.0
var base_y := 0.0


func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	t += delta
	position.y = base_y + sin(t * 3.0) * 4.0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.add_embers(1)
		body.heal(1)
		queue_free()
