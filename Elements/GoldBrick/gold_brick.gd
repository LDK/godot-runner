extends Dissolvable
class_name GoldBrick

var boss: Boss:
	set(value):
		boss = value

func _ready() -> void:
	for el in get_tree().root.get_child(0).get_children():
		if el is Boss:
			boss = el

func handle_state_change(value: BrickState) -> void:
	if value == BrickState.EMPTY:
		var collision_box = body.get_child(0)
		collision_box.disabled = true
		var kill_box = kill_zone.get_child(0)
		kill_box.disabled = true
		sprite.play("empty")
		
		if boss:
			boss.take_hit()

	if value == BrickState.DISSOLVING:
		transition_dissolve()

	if value == BrickState.NORMAL:
		sprite.play("default")
		var collision_box = body.get_child(0)
		collision_box.set_deferred('disabled', false)
		var kill_box = kill_zone.get_child(0)
		kill_box.set_deferred('disabled', false)

func zap() -> void:
	if !state == BrickState.NORMAL:
		return

	state = BrickState.DISSOLVING
