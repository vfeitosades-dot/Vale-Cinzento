shader_type sky;

uniform vec4 zenith : source_color = vec4(0.23, 0.42, 0.48, 1.0);
uniform vec4 horizon : source_color = vec4(0.81, 0.73, 0.57, 1.0);
uniform vec4 cloud_tint : source_color = vec4(0.9, 0.86, 0.73, 1.0);
uniform vec3 sun_direction = vec3(-0.4, 0.55, -0.73);
uniform float cover = 0.26;
uniform float daylight = 1.0;
uniform float wind_offset = 0.0;

float hash21(vec2 p) {
	return fract(sin(mod(dot(p, vec2(127.1, 311.7)), 6.28318)) * 4375.5453);
}
float value_noise(vec2 p) {
	vec2 f = fract(p);
	vec2 t = f * f * (3.0 - 2.0 * f);
	vec2 cell = floor(p);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), t.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), t.x), t.y);
}
void sky() {
	float y = max(EYEDIR.y, 0.0);
	vec3 base = mix(horizon.rgb, zenith.rgb, pow(y, 0.55));
	vec2 uv = EYEDIR.xz / (y + 0.23) * vec2(2.5, 4.0) + vec2(wind_offset, 0.0);
	float n = 0.58 * value_noise(uv) + 0.28 * value_noise(uv * 2.07 + 5.2) + 0.14 * value_noise(uv * 4.16);
	float density = smoothstep(0.60 - cover * 0.29, 0.77 - cover * 0.21, n) * smoothstep(0.01, 0.17, y);
	float dist_sun = max(dot(normalize(sun_direction), EYEDIR), 0.0);
	vec3 light = vec3(1.0, 0.76, 0.45) * (pow(dist_sun, 24.0) * 0.18 + smoothstep(0.99935, 0.99983, dist_sun) * 1.2);
	base = mix(base + light * daylight, cloud_tint.rgb, density * 0.76);
	vec2 star_uv = SKY_COORDS * vec2(980.0, 520.0);
	float star = step(0.9967, hash21(floor(star_uv))) * (1.0 - smoothstep(0.05, 0.32, length(fract(star_uv) - 0.5)));
	COLOR = base + vec3(star * (1.0 - daylight) * (1.0 - density) * y * 0.7);
}
