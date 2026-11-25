// Obrys światłem (rim) postaci: jasna krawędź sylwetki, żeby bohater, wrogowie i NPC nie zlewali się z tłem.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
uniform vec4 kolor : source_color = vec4(1.0, 0.75, 0.5, 1.0);
uniform float sila = 0.9;
uniform float ostrosc = 2.6;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), ostrosc);
	ALBEDO = kolor.rgb * f * sila;
}
