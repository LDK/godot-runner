extends Boss

enum TurtleState { WALKING, SELLING, ATTACK1, ATTACK2, BERZERK1, BERZERK2 }
var stateNames = ['Walking', 'Selling', 'Attack 1', 'Attack 2', 'Berzerk1', 'Berzerk2']
const LEFT_X: float = -60.0
const RIGHT_X: float = 0.0
const CENTER_X: float = -45.0
const DEFAULT_EXTENSION = 24

const MIN_HEAD_LEVEL = -40
const DEFAULT_HEAD_LEVEL = 10
const HURT_HEAD_LEVEL = -20
const MAX_HEAD_LEVEL = 60

@onready var sell_timer: Timer = $SellTimer

@onready var neck_segments: Array[Node2D] = [
	$Neck/Neck1,
	$Neck/Neck1/Neck2,
	$Neck/Neck1/Neck2/Neck3
]

const NECK_LENGTH = 3

func distribute_values(value) -> Array[float]:
	# ex: 64.5
	# each should get 21, but neck[0] should get an additional 1 (making 22) and 2 should get the remaining .5 (making 21.5)
	# 21 + 22 + 21.5 = 64.5
	var i := 0
	var neg: bool = (value < 0)

	var values: Array[float] = [0.0, 0.0, 0.0]

	while i + 1 <= abs(round(value)):
		values[i % NECK_LENGTH] += (1.0 * -1 if neg else 1)

		i += 1

	var remainder = value - i

	if neg:
		remainder = value + i

	values[i % NECK_LENGTH] += remainder

	if neg:
		for val in values:
			val = 3
		values.reverse()

	return values


var head_level: float = 0.0:
	set(value):
		if value != head_level:
			value = min(MAX_HEAD_LEVEL, max(value, MIN_HEAD_LEVEL))
			head_level = value

		var neck_ys: Array[float] = distribute_values(value)

		var i := 0
		
		while i < NECK_LENGTH:
			neck_segments[i].position.y = -1 * neck_ys[i]
			i += 1

var extension: float = 0.0:
	set(value):
		if value != extension:
			extension = value

		var neck_extensions = distribute_values(value)

		var i := 0
		
		while i < NECK_LENGTH:
			neck_segments[i].position.x = -1 * neck_extensions[i]
			i += 1


var state: TurtleState = TurtleState.WALKING:
	set(value):
		if value != state:
			state = value
		#else:
			#print("Attempted state change, but state was already ", stateNames[value])
		
		if value == TurtleState.SELLING:
			shaking = true
			sell_timer.start(sell_time)
		else:
			shaking = false
			position.y = original_y
		
		if value == TurtleState.WALKING:
			tween_left()
			tween_neck(DEFAULT_EXTENSION)
			tween_head(DEFAULT_HEAD_LEVEL, 1.5)


@onready var original_y:float = position.y

var shaking := false
@export var sell_time: float = 2.5
@export var sell_intensity: float = 5.0

var is_left: bool = false:
	set(value):
		if value != is_left:
			is_left = value

		if state == TurtleState.WALKING:
			if value:
				is_left = false
				tween_right()

var is_right: bool = true:
	set(value):
		if value != is_right:
			is_right = value

		if state == TurtleState.WALKING:
			if value:
				is_right = false
				tween_left()

func body_left() -> void:
	is_left = true

func body_right() -> void:
	is_right = true

func tween_left() -> void:
	var body_f = create_tween()
	body_f.tween_property(self, "position:x", LEFT_X, 1.0)
	body_f.tween_callback(body_left)

func tween_right() -> void:
	var body_b = create_tween()
	body_b.tween_property(self, "position:x", RIGHT_X, 1.0)
	body_b.tween_callback(body_right)

func kill_tweens_on(obj: Object) -> void:
	# Fetch all active tweens running in the scene tree
	for tween in get_tree().get_tweens():
		# Check if the tween is bound to or animating this specific object
		if tween.is_valid() and tween.is_bound_to(obj):
			tween.kill()

func _process(delta: float) -> void:
	if shaking:
		position.y = original_y + randf_range(-sell_intensity, sell_intensity)
	else:
		tween_head((hero.position.y - 16) * -1, .5)

func fling_hero():
	if !hero:
		return
	hero.collision_box.disabled = true
	hero.state = Runner.RunnerState.FLUNG
	
	hero.velocity = Vector2.ZERO
	hero.velocity.y = -200

func tween_neck(ext: float, duration: float = 1.0):
	var extension_tween := create_tween()
	extension_tween.tween_property(self, "extension", ext, duration)

func tween_head(elv: float, duration: float = 1.0):
	var elevation_tween := create_tween()
	elevation_tween.tween_property(self, "head_level", elv, duration)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#extension = 46.5
	tween_left()
	tween_neck(DEFAULT_EXTENSION)
	tween_head(DEFAULT_HEAD_LEVEL, 1.5)
	if hero:
		hero.connect("hero_zapping", _on_hero_zap)

func _on_hero_zap(zapping: bool) -> void:
	if zapping:
		hero.anchor = self
	else:
		hero.anchor = null

func die() -> void:
	queue_free()

func take_hit() -> void:
	tween_neck(0.0, 0.5)
	tween_head(HURT_HEAD_LEVEL, 0.5)
	is_left = false
	is_right = false
	state = TurtleState.SELLING
	hp -= 1
	if hp < 1:
		die()
	fling_hero()

func _on_sell_timer_timeout() -> void:
	state = TurtleState.WALKING
