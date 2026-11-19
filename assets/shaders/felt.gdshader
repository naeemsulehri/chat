shader_type canvas_item;
// Table felt: radial light, subtle woven grain and a vignette.

uniform vec4 center_color : source_color = vec4(0.10, 0.50, 0.32, 1.0);
uniform vec4 edge_color : source_color = vec4(0.02, 0.15, 0.10, 1.0);
uniform vec2 light_pos = vec2(0.5, 0.42);
uniform float grain = 0.035;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float d = length((uv - light_pos) * vec2(1.0, 0.75));
	vec3 col = mix(center_color.rgb, edge_color.rgb, smoothstep(0.05, 0.85, d));
	vec2 px = floor(FRAGCOORD.xy * 0.5);
	float weave = (hash(px) - 0.5) + 0.5 * (sin(FRAGCOORD.x * 1.7) * sin(FRAGCOORD.y * 1.7));
	col += weave * grain;
	col *= 1.0 - 0.35 * smoothstep(0.45, 1.0, d);
	COLOR = vec4(col, 1.0);
}
