// Przyziemna mgła: dwie warstwy szumu przesuwające się w różnych kierunkach, miękkie przy przecięciu z geometrią.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_disabled;
uniform sampler2D szum : filter_linear, repeat_enable;
uniform sampler2D tex_glebi : hint_depth_texture, filter_linear;
uniform vec4 kolor : source_color = vec4(0.5, 0.55, 0.65, 0.35);
uniform float skala = 0.06;
uniform float predkosc = 0.012;
uniform float miekkosc = 0.6;
varying vec3 swiat;
void vertex() {
	swiat = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = swiat.xz * skala;
	float a = texture(szum, p + vec2(TIME * predkosc, TIME * predkosc * 0.4)).r;
	float b = texture(szum, p * 2.3 - vec2(TIME * predkosc * 1.6, -TIME * predkosc)).g;
	float m = smoothstep(0.35, 0.85, a * 0.65 + b * 0.5);
	// miękkie przecięcie z podłogą/murami (głębia w rzucie ortogonalnym jest liniowa)
	float d = texture(tex_glebi, SCREEN_UV).r;
	vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	vec4 v = INV_PROJECTION_MATRIX * ndc;
	v.xyz /= v.w;
	float roznica = clamp((VERTEX.z - v.z) / miekkosc, 0.0, 1.0);
	// brak geometrii za mgłą (niezbadane, tło) -> brak mgły
	float jest_cos = 1.0 - step(90.0, -v.z);
	ALBEDO = kolor.rgb;
	ROUGHNESS = 1.0;
	BACKLIGHT = kolor.rgb;
	ALPHA = kolor.a * m * roznica * jest_cos;
}
