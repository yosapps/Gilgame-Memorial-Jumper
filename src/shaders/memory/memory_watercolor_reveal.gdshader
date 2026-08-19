shader_type canvas_item;

uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;
uniform float reveal_softness : hint_range(0.001, 0.25) = 0.055;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.18;
uniform float noise_scale : hint_range(0.5, 16.0) = 4.0;
uniform float paper_strength : hint_range(0.0, 0.2) = 0.025;
uniform float pigment_variation : hint_range(0.0, 0.25) = 0.045;
uniform float wet_edge_width : hint_range(0.001, 0.2) = 0.045;
uniform float wet_edge_strength : hint_range(0.0, 0.4) = 0.12;
uniform float watercolor_strength : hint_range(0.0, 1.0) = 0.32;
uniform float saturation : hint_range(0.0, 2.0) = 1.02;
uniform float contrast : hint_range(0.5, 1.5) = 1.0;
uniform vec2 reveal_direction = vec2(1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float broad_noise(vec2 uv) {
	float n = value_noise(uv);
	n += value_noise(uv * 2.03 + vec2(4.1, 1.7)) * 0.5;
	n += value_noise(uv * 4.07 + vec2(2.3, 6.2)) * 0.25;
	return n / 1.75;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 direction = normalize(reveal_direction);
	float diagonal = dot(UV, direction);
	float diagonal_max = max(direction.x, 0.0) + max(direction.y, 0.0);
	diagonal = diagonal / max(diagonal_max, 0.001);
	float organic = broad_noise(UV * noise_scale);
	float secondary_pass = value_noise(UV * noise_scale * 0.62 + vec2(8.7, 3.4));
	float boundary = reveal_progress + (organic - 0.5) * noise_strength;
	boundary += (secondary_pass - 0.5) * noise_strength * 0.35;
	float mask = smoothstep(diagonal - reveal_softness, diagonal + reveal_softness, boundary);
	if (reveal_progress <= 0.001) {
		mask = 0.0;
	} else if (reveal_progress >= 0.999) {
		mask = 1.0;
	}

	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 color = mix(vec3(luminance), source.rgb, saturation);
	color = (color - 0.5) * contrast + 0.5;
	float pigment = (organic - 0.5) * pigment_variation * watercolor_strength;
	float paper = (value_noise(UV * 210.0) - 0.5) * paper_strength;
	color *= 1.0 + pigment + paper;

	float edge_distance = abs(diagonal - boundary);
	float wet_edge = (1.0 - smoothstep(0.0, wet_edge_width, edge_distance)) * mask;
	color *= 1.0 - wet_edge * wet_edge_strength;
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), source.a * mask);
}
