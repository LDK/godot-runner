shader_type canvas_item;

uniform float radius = 0.5f;
uniform float strength = 0.5f;

void fragment() {
	COLOR.r = 0.0;
	COLOR.g = 0.0;
	COLOR.b = 0.0;
	COLOR.a = smoothstep(distance(vec2(0.5, 0.5), UV), 0, radius) * strength; 
}