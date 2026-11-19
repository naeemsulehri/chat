shader_type canvas_item;
// Soft pulsing glow around a rounded-rectangle card.

uniform vec2 card_size = vec2(100.0, 140.0);
uniform float radius = 9.0;
uniform float spread = 22.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.35, 1.0);
uniform float intensity = 1.0;
uniform float pulse_speed = 4.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - (half_size - vec2(r));
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	float d = rounded_box(local_pos, card_size * 0.5, radius);
	float outside = max(d, 0.0);
	float a = exp(-outside / (spread * 0.33)) * (1.0 - smoothstep(spread * 0.8, spread, outside));
	a *= step(-2.0, d); // only outside the card (+ a hairline)
	float pulse = 0.78 + 0.22 * sin(TIME * pulse_speed);
	COLOR = vec4(glow_color.rgb, glow_color.a * a * intensity * pulse);
}
