shader_type canvas_item;

uniform vec4 paper_color : source_color = vec4(1.0, 0.992, 0.969, 1.0);
uniform float grain_strength : hint_range(0.0, 0.08) = 0.012;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

void fragment() {
	float fine_grain = hash(floor(UV * 640.0));
	float broad_grain = hash(floor(UV * 95.0));
	float grain = ((fine_grain - 0.5) * 0.35 + (broad_grain - 0.5) * 0.65) * grain_strength;
	COLOR = vec4(clamp(paper_color.rgb + grain, vec3(0.0), vec3(1.0)), paper_color.a);
}
