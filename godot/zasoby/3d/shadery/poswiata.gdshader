// Poświata wroga w zamachu (autor 26.11: „wolę podświetlenie postaci lekkim shaderem niż słup światła”):
// jasny brzeg sylwetki (Fresnel) i lekki odcień całego ciała, bez światła rzucanego na otoczenie.
// Barwa: złota = do sparowania, czerwona = ciężki (tylko unik), błękitna = strzała.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 kolor : source_color = vec4(1.0, 0.78, 0.25, 1.0);
uniform float sila = 0.0;

void fragment() {
	float f = 1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float brzeg = pow(f, 2.4);
	ALBEDO = kolor.rgb * (brzeg * 1.25 + 0.1) * sila;
}
