extends Node2D

## The hero's rig — procedural animation. No keyframes: every pose is
## driven by the hero's own state (velocity, floor contact, attacking,
## rolling), so movement and animation can never disagree.
##
## Contract with player.gd (do not break):
##   - this node is $Body; player.gd sets `scale` (facing mirror) and
##     `modulate` (hit flash) on it. Both still work: mirroring flips the
##     whole rig, and modulate tints every child polygon.
##
## The pose is written every frame from scratch, so there is no state to
## get stuck in — the stuck-blade class of bug can't happen here.

@onready var head: Node2D = $Head
@onready var torso: Polygon2D = $Torso
@onready var pelvis: Polygon2D = $Pelvis
@onready var cape: Polygon2D = $Cape
@onready var sword_arm: Node2D = $SwordArm
@onready var sword_fore: Node2D = $SwordArm/Fore
@onready var back_arm: Node2D = $BackArm
@onready var back_fore: Node2D = $BackArm/Fore
@onready var front_leg: Node2D = $FrontLeg
@onready var front_shin: Node2D = $FrontLeg/Shin
@onready var back_leg: Node2D = $BackLeg
@onready var back_shin: Node2D = $BackLeg/Shin

var hero: CharacterBody2D
var t := 0.0            # animation clock
var stride := 0.0       # run-cycle phase, advanced by actual distance moved
var land_squash := 0.0  # decays after a landing
var was_airborne := false
var cape_lag := 0.0

const REST_Y := 0.0

var _glow: Polygon2D
var _glow_base_alpha := 0.08


func _setup_glow() -> void:
	_glow = Polygon2D.new()
	_glow.name = "HeroGlow"
	_glow.color = Color(1.0, 0.82, 0.4, _glow_base_alpha)
	_glow.z_index = -5
	var r := 62.0
	var sides := 28
	var pts: PackedVector2Array = PackedVector2Array()
	for i in sides:
		var a: float = TAU * i / float(sides)
		pts.append(Vector2(cos(a) * r, sin(a) * 0.65 * r))
	_glow.polygon = pts
	add_child(_glow)


func _ready() -> void:
	hero = get_parent() as CharacterBody2D
	_setup_glow()


## The greatsword is a sibling of this rig (player.gd owns its transform
## during the swing, for the hitbox contract). Between swings the RIG owns
## the resting pose: a heavy weapon is carried shouldered, not held aloft
## like a candle. The hand is then planted on the grip so the two agree.
func _carry_sword(delta: float) -> void:
	var sword: Node2D = hero.sword
	# Rest pose in the hero's local space (pre-mirror; player.gd flips scale.x).
	var rest_pos := Vector2(10, -6)
	var rest_rot := -0.55           # shouldered, blade angled back over the shoulder
	if hero.is_rolling:
		rest_pos = Vector2(4, 4)
		rest_rot = -1.9             # tucked in against the body
	elif not hero.is_on_floor():
		rest_pos = Vector2(12, -4)
		rest_rot = -0.85            # raised on the way up
	elif absf(hero.velocity.x) > 8.0:
		rest_pos = Vector2(9, -7)
		rest_rot = -0.72 + sin(stride) * 0.06  # bounces with the run
	sword.position = sword.position.lerp(Vector2(rest_pos.x * hero.facing.x, rest_pos.y), delta * 14.0)
	sword.rotation = lerp_angle(sword.rotation, rest_rot * hero.facing.x, delta * 14.0)


