// Podłoga lochu: trzy warstwy tekstur NightBrand mieszane po wysokości i szumie w przestrzeni świata
// (bez widocznego kafelkowania), ciemnienie przy murach z maski mapy, kałuże/żar zależnie od krainy.
// COLOR (kolor instancji) = jasność mgły wojny.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D a_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D a_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D a_rh : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D b_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D b_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D b_rh : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D c_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D c_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D c_rh : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D szum : filter_linear, repeat_enable;        // bezszwowy szum (R, G, B różne częstotliwości)
uniform sampler2D maska_mapy : filter_linear, repeat_disable; // R = bliskość muru, G = ścieżka, B = plamy
uniform float rozmiar_mapy = 42.0;

uniform float a_skala = 0.25;   // powtórzenia na metr
uniform float b_skala = 0.2;
uniform float c_skala = 0.22;
uniform float b_ilosc = 0.35;   // ile warstwy B (plamy)
uniform float c_ilosc = 0.25;   // ile warstwy C (akcent)
uniform float c_przy_murach = 0.6; // akcent gęstnieje przy murach (mech, sadza)
uniform float sciezka_b = 0.8;  // ścieżki z warstwy B
uniform vec3 ton : source_color = vec3(1.0);
uniform float jasnosc = 1.0;
uniform float ao_murow = 0.55;
uniform float kaluze = 0.0;     // ilość wody (gładka, odbijająca)
uniform vec3 kolor_wody : source_color = vec3(0.05, 0.06, 0.07);
uniform float zar = 0.0;        // świecenie gorących pikseli warstwy C (popiół z żarem)
uniform vec3 kolor_zaru : source_color = vec3(1.0, 0.35, 0.08);
uniform float normalna = 1.0;

varying vec3 swiat;

// Miękki brzeg mgły wojny (autor 26.11): mapa znanych pól (1 = odkryte) próbkowana z rozmyciem,
// odkryty teren ciemnieje łagodnie ku granicy z nieznanym zamiast urywać się schodkiem.
// Bez przypisanej tekstury (np. Przystań) — biała = brak efektu.
uniform sampler2D mgla_znane : hint_default_white, filter_linear, repeat_disable;
uniform float rozmiar_mgly = 128.0;
float brzeg_mgly(vec2 p) {
	vec2 uv = p / rozmiar_mgly;
	float d = 0.75 / rozmiar_mgly;
	float s = texture(mgla_znane, uv).r * 0.36
		+ (texture(mgla_znane, uv + vec2(d, 0.0)).r + texture(mgla_znane, uv - vec2(d, 0.0)).r
		+ texture(mgla_znane, uv + vec2(0.0, d)).r + texture(mgla_znane, uv - vec2(0.0, d)).r) * 0.16;
	return smoothstep(0.3, 0.92, s);
}
uniform float sciezka_jasn = 1.0;     // las: wydeptana ścieżka jaśniejsza od runa (czytelność ponad nastrój)
uniform float sciezka_czysta = 0.0;   // las: na ścieżce mniej liści i mchu (warstwa C)

