extends ColorRect
class_name CircleWipe

const OPEN_RADIUS = .65
const CLOSED_RADIUS = 0.0

func open() -> void:
	(material as ShaderMaterial).set_shader_parameter("radius", CLOSED_RADIUS)
	var tween := create_tween()
	tween.tween_property(self, "material:shader_parameter/radius", OPEN_RADIUS, 1)

func close() -> void:
	(material as ShaderMaterial).set_shader_parameter("radius", OPEN_RADIUS)
	var tween := create_tween()
	tween.tween_property(self, "material:shader_parameter/radius", CLOSED_RADIUS, 1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	open()
	pass # Replace with function body.