func _plant_hand_on_grip() -> void:
	var hand: Node2D = sword_fore.get_node("Hand")
	var sword: Node2D = hero.sword
	var grip: Vector2 = sword.global_position + sword.global_transform.basis_xform(Vector2(0, 7))
	# Aim the whole arm at the grip, then bend the forearm to reach it.
	var shoulder: Vector2 = sword_arm.global_position
	var to_grip: Vector2 = grip - shoulder
	var dist: float = to_grip.length()
	# Arm segments are 10px each; keep the reach inside what the arm can do.
	var reach: float = clampf(dist, 6.0, 21.0)
	var ang: float = to_grip.angle() - PI * 0.5
	# global -> local rotation, accounting for the rig's facing mirror.
	sword_arm.rotation = ang * signf(scale.x) if scale.x != 0.0 else ang
	sword_fore.rotation = 0.0
	sword_fore.position.y = reach * 0.55
	hand.position.y = reach * 0.45


func _process(delta: float) -> void:
	if hero == null:
		return
	t += delta
	var on_floor: bool = hero.is_on_floor()
	var vx: float = absf(hero.velocity.x)
	var vy: float = hero.velocity.y

	# Landing: a squash impulse the moment we touch down after a fall.
	if on_floor and was_airborne:
		land_squash = 1.0
	was_airborne = not on_floor
	land_squash = maxf(0.0, land_squash - delta * 6.0)

	# The cape lags behind horizontal motion and lifts when falling.
	var target_lag: float = clampf(-hero.velocity.x / 260.0, -1.1, 1.1)
	if not on_floor:
		target_lag += clampf(vy / 700.0, -0.5, 0.6)
	cape_lag = lerpf(cape_lag, target_lag, delta * 9.0)

	if hero.is_rolling:
		_pose_roll(delta)
	elif not on_floor:
		_pose_air(vy)
	elif vx > 8.0:
		_pose_run(delta, vx)
	else:
		_pose_idle()

	# The attack overrides the sword arm on top of any pose.
	if hero.is_attacking:
		_pose_attack()
	else:
		# Between swings the rig carries the weapon; during a swing
		# player.gd owns it (the hitbox contract depends on that).
		_carry_sword(delta)
	# Whatever the pose, the sword hand ends up ON the grip.
	_plant_hand_on_grip()

	_apply_squash()
	# The bloom halo pulses when the greatsword swings.
	_update_glow()
	cape.rotation = cape_lag * 0.5
	cape.skew = clampf(cape_lag * 0.45, -0.6, 0.6)


## Standing: slow breathing, a little weight shift, the cape settling.
func _pose_idle() -> void:
	stride = lerpf(stride, 0.0, 0.15)
	var breath := sin(t * 2.0)
	torso.position.y = breath * 0.6
	head.position.y = -13.0 + breath * 0.5
	head.rotation = breath * 0.02
	pelvis.position.y = 4.0
	front_leg.rotation = 0.0
	front_shin.rotation = 0.0
	back_leg.rotation = 0.0
	back_shin.rotation = 0.0
	front_leg.position = Vector2(2, 5)
	back_leg.position = Vector2(-2, 5)
	if not hero.is_attacking:
		sword_arm.rotation = -0.15 + breath * 0.03
		sword_fore.rotation = 0.2
	back_arm.rotation = 0.12 - breath * 0.04
	back_fore.rotation = 0.25


## Running: real leg alternation, counter-swinging arms, a bobbing torso.
func _pose_run(delta: float, vx: float) -> void:
	# Phase advances with distance travelled, so the cycle never skates.
	stride += delta * (vx / 26.0)
	var s := sin(stride)
	var c := cos(stride)
	front_leg.rotation = s * 0.85
	back_leg.rotation = -s * 0.85
	# Shins trail the thighs: they bend on the backswing, straighten forward.
	front_shin.rotation = maxf(0.0, -s) * 1.15
	back_shin.rotation = maxf(0.0, s) * 1.15
	front_leg.position = Vector2(2, 5)
	back_leg.position = Vector2(-2, 5)
	# The torso bobs twice per stride, leans in, and TWISTS with the arms.
	var bob := absf(c) * 1.6
	torso.position.y = -bob
	torso.position.x = s * 0.7
	pelvis.position.y = 4.0 - bob
	torso.rotation = 0.10 + s * 0.07
	head.position.y = -13.0 - bob * 0.8
	head.position.x = 1.0 + s * 0.5
	head.rotation = 0.06 - s * 0.05
	# Arms counter-swing against the legs.
	if not hero.is_attacking:
		sword_arm.rotation = -0.25 + s * 0.5
		sword_fore.rotation = 0.35
	back_arm.rotation = -s * 0.7
	back_fore.rotation = 0.4 + maxf(0.0, s) * 0.5