void vertex() {
	swiat = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 nrm_mix(vec3 a, vec3 b, float t) { return normalize(mix(a, b, t)); }

void fragment() {
	vec2 p = swiat.xz;
	vec3 n1 = texture(szum, p * 0.045).rgb;
	vec3 n2 = texture(szum, p * 0.17 + vec2(0.31, 0.77)).rgb;
	vec3 mk = texture(maska_mapy, p / rozmiar_mapy).rgb;

	// warstwa A: dwie próbki (obrót + inna skala) mieszane szumem -> brak powtarzalnego wzoru
	vec2 ua = p * a_skala;
	vec2 ua2 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p * a_skala * 0.83 + vec2(0.37, 0.11);
	float wa = smoothstep(0.35, 0.65, n1.b);
	vec3 alb = mix(texture(a_alb, ua).rgb, texture(a_alb, ua2).rgb, wa);
	vec3 nrm = nrm_mix(texture(a_nrm, ua).rgb, texture(a_nrm, ua2).rgb, wa);
	vec2 rh = mix(texture(a_rh, ua).rg, texture(a_rh, ua2).rg, wa);

	// warstwa B: plamy + ścieżki; przejście po wysokości (wypełnia spoiny najpierw)
	vec2 ub = p * b_skala;
	vec3 bb = texture(b_alb, ub).rgb;
	vec2 brh = texture(b_rh, ub).rg;
	float mb = clamp((n1.r - (1.0 - b_ilosc)) * 3.0 + mk.g * sciezka_b + (n2.g - 0.5) * 0.4, 0.0, 1.0);
	float tb = smoothstep(rh.g - 0.15, rh.g + 0.15, mb * 1.3 - 0.15 + brh.g * 0.3);
	alb = mix(alb, bb, tb);
	nrm = nrm_mix(nrm, texture(b_nrm, ub).rgb, tb);
	rh = mix(rh, brh, tb);

	// warstwa C: akcent (mech / popiół z żarem), gęstszy przy murach
	vec2 uc = p * c_skala;
	vec3 cc = texture(c_alb, uc).rgb;
	vec2 crh = texture(c_rh, uc).rg;
	float mc = clamp((n2.r - (1.0 - c_ilosc)) * 3.0 + mk.r * c_przy_murach - mk.g * sciezka_czysta, 0.0, 1.0);
	float tc = smoothstep(rh.g - 0.2, rh.g + 0.1, mc * 1.2 - 0.1 + (1.0 - rh.g) * 0.25);
	alb = mix(alb, cc, tc);
	nrm = nrm_mix(nrm, texture(c_nrm, uc).rgb, tc);
	rh = mix(rh, crh, tc);

	// zmienność w dużej skali + ciemnienie przy murach (kontakt cienia, brud)
	float makro = mix(0.78, 1.12, n1.g) * mix(0.92, 1.05, n2.b);
	float ao = 1.0 - mk.r * ao_murow;
	vec3 kol = alb * ton * makro * ao * jasnosc;
	kol *= mix(1.0, sciezka_jasn, smoothstep(0.15, 0.75, mk.g));
	float szorst = rh.r;

	// kałuże w zagłębieniach: ciemne, gładkie (odbicia SSR)
	if (kaluze > 0.0) {
		float w = smoothstep(0.62, 0.7, n2.g * 0.7 + (1.0 - rh.g) * 0.45 + mk.b * 0.25 - (1.0 - kaluze) * 0.5);
		kol = mix(kol, kol * 0.35 + kolor_wody, w * 0.85);
		szorst = mix(szorst, 0.06, w);
		nrm = nrm_mix(nrm, vec3(0.5, 0.5, 1.0), w * 0.9);
	}

	// pamięć mapy (widziane, ale nie teraz): wyblakłe i chłodne, jak w klasycznych grach izometrycznych
	float pamiec = 1.0 - smoothstep(0.6, 0.95, COLOR.r);
	float szar = dot(kol, vec3(0.3, 0.59, 0.11));
	kol = mix(kol, vec3(szar) * vec3(0.8, 0.88, 1.05), pamiec * 0.75);
	float brzeg = brzeg_mgly(p);
	ALBEDO = kol * COLOR.rgb * brzeg;
	ROUGHNESS = szorst;
	SPECULAR = 0.35;
	NORMAL_MAP = nrm;
	NORMAL_MAP_DEPTH = normalna;
	AO = mix(1.0, 0.35 + 0.65 * rh.g, 0.7);
	AO_LIGHT_AFFECT = 0.3;

	if (zar > 0.0) {
		// gorące piksele warstwy C (pomarańczowe w teksturze) świecą i pulsują w szumie
		float goraco = clamp((cc.r - cc.b * 1.3 - 0.12) * 4.0, 0.0, 1.0) * tc;
		float puls = 0.65 + 0.35 * sin(TIME * 1.7 + n2.r * 12.0);
		EMISSION = kolor_zaru * goraco * zar * puls * COLOR.r * brzeg;
	}
}
