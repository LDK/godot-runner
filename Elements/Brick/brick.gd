extends Node2D
class_name Brick

enum BrickState { NORMAL, DISSOLVING, EMPTY, REFILLING }
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body: BrickBody = $Body
@onready var timer: Timer = $RefillTimer
@export var refill_wait:float = 4.0
@onready var kill_zone: Area2D = $KillZone

func transition_dissolve() -> void:
	sprite.play("dissolve")
	await sprite.animation_finished
	state = BrickState.EMPTY

func transition_refill() -> void:
	sprite.play("refill")
	await sprite.animation_finished
	state = BrickState.NORMAL

@export var state: BrickState = BrickState.NORMAL:
	set(value):
		if value != state:
			state = value
			
		if value == BrickState.EMPTY:
			var collision_box = body.get_child(0)
			collision_box.disabled = true
			var kill_box = kill_zone.get_child(0)
			kill_box.disabled = true
			sprite.play("empty")
			timer.start(4.0)
		
		if value == BrickState.DISSOLVING:
			transition_dissolve()
			
		if value == BrickState.REFILLING:
			transition_refill()

		if value == BrickState.NORMAL:
			sprite.play("default")
			var collision_box = body.get_child(0)
			collision_box.set_deferred('disabled', false)
			var kill_box = kill_zone.get_child(0)
			kill_box.set_deferred('disabled', false)

func _on_fire_zone_body_entered(bdy: Node2D) -> void:
	if bdy is Hero:
		var hero = bdy as Hero
		hero.top_of_ladder = false
	elif bdy is Enemy:
		if state == BrickState.DISSOLVING:
			state = BrickState.NORMAL

func _on_fire_zone_body_exited(_body: Node2D) -> void:
	#if body is Hero:
		#var hero = body as Hero
	pass

func zap() -> void:
	if !state == BrickState.NORMAL:
		return

	state = BrickState.DISSOLVING

func _on_refill_timer_timeout() -> void:
	if !state == BrickState.EMPTY:
		return

	state = BrickState.REFILLING


func _on_kill_zone_body_entered(bdy: Node2D) -> void:
	if bdy is Hero:
		(bdy as Hero).die()
	elif bdy is Enemy:
		(bdy as Enemy).die()
