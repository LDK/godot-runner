shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(1.0, 0.84, 0.0, 1.0);
uniform float mix_weight : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec3 mixed_color = mix(texture_color.rgb, target_color.rgb, mix_weight);
    COLOR = vec4(mixed_color, texture_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
