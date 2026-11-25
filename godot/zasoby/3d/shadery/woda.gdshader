shader_type spatial;
// Czarna woda przystani: dwie warstwy fal z tekstury szumu przesuwane w różne strony,
// zimny połysk księżyca na krawędziach fal (Fresnel), ciemna toń. Odbicia ognisk daje SSR.
render_mode cull_disabled;

uniform sampler2D szum : filter_linear_mipmap, repeat_enable;
uniform vec4 kolor_toni : source_color = vec4(0.012, 0.018, 0.028, 1.0);
uniform vec4 kolor_polysku : source_color = vec4(0.35, 0.45, 0.62, 1.0);
uniform float skala = 0.08;
uniform float sila_fal = 0.55;
uniform float predkosc = 0.025;

vec3 normal_z(vec2 uv) {
	float e = 0.004;
	float h = texture(szum, uv).r;
	float hx = texture(szum, uv + vec2(e, 0.0)).r;
	float hy = texture(szum, uv + vec2(0.0, e)).r;
	return normalize(vec3((h - hx) * sila_fal * 40.0, (h - hy) * sila_fal * 40.0, 1.0));
}

void fragment() {
	vec3 sw = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = sw.xz * skala;
	vec3 n1 = normal_z(uv + vec2(TIME * predkosc, TIME * predkosc * 0.6));
	vec3 n2 = normal_z(uv * 1.9 - vec2(TIME * predkosc * 0.8, -TIME * predkosc * 1.1));
	vec3 n = normalize(vec3(n1.xy + n2.xy, 1.0));
	NORMAL_MAP = n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = kolor_toni.rgb;
	ROUGHNESS = 0.06;
	METALLIC = 0.3;
	SPECULAR = 0.7;
	float grzbiet = smoothstep(0.62, 0.85, texture(szum, uv * 2.3 + vec2(TIME * 0.01, 0.0)).g);
	EMISSION = kolor_polysku.rgb * (fres * 0.25 + grzbiet * 0.012);
}
