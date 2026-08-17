extends Runner
class_name Hero

var zapping := false:
	set(value):
		if value != zapping:
			zapping = value
		
			hero_zapping.emit(value)

@onready var zap_left:RayCast2D = $ZapLeft
@onready var zap_right:RayCast2D = $ZapRight
@onready var zap_check_left:RayCast2D = $ZapCheckLeft
@onready var zap_check_right:RayCast2D = $ZapCheckRight

var anchor_local_offset := Vector2.ZERO

# This will either be a Node2D or null
var anchor: Variant:
	set(value):
		if value != anchor:
			anchor = value
			anchor_local_offset = value.to_local(global_position) if value else Vector2.ZERO
		#if value:	
			#print("anchored to: ", value)

signal hero_area_change(area: Variant)
signal hero_zapping(is_zapping: bool)
signal gold_collected()

var current_area: Variant = null:
	set(value):
		if value != current_area:
			if value:
				current_area = value
			else:
				var coords = my_coords()
				if state == RunnerState.CLIMBING:
					var ladderLeft: Variant = map.ladder_at(Vector2i(coords.x - 1, coords.y))
					var ladderRight: Variant = map.ladder_at(Vector2i(coords.x + 1, coords.y))

					print("ladderLeft", ladderLeft)
					print("ladderRight", ladderRight)

					if ladderLeft and not ladderRight:
						current_area = ladderLeft
						print("current area is now ", current_area, value)
					elif ladderRight and not ladderLeft:
						current_area = ladderRight
					elif not (ladderLeft or ladderRight):
						print("This should never happen if I'm in a null area!!")
						state = RunnerState.FALLING
					else:
						var distanceLeft = abs(global_position.x - map.get_cell_center_global(Vector2i(ladderLeft.x, 0)).x)
						var distanceRight = abs(global_position.x - map.get_cell_center_global(Vector2i(ladderRight.x, 0)).x)
						if distanceLeft < distanceRight:
							current_area = ladderLeft
						else:
							current_area = ladderRight

			if !current_area:
				print("hero emitting null area ", stateNames[state], my_coords())

			hero_area_change.emit(value)		

var state: RunnerState = RunnerState.GROUND:
	set(value):
		if value != state:
			state = value

		current_area = my_area()

		if value == RunnerState.GROUND:
			velocity.y = 0
		elif value == RunnerState.CLIMBING:
			sprite.play("climb")
		elif value == RunnerState.FALLING:
			sprite.play("fall")
		elif value == RunnerState.HANGING:
			if velocity.x:
				sprite.play("hang_walk")
			else:
				sprite.play("hang_idle")
		elif value == RunnerState.DEAD:
			collision_box.set_deferred("disabled", true)
			sprite.play("die")
			lives -= 1
		elif value == RunnerState.FLUNG:
			sprite.play("fall")

		if value != RunnerState.GROUND:
			zapping = false

var falling := false

signal lives_remaining(l:int)

@export var lives: int = 5:
	set(value):
		if value != lives:
			lives = value
			lives_remaining.emit(value)

## LADDERS ##

func die() -> void:
	state = RunnerState.DEAD

func _ready() -> void:
	sprite.animation_finished.connect(_animation_finished)

func _animation_finished() -> void:
	if sprite.animation == 'zap':
		zapping = false
		sprite.animation = 'idle'

func get_direction_x() -> float:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	return direction

func check_brick_zap(zap: RayCast2D) -> Dissolvable:
	if !zap.is_colliding():
		return null

	var object = zap.get_collider()
	#print("object: ", object)


	if !object is BrickBody:
		return null

	return object.brick as Dissolvable

func check_for_zap_block(zap: RayCast2D, zap_check: RayCast2D) -> bool:
	var blocked := false

	if zap_check.is_colliding():
		var object = zap_check.get_collider()
		if object is LadderClimbZone:
			blocked = true
		if object is Collectible:
			blocked = true
		if object is Runner:
			blocked = true
	
	if !zap.is_colliding():
		blocked = true
	
	return blocked

