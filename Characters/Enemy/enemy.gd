extends Runner
class_name Enemy

@onready var recover_timer: Timer = $RecoverTimer
@onready var respawn_timer: Timer = $RespawnTimer

@onready var starting_x = position.x
const RESPAWN_Y = -264.0

const RECOVER_TIME = 2.0
const RESPAWN_TIME = 0.25

@onready var stuck_box_collider:CollisionShape2D = $StuckBox/CollisionShape2D
@onready var hurt_box_collider:CollisionShape2D = $HurtBox/CollisionShape2D

var dropX: Variant = null
var climbYGlobal: Variant = null
var climbY: Variant = null:
	set(value):
		if value != climbY:
			climbY = value

		if value:
			climbYGlobal = map.get_cell_center_global(Vector2i(0, value)).y
		else:
			climbYGlobal = null

var next_dest: Variant = null:
	set(value):
		if value != next_dest:
			next_dest = value
		else:
			return

		if value:
			print("I should head to: ", value.type, value.entity_id, " from: ", my_area())
			#print(value)
			#print("from:")
			#print(my_area())
			

func game_plan() -> void:
	if !target:
		return

	var area = my_area()
	var target_area = target.my_area()
	
	if (area and target_area) and (area.has('entity_id') and target_area.has('entity_id')):
		var my_path = map.find_shortest_path(area.entity_id, target_area.entity_id)

		if my_path.size() > 1:
			next_dest = map.entities[my_path[1]].def
		else:
			print("Something is wrong!")
			print(my_path, " from ", area, " to ", target_area)
	else:
		#if not area:
			#print("no enemy area", area)
		if not target_area:
			print("no hero area", target_area)


var state: RunnerState = RunnerState.GROUND:
	set(value):
		if value != state:
			#print("State changed from ", stateNames[state], " to ", stateNames[value])
			state = value
		else:
			return

		if value != RunnerState.HANGING:
			dropX = null
		if value != RunnerState.CLIMBING:
			climbY = null

		if value == RunnerState.GROUND:
			velocity.y = 0
			game_plan()
		elif value == RunnerState.CLIMBING:
			sprite.play("climb")
			game_plan()
		elif value == RunnerState.FALLING:
			sprite.play("fall")
		elif value == RunnerState.HANGING:
			if velocity.x:
				sprite.play("hang_walk")
			else:
				sprite.play("hang_idle")
			game_plan()
		elif value == RunnerState.DEAD:
			sprite.play("die")
			await sprite.animation_finished
			respawn_timer.start(RESPAWN_TIME)
		elif value == RunnerState.STUCK:
			#stuck_box_collider.set_deferred('disabled', false)
			#hurt_box_collider.set_deferred('disabled', true)
			sprite.play("fall")
			recover_timer.start(RECOVER_TIME)
		elif value == RunnerState.RECOVERING:
			#stuck_box_collider.set_deferred('disabled', true)
			#hurt_box_collider.set_deferred('disabled', false)
			sprite.play("climb")
			climb_out()

const CLIMBOUT_DURATION:float = .75
var falling := false

func die() -> void:
	state = RunnerState.DEAD

func climb_over() -> void:
	state = RunnerState.GROUND
	var tween := create_tween()
	tween.tween_property(self, 'position:x', position.x + 4, CLIMBOUT_DURATION / 4)
	
func climb_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, 'position:y', position.y - 16, CLIMBOUT_DURATION)
	tween.tween_callback(climb_over)

@onready var target: Hero = level.hero

func hero_area_changed(hero_area: Variant) -> void:
	if hero_area:
		game_plan()

@onready var gold_indicator: Sprite2D = $GoldIndicator
@export var has_gold := false:
	set(value):
		if value != has_gold:
			has_gold = value
		
		gold_indicator.visible = value

