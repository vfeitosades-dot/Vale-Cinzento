shader_type spatial;
render_mode cull_disabled;
uniform vec4 deep : source_color = vec4(0.16, 0.36, 0.37, 1.0);
uniform vec4 shallow : source_color = vec4(0.43, 0.60, 0.55, 1.0);
uniform vec4 glint : source_color = vec4(0.80, 0.84, 0.71, 1.0);
varying vec2 point;
void vertex() {
	point = VERTEX.xz;
	float phase = VERTEX.x * 0.81 + VERTEX.z * 1.7 + TIME * 1.1;
	VERTEX.y += sin(phase) * 0.022;
}
void fragment() {
	float wave = sin(point.x * 1.65 + point.y * 3.82 + TIME * 1.2 + 0.6 * sin(point.x * 0.23));
	float thin = smoothstep(0.91, 0.992, wave) * smoothstep(0.3, 0.85, sin(point.x * 0.34 - point.y * 0.89 + TIME * 0.4));
	float edge = smoothstep(0.60, 0.99, abs(UV.y * 2.0 - 1.0));
	ALBEDO = mix(mix(deep.rgb, shallow.rgb, edge * 0.65 + 0.12 * (wave + 1.0)), glint.rgb, thin * 0.34);
	ROUGHNESS = 0.52;
	SPECULAR = 0.37;
}