## Airborne: extend on the way up, tuck on the way down.
func _pose_air(vy: float) -> void:
	var rising: bool = vy < 0.0
	stride = 0.0
	torso.rotation = 0.06 if rising else 0.16
	torso.position.y = 0.0
	pelvis.position.y = 4.0
	head.position.y = -13.0
	head.rotation = 0.04 if rising else 0.1
	if rising:
		# Extended: trailing legs, arms up.
		front_leg.rotation = -0.5
		front_shin.rotation = 0.5
		back_leg.rotation = 0.35
		back_shin.rotation = 0.15
		back_arm.rotation = -0.8
	else:
		# Tucked: knees up, ready to land.
		front_leg.rotation = -0.9
		front_shin.rotation = 1.2
		back_leg.rotation = -0.3
		back_shin.rotation = 0.9
		back_arm.rotation = -0.4
	back_fore.rotation = 0.5
	if not hero.is_attacking:
		sword_arm.rotation = -0.4
		sword_fore.rotation = 0.3


## Rolling: a tight ball, spun by the roll's own timer.
func _pose_roll(delta: float) -> void:
	stride += delta * 22.0
	front_leg.rotation = -1.5
	front_shin.rotation = 1.9
	back_leg.rotation = -1.2
	back_shin.rotation = 1.9
	torso.rotation = 0.9
	torso.position.y = 4.0
	pelvis.position.y = 5.0
	head.position.y = -8.0
	head.rotation = 0.9
	back_arm.rotation = 1.5
	back_fore.rotation = 1.2
	sword_arm.rotation = 1.3
	sword_fore.rotation = 0.9


## Mid-swing: the whole body commits — shoulders open, weight forward.
func _pose_attack() -> void:
	var arm := clampf(hero.sword.rotation * hero.facing.x, -1.6, 2.0)
	sword_arm.rotation = -0.9 + arm * 0.9
	sword_fore.rotation = 0.15
	torso.rotation = 0.06 + arm * 0.16
	head.rotation = arm * 0.1
	back_arm.rotation = 0.5 - arm * 0.4


## The hero's light burns brighter mid-combat — the glow pulses with the
## swing and fades back to a restful shimmer.
func _update_glow() -> void:
	var target := _glow_base_alpha
	if hero.is_attacking:
		target = _glow_base_alpha + 0.22
	elif hero.is_rolling:
		target = _glow_base_alpha + 0.08
	elif not hero.is_on_floor():
		target = _glow_base_alpha + 0.05
	elif absf(hero.velocity.x) > 8.0:
		target = _glow_base_alpha + 0.03 + absf(sin(stride)) * 0.04
	_glow.color.a = lerpf(_glow.color.a, target, 0.12)
	_glow.visible = not hero.dead


## Landing squash, applied as a non-destructive scale on the visual root.
func _apply_squash() -> void:
	if land_squash <= 0.0:
		return
	var k := land_squash * land_squash
	# Squash without touching this node's own scale (player.gd owns it):
	# apply it to the parts instead.
	torso.scale = Vector2(1.0 + k * 0.18, 1.0 - k * 0.22)
	pelvis.scale = Vector2(1.0 + k * 0.12, 1.0 - k * 0.15)
	head.scale = Vector2(1.0 + k * 0.1, 1.0 - k * 0.12)
	if land_squash < 0.02:
		torso.scale = Vector2.ONE
		pelvis.scale = Vector2.ONE
		head.scale = Vector2.ONE