func get_ground_direction_x() -> float:
	if !next_dest:
		return 0.0

	var direction: float
	var coords = my_coords()
	var platform = my_area()
	var hero_area = target.my_area()

	if !platform:
		print("I AM NOWHERE")
		state = RunnerState.FALLING
		return 0.0

	if state == RunnerState.CLIMBING:
		_climbing_process()
		return 0.0

	#if !hero_area and target.state == RunnerState.FALLING:
		#var hero_coords = target.my_coords()

	# We're on the same platform as the hero
	if platform and hero_area and platform.entity_id == hero_area.entity_id:
		var hero_coords := target.my_coords()

		if coords.x > hero_coords.x:
			direction = -1.0
		elif coords.x < hero_coords.x:
			direction = 1.0

	elif next_dest.type in ['bar']:
		#print("hi")
		var endX = next_dest.endX
		var startX = next_dest.startX

		if next_dest.startX > platform.startX:
			startX = platform.startX - 1
		if next_dest.endX < platform.endX:
			endX = platform.endX + 1

		#print(endX, ", ", startX, ", ", coords.x)

		if startX < coords.x:
			direction = -1.0
		elif endX > coords.x:
			direction = 1.0
		
		#print("direction", direction)

	elif next_dest.type in ['platform']:
		# Check both edges of the current platform for which will drop you on the proper target platform
		var leftCoords = Vector2i(platform.startX - 1, platform.y)
		var rightCoords = Vector2i(platform.endX + 1, platform.y)
		var dropLeft = map.level_drops[leftCoords] if map.level_drops.has(leftCoords) else null
		var dropRight = map.level_drops[rightCoords] if map.level_drops.has(rightCoords) else null

		#print("drop left from ", leftCoords, "?", dropLeft)
		#print("platform?", map.platform_at(Vector2i(5,3)))
		
		# If the left side is valid
		if dropLeft and dropLeft.entity_id == next_dest.entity_id:
			# If the right side is also valid...
			if dropRight and dropRight.entity_id == dropLeft.entity_id:
				# Go to whichever is closer
				if abs(coords.x - platform.endX) < abs(coords.x - platform.startX):
					#print("End is closer")
					direction = 1.0
				else:
					#print("Start is closer")
					direction = -1.0
				#direction = 1.0 if abs(coords.x - area.endX) > abs(coords.x - area.startX) else -1.0
			else:
				# Otherwise just go to the left
				direction = -1.0
		else:
			# If not, try the right side.
			if dropRight and dropRight.entity_id == next_dest.entity_id:
				direction = 1.0

	elif next_dest.type == 'ladder':
		if next_dest.x < coords.x:
			direction = -1.0
		elif next_dest.x > coords.x:
			direction = 1.0
		elif next_dest.x == coords.x and ladders_touched.size():
			state = RunnerState.CLIMBING
			global_position.x = ladders_touched[0].global_position.x
		elif next_dest.x == coords.x:
			global_position.x = map.map_to_local(coords).x

	return direction

func get_hanging_direction_x() -> float:
	if !next_dest and dropX == null:
		return 0.0

	var hero_area = target.my_area()

	var direction: float = 0.0
	var coords = my_coords()

	var candidates: Array[int] = []

	var bar = my_area()

	if !bar or !bar.has('drops') or !bar.drops.size():
		if next_dest.type == 'bar':
			bar = next_dest
			game_plan()
		else:
			state = RunnerState.FALLING
			return 0.0

	if next_dest.entity_id == bar.entity_id and hero_area and next_dest.entity_id != hero_area.entity_id:
		game_plan()

	if bar.type != 'bar':
		if state == RunnerState.HANGING:
			print("fall2")
			state = RunnerState.FALLING

	var drop_found := false

	if bar.has('drops'):
		for x in bar.drops:
			if bar.drops[x] == next_dest.entity_id:
				drop_found = true
				candidates.push_back(x)

		candidates.sort()

		var dest_x = dropX if dropX else coords.x
		
		if dest_x < coords.x:
			direction = -1.0
		elif dest_x > coords.x:
			direction = 1.0

		if target:
			if next_dest.entity_id == bar.entity_id and bar.type == 'bar':
				direction = 1.0 if target.my_coords().x > coords.x else -1.0
			else:
				var hero_coords = target.my_coords()
				if bar.drops.has(hero_coords.x) and next_dest.entity_id == bar.drops[hero_coords.x]:
					dropX = hero_coords.x
				elif candidates.size() && hero_coords.x < candidates[0]:
					dropX = candidates[0]
				elif candidates.size() && hero_coords.x > candidates[candidates.size() - 1]:
					dropX = candidates[candidates.size() - 1]

	if !drop_found:
		if next_dest.type == 'platform':
			direction = 1.0 if next_dest.startX > coords.x else -1.0
		elif next_dest.type == 'ladder':
			direction = 1.0 if next_dest.x > coords.x else -1.0

	return direction

