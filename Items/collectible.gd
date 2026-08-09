extends Area2D
class_name Collectible

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var particles_on_collect: bool = false
@onready var particles = get_node_or_null("Particles")

@export var sound_on_collect: bool = false
@onready var sound:AudioStreamPlayer2D = get_node_or_null("CollectSound")

signal collected(collectible: Collectible, runner: Runner)

var is_collected := false:
	set(value):
		is_collected = value
		check_for_expiration()
		
var sound_finished := false:
	set(value):
		sound_finished = value
		check_for_expiration()
		
var particles_finished := false:
	set(value):
		particles_finished = value
		check_for_expiration()

func _ready() -> void:
	if sound_on_collect and sound and sound is AudioStreamPlayer2D:
		sound.connect('finished', _on_sound_finished)
	else:
		sound_finished = true
		
	if particles_on_collect and particles and particles is CPUParticles2D:
		particles.connect('finished', _on_particles_finished)
	else:
		particles_finished = true
		
func check_for_expiration() -> void:
	if particles_finished and sound_finished and is_collected:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if (not body is Runner) or is_collected:
		return
		
	# Enemy cannot pick up two golds.
	if (body is Enemy) and (body as Enemy).has_gold:
		return

	is_collected = true
	collected.emit(self, body)
	_on_collect(body as Runner)

	sprite.hide()

	if sound_on_collect and sound and sound is AudioStreamPlayer2D:
		sound.play()

	if particles_on_collect and particles and particles is CPUParticles2D:
		particles.restart()
		particles.emitting = true

func _on_particles_finished() -> void:
	particles_finished = true

func _on_sound_finished() -> void:
	sound_finished = true

# Placeholder for specific Collectibles to have their own callback function
func _on_collect(_runner: Runner) -> void:
	pass
