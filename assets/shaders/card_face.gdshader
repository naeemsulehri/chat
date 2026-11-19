shader_type canvas_item;
// Card face effects: a diagonal shine sweep and dimming for unplayable cards.

uniform vec2 card_size = vec2(100.0, 140.0);
uniform float shine_pos = -1.0;     // sweep position, animate from -0.4 to 1.4
uniform float shine_strength = 0.0; // 0..1
uniform float dim = 0.0;            // 0..1

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 c = COLOR;
	vec2 uv = (local_pos + card_size * 0.5) / card_size;
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	float d = (uv.x * 0.8 + uv.y * 0.6) - shine_pos;
	float band = smoothstep(0.16, 0.0, abs(d)) + 0.6 * smoothstep(0.03, 0.0, abs(d - 0.05));
	c.rgb += vec3(1.0, 0.97, 0.88) * band * shine_strength * 0.55 * inside;
	c.rgb = mix(c.rgb, c.rgb * vec3(0.52, 0.55, 0.6), dim);
	COLOR = c;
}
