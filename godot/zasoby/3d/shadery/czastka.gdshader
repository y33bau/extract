// Pył / iskry w powietrzu: billboard, widoczny tylko tam, gdzie tuż za nim jest odkryta geometria
// (nie świeci w czarnej pustce niezbadanych miejsc).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D tex_glebi : hint_depth_texture, filter_linear;
uniform float sila = 1.0;
uniform float zasieg_tla = 3.5;
void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float a = smoothstep(1.0, 0.0, r);
	float d = texture(tex_glebi, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	float blisko = 1.0 - smoothstep(zasieg_tla * 0.6, zasieg_tla, VERTEX.z - v.z);
	ALBEDO = COLOR.rgb * sila;
	ALPHA = a * COLOR.a * blisko;
}