func _ground_process() -> void:
	## ZAPPING ##
	if zapping:
		velocity = Vector2.ZERO
		if sprite.animation != 'zap':
			sprite.play("zap")
	
	if anchor:
		global_position = anchor.to_global(anchor_local_offset)
		#print("anchor local offset: ", anchor_local_offset)
		#print("global position: ", global_position, anchor.to_global(anchor_local_offset))

	if anchor or zapping:
		return

	var target_brick: Dissolvable

	if Input.is_action_just_pressed("zap_left"):
		var blocked = check_for_zap_block(zap_left, zap_check_left)

		if not blocked:
			sprite.flip_h = false
			target_brick = check_brick_zap(zap_left)

	if Input.is_action_just_pressed("zap_right"):
		var blocked = check_for_zap_block(zap_right, zap_check_right)

		if not blocked:
			sprite.flip_h = true
			target_brick = check_brick_zap(zap_right)

	if target_brick:
		zapping = true
		target_brick.zap()

	## MOVEMENT ##
	var direction := get_direction_x()

	if direction:
		velocity.x = direction * walk_speed
		if sprite.animation != 'walk':
			sprite.play('walk')
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		if sprite.animation != 'idle' and velocity.x == 0:
			sprite.animation = 'idle'

	## LADDER INTERACTION ##
	if on_ladder:
		var vert := Input.get_axis("ui_up", "ui_down")

		if vert:
			if not (top_of_ladder and (vert < 0.0 or velocity.x != 0)):
				if not (bottom_of_ladder and vert > 0.0):
					state = RunnerState.CLIMBING
					global_position.x = ladders_touched[0].global_position.x

	## TRANSITION TO FALLING ##
	elif !is_on_floor():
		state = RunnerState.FALLING

func _falling_process(delta: float) -> void:
	if sprite.animation != 'fall':
		sprite.play("fall")

	# Add the gravity.
	velocity += (get_gravity() / 2) * delta
	velocity.x = 0

	if is_on_floor() or on_ladder:
		state = RunnerState.GROUND
	
	if on_bar:
		state = RunnerState.HANGING

func _climbing_process() -> void:
	velocity.y = 0
	
	if Input.is_action_pressed("ui_down"):
		top_of_ladder = false

	var vert := Input.get_axis("ui_up", "ui_down")
	
	if vert and ladders_touched.size():
		velocity.y = vert * climb_speed
		if velocity.y < 0.0 and top_of_ladder:
			state = RunnerState.GROUND
		elif velocity.y > 0.0 and bottom_of_ladder:
			state = RunnerState.GROUND
		global_position.x = ladders_touched[0].global_position.x
	
	var direction := get_direction_x()

	if direction:
		velocity.x = direction * walk_speed
		if sprite.animation != 'climb':
			sprite.play('climb')
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		
	if bottom_of_ladder and velocity.y >= 0:
		state = RunnerState.GROUND

	if not on_ladder:
		state = RunnerState.GROUND if is_on_floor() else RunnerState.FALLING
		
func _hanging_process() -> void:
	velocity.y = 0
	if Input.is_action_pressed("ui_down"):
		state = RunnerState.FALLING
		on_bar = false
		return
	
	var direction := get_direction_x()

	if direction:
		velocity.x = direction * walk_speed
		if sprite.animation != 'hang_walk':
			sprite.play('hang_walk')
	else:
		if sprite.animation != 'hang_idle':
			sprite.play('hang_idle')
		velocity.x = move_toward(velocity.x, 0, walk_speed)

	if is_on_floor():
		state = RunnerState.GROUND

func _flung_process() -> void:
	if global_position.y <= -80.0:
		collision_box.disabled = false
		state = RunnerState.FALLING

func _physics_process(delta: float) -> void:
	if state == RunnerState.DEAD:
		return
	elif state == RunnerState.GROUND:
		_ground_process()
	elif state == RunnerState.FALLING:
		_falling_process(delta)
		var coords = my_coords()
		if map.level_drops.has(coords):
			current_area = map.level_drops[coords]
	elif state == RunnerState.CLIMBING:
		_climbing_process()
	elif state == RunnerState.HANGING:
		_hanging_process()
	elif state == RunnerState.FLUNG:
		_flung_process()

	if top_of_ladder and velocity.y < 0:
		velocity.y = 0

	if velocity.x != 0.0:
		sprite.flip_h = velocity.x > 0.0

	move_and_slide()


func _on_climb_zone_area_entered(area: Area2D) -> void:
	if area is Bar:
		state = RunnerState.HANGING