func _ground_process() -> void:
	## MOVEMENT ##
	var direction := get_ground_direction_x()

	if direction:
		velocity.x = direction * walk_speed
		if sprite.animation != 'walk':
			sprite.play('walk')
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		if sprite.animation != 'idle' and velocity.x == 0:
			sprite.animation = 'idle'

	## LADDER INTERACTION ##
	#if on_ladder:
		#pass
		#var vert := Input.get_axis("ui_up", "ui_down")
#
		#if vert:
			#if not (top_of_ladder and (vert < 0.0 or velocity.x != 0)):
				#if not (bottom_of_ladder and vert > 0.0):
					#state = RunnerState.CLIMBING
					#global_position.x = ladders_touched[0].global_position.x
					#print("bottom of ladder? ", bottom_of_ladder, " ", vert)

	## TRANSITION TO FALLING ##
	if !is_on_floor() and !on_ladder and !on_bar:
		print("fall4")
		state = RunnerState.FALLING

func _falling_process(delta: float) -> void:
	if sprite.animation != 'fall':
		sprite.play("fall")

	# Add the gravity.
	velocity += (get_gravity() / 2) * delta
	velocity.x = 0

	if on_bar:
		state = RunnerState.HANGING

	elif is_on_floor() or on_ladder:
		state = RunnerState.GROUND

func get_climbing_direction_x(coords: Vector2i, ladder: Variant) -> float:
	if !next_dest or !ladder:
		return 0.0

	var direction: float = 0.0

	if next_dest.type == 'platform':
		
		if next_dest.y > coords.y:
			if next_dest.y == coords.y - 1:
				direction = -1 if next_dest.startX < coords.x else 1
			elif map.level_drops.has(Vector2i(coords.x - 1, coords.y)):
				if map.level_drops[Vector2i(coords.x - 1, coords.y)].entity_id == next_dest.entity_id:
					var distance = abs(global_position.y - map.get_cell_center_global(Vector2i(0, coords.y)).y)

					if distance < .8:
						direction = -1.0
					else:
						print("distance", distance)

			elif map.level_drops.has(Vector2i(coords.x + 1, coords.y)):
				if map.level_drops[Vector2i(coords.x + 1, coords.y)].entity_id == next_dest.entity_id:
					var distance = abs(global_position.y - map.get_cell_center_global(Vector2i(0, coords.y)).y)

					if distance < .8:
						direction = 1.0
					else:
						print("distance", distance)

	elif next_dest.type == 'bar':
		if next_dest.y == coords.y:
			var distance = abs(global_position.y - map.get_cell_center_global(Vector2i(0, next_dest.y)).y)

			if distance < .8:
				direction = 1.0 if next_dest.startX > ladder.x else -1.0

		if direction:
			if (map.platform_at(Vector2i(coords.x + int(direction), coords.y))):
				direction = 0
			else:
				print("moving ", direction, " at ", coords.y)

	return direction

func get_climbing_direction_y(coords: Vector2i, ladder: Variant) -> float:
	if !next_dest:
		return 0.0
	
	var direction: float = 0.0
	
	if coords == null:
		return 0.0
	
	if !ladder:
		return 0.0
		
	
	if next_dest.type == 'platform' and next_dest.y <= coords.y:
		climbY = next_dest.y - 5
	elif next_dest.type == 'platform' and next_dest.y > coords.y + 2:
		climbY = next_dest.y + 1
	elif next_dest.type == 'bar':
		climbY = next_dest.y
	
	if next_dest.entity_id == ladder.entity_id:
		direction = 1.0 if target.my_coords().y > coords.y else -1.0
		climbY = target.my_coords().y
	
	#print("ladder", ladder)
	#print("next dest", next_dest)
	#print("coords", coords)
	#print("climbY", climbY)

	if climbY == null or climbYGlobal == null:
		return 0.0

	if abs(global_position.y - climbYGlobal) < .8:
		direction = 0.0
		#print("reached climbY", climbY)
		#print("climbY global", map.get_cell_center_global(coords).y)
		#print("climbY global2", climbYGlobal)
		#print("my global", global_position)
	elif climbYGlobal < global_position.y:
		direction = -1.0
	elif climbYGlobal > global_position.y:
		direction = 1.0

	return direction

