extends Node2D

## A boss arena — one fight of the gauntlet. Wires the run (autoload Run) to
## the fight: the boss is scaled for the lap, the hero gets her buffs, a
## victory offers three upgrade cards, and a death ends the run.

@onready var player: CharacterBody2D = $Player
@onready var boss: Node2D = $Boss
@onready var hp_fill: ColorRect = $UI/HPBG/HPFill
@onready var stamina_fill: ColorRect = $UI/StaminaBG/Fill
@onready var hp_smooth := 5.0
@onready var death_label: Label = $UI/DeathLabel
@onready var victory_label: Label = $UI/VictoryLabel
@onready var run_label: Label = $UI/RunLabel
@onready var card_panel: VBoxContainer = $UI/CardPanel
@onready var card_buttons: Array[Button] = [$UI/CardPanel/Card1, $UI/CardPanel/Card2, $UI/CardPanel/Card3]
@onready var boss_bar_bg: ColorRect = $UI/BossBG
@onready var boss_bar_fill: ColorRect = $UI/BossBG/BossFill
@onready var boss_name_label: Label = $UI/BossName
@onready var boss_stamina_bg: ColorRect = get_node_or_null("UI/BossStaminaBG")
@onready var boss_stamina_fill: ColorRect = get_node_or_null("UI/BossStaminaBG/BossStaminaFill")


var victory_shown := false


func _ready() -> void:
	if not Run.run_active:
		Run.init_run()
	boss.scale_for_lap(Run.lap)
	player.apply_buffs(Run.buffs)
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.died.connect(_on_player_died)
	boss.died.connect(_on_boss_died)
	boss.hit_taken.connect(_on_boss_hit)
	boss.big_attack.connect(_on_boss_big_attack)
	_on_health_changed(player.health)
	_on_stamina_changed(player.stamina)
	run_label.text = "Lap %d · Shards %d · %d upgrades" % [Run.lap, Run.shards, Run.buffs.size()]
	boss_name_label.text = boss.boss_name
	# Some champions speak before the duel.
	if boss.get("intro_line") != null and boss.intro_line != "":
		_show_dialogue(boss.intro_line, 2.5)
	# The world behind the fight: parallax backdrop, one palette per arena.
	var bd: Node = load("res://scripts/backdrop.gd").new()
	bd.setup_for(boss_name_label.text)
	add_child(bd)
	# The arena is 0..1400 — clamp the hero's camera to it.
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_right = 1400
	cam.limit_top = 0
	cam.limit_bottom = 720


func _process(_delta: float) -> void:
	# The boss's health, always readable.
	var ratio := clampf(boss.hp / float(maxi(boss.max_hp, 1)), 0.0, 1.0)
	boss_bar_fill.size.x = 296.0 * ratio
	boss_bar_bg.visible = not boss.dead
	# HP bar lerps so damage reads as a chunk.
	hp_smooth = lerpf(hp_smooth, player.health, 0.18)
	var hpratio := clampf(hp_smooth / float(maxf(player.max_health, 1)), 0.0, 1.0)
	hp_fill.size.x = 200.0 * hpratio
	# The Duel: bosses with a stamina bar show it under their health.
	if boss_stamina_fill != null and boss.get("max_stamina") != null:
		var sratio := clampf(boss.stamina / float(maxf(boss.max_stamina, 1.0)), 0.0, 1.0)
		boss_stamina_fill.size.x = 296.0 * sratio
		boss_stamina_bg.visible = not boss.dead


## A spoken line, faded out after a moment (no cutscenes — just a beat).
func _show_dialogue(text: String, seconds: float) -> void:
	var label := Label.new()
	label.name = "DialogueLabel"
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.65))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -420.0
	label.offset_right = 420.0
	label.offset_top = 70.0
	label.offset_bottom = 102.0
	$UI.add_child(label)
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(label):
		label.queue_free()


func _on_health_changed(hp: int) -> void:
	pass  # HP is now a lerped bar updated in _process


func _on_stamina_changed(value: float) -> void:
	stamina_fill.size.x = 200.0 * clampf(value / player.max_stamina, 0.0, 1.0)


func _on_boss_hit() -> void:
	_shake(3.0)


func _on_boss_big_attack() -> void:
	_shake(6.0)


func _shake(amount: float) -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	var tween := create_tween()
	for i in 6:
		tween.tween_callback(cam.set_offset.bind(Vector2(randf_range(-amount, amount), randf_range(-amount, amount))))
		tween.tween_interval(0.03)
	tween.tween_callback(cam.set_offset.bind(Vector2.ZERO))


## The hero fell — the run is over. Shards survive; the gauntlet restarts.
func _on_player_died() -> void:
	Run.record_death()
	death_label.text = "YOU DIED\nRUN OVER — Shards %d" % Run.shards
	death_label.visible = true
	await get_tree().create_timer(2.5).timeout
	death_label.visible = false
	Run.restart_run()


## The boss fell — victory: shards, then three upgrade cards.
## Guarded: a stray second death event must not double-award or double-connect.
func _on_boss_died() -> void:
	if victory_shown:
		return
	victory_shown = true
	Run.record_victory()
	Sfx.play("victory", -6.0)
	if boss.get("death_line") != null and boss.death_line != "":
		victory_label.text = boss.death_line
	victory_label.visible = true
	run_label.text = "Lap %d · Shards %d · %d upgrades" % [Run.lap, Run.shards, Run.buffs.size()]
	var picks: Array[String] = Run.draw_cards(3)
	for i in 3:
		var btn: Button = card_buttons[i]
		var info: Dictionary = Run.card_info(picks[i])
		btn.text = "%s\n%s" % [info.title, info.desc]
		btn.visible = true
		btn.pressed.connect(_on_card_pressed.bind(picks[i]))
	card_panel.visible = true


func _on_card_pressed(id: String) -> void:
	for btn: Button in card_buttons:
		btn.visible = false
	card_panel.visible = false
	victory_label.text = "THE GAUNTLET OPENS"
	Sfx.play("click", -8.0)
	Run.apply_card(id)
	Run.advance()
