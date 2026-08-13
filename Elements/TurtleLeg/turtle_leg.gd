extends Node2D
class_name TurtleLeg

@export var slot: int = 0
@onready var timer: Timer = $Timer
const UP_Y: float = 48.0
const DOWN_Y: float = 72.0

var moving_down := false

var is_up: bool = false:
	set(value):
		if value != is_up:
			is_up = value

		if value:
			is_up = false
			tween_down()

var is_down: bool = true:
	set(value):
		if value != is_down:
			is_down = value

		if value:
			moving_down = false
			is_down = false
			tween_up()

func leg_up() -> void:
	is_up = true

func leg_down() -> void:
	is_down = true

func tween_up() -> void:
	var leg_lift = create_tween()
	leg_lift.tween_property(self, "position:y", UP_Y, 1.0)
	leg_lift.tween_callback(leg_up)

func tween_down() -> void:
	moving_down = true
	var leg_drop = create_tween()
	leg_drop.tween_property(self, "position:y", DOWN_Y, 1.0)
	leg_drop.tween_callback(leg_down)

func _ready() -> void:
	if slot in [1,3]:
		print("Slot ", slot)
		tween_up()
	else:
		timer.start(1.0)

func _on_timer_timeout() -> void:
	tween_up()


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if moving_down and body is Hero:
		(body as Hero).die()