func _climbing_process() -> void:
	velocity.y = 0
	
	if climbY != null:
		top_of_ladder = false

	var area = my_area()

	if top_of_ladder and next_dest and next_dest.type == 'platform' and area and area.entity_id == next_dest.entity_id:
		state = RunnerState.GROUND
		return

	if !ladders_touched.size():
		state = RunnerState.GROUND
		climbY = null
		return

	var ladder = my_area()
	var coords = my_coords()

	if !ladder or ladder.type != 'ladder':
		return
		
	var vert := get_climbing_direction_y(coords, ladder)

	if vert:
		if sprite.animation != 'climb':
			sprite.play('climb')

		velocity.y = vert * climb_speed
		if velocity.y < 0.0 and top_of_ladder:
			state = RunnerState.GROUND
		elif velocity.y > 0.0 and bottom_of_ladder:
			state = RunnerState.GROUND
	else:
		if sprite.animation != 'climb_idle':
			sprite.play('climb_idle')

	var direction := get_climbing_direction_x(coords, ladder)

	if direction:
		velocity.y = 0
		velocity.x = direction * walk_speed
		if sprite.animation != 'climb':
			sprite.play('climb')
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)

	if vert and !direction:
		global_position.x = ladders_touched[0].global_position.x


	if bottom_of_ladder and velocity.y >= 0 and next_dest and next_dest.type == 'platform' and next_dest == my_area():
		state = RunnerState.GROUND

	if not on_ladder:
		state = RunnerState.GROUND if is_on_floor() else RunnerState.FALLING
		
func _hanging_process() -> void:
	velocity.y = 0
	
	if dropX:
		var coords = my_coords()
		if coords.x == dropX:
			state = RunnerState.FALLING
			on_bar = false
			return
	
	var direction := get_hanging_direction_x()

	if direction:
		velocity.x = direction * walk_speed
		if sprite.animation != 'hang_walk':
			sprite.play('hang_walk')
	else:
		if sprite.animation != 'hang_idle':
			sprite.play('hang_idle')
		velocity.x = move_toward(velocity.x, 0, walk_speed)

	if is_on_floor():
		var area = my_area()

		if area and next_dest and area.entity_id == next_dest.entity_id and next_dest.type == 'platform':
			state = RunnerState.GROUND
	
func _physics_process(delta: float) -> void:
	if state == RunnerState.DEAD:
		return
	elif state == RunnerState.GROUND:
		_ground_process()
	elif state == RunnerState.FALLING:
		_falling_process(delta)
	elif state == RunnerState.CLIMBING:
		_climbing_process()
	elif state == RunnerState.HANGING:
		_hanging_process()

	if top_of_ladder and velocity.y < 0:
		velocity.y = 0

	#if top_of_ladder and velocity == Vector2.ZERO and sprite.animation != 'idle':
		#sprite.play("idle")
#
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x > 0.0

	move_and_slide()

func _on_climb_zone_area_entered(area: Area2D) -> void:
	if area is Bar and next_dest and next_dest.type == 'bar':
		state = RunnerState.HANGING
		on_bar = true

func _on_foot_area_entered(area: Area2D) -> void:
	if area.name == 'Caught':
		state = RunnerState.STUCK

func _on_recover_timer_timeout() -> void:
	if state == RunnerState.STUCK:
		state = RunnerState.RECOVERING

func _on_respawn_timer_timeout() -> void:
	if state == RunnerState.DEAD:
		state = RunnerState.FALLING
		position = Vector2(starting_x, RESPAWN_Y)

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if hurt_box_collider.disabled:
		return

	if body is Hero:
		var hero = body as Hero
		hero.die()

func _ready() -> void:
	target.connect('hero_area_change', hero_area_changed)
