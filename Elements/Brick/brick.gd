extends Dissolvable
class_name Brick

const HIGHLIGHT_TIME := 0.05
const HIGHLIGHT_MIX := .3
const DEFAULT_MIX := 0.0

var highlight: bool = false:
	set(value):
		if value != highlight:	
			var tween := create_tween()
			tween.tween_property(sprite, "material:shader_parameter/mix_weight", HIGHLIGHT_MIX if value else DEFAULT_MIX, HIGHLIGHT_TIME)
		
			highlight = value

func transition_dissolve() -> void:
	sprite.play("dissolve")
	await sprite.animation_finished
	state = BrickState.EMPTY

func transition_refill() -> void:
	sprite.play("refill")
	await sprite.animation_finished
	state = BrickState.NORMAL

func _on_kill_zone_body_entered(bdy: Node2D) -> void:
	if bdy is Hero:
		(bdy as Hero).die()
	elif bdy is Enemy:
		(bdy as Enemy).die()
