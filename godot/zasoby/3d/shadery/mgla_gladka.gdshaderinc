// Gładka mgła wojny (autor 26.11: „odsłanianie mapy to parada kwadratów”). Jasność pól z mapy (0 nieznane,
// ok. 0,3 pamięć, 1 widoczne; mury i gąszcz biorą jasność najbliższego przejścia), rozmyta 9 próbkami
// i z falującym brzegiem z szumu. Wymaga wcześniej: uniform sampler2D szum, uniform float rozmiar_mgly.
uniform sampler2D jasnosc_mapy : hint_default_white, filter_linear, repeat_disable;
uniform bool mgla_gladka = false;
float jas_gladka(vec2 p) {
	vec2 fala = (texture(szum, p * 0.085 + vec2(0.13, 0.71)).rg - 0.5) * 1.6;
	vec2 uv = (p + fala) / rozmiar_mgly;
	float d = 1.1 / rozmiar_mgly;
	float s = texture(jasnosc_mapy, uv).r * 0.25;
	s += (texture(jasnosc_mapy, uv + vec2(d, 0.0)).r + texture(jasnosc_mapy, uv - vec2(d, 0.0)).r
		+ texture(jasnosc_mapy, uv + vec2(0.0, d)).r + texture(jasnosc_mapy, uv - vec2(0.0, d)).r) * 0.125;
	s += (texture(jasnosc_mapy, uv + vec2(d, d)).r + texture(jasnosc_mapy, uv - vec2(d, d)).r
		+ texture(jasnosc_mapy, uv + vec2(d, -d)).r + texture(jasnosc_mapy, uv - vec2(d, -d)).r) * 0.0625;
	return smoothstep(0.02, 0.98, s);
}
