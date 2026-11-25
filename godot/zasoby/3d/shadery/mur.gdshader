// Mury lochu: tekstura w rzucie trójpłaszczyznowym w przestrzeni świata (bez szwów między blokami),
// brud i mech/sadza przy podstawie, wytarte krawędzie u góry, ciemniejsza korona muru.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D m_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D m_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D m_rh : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D d_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable; // dolny akcent (mech / sadza)
uniform sampler2D szum : filter_linear, repeat_enable;
uniform float skala = 0.5;
uniform float d_skala = 0.5;
uniform vec3 ton : source_color = vec3(1.0);
uniform float jasnosc = 1.0;
uniform float wys_akcentu = 0.55;
uniform float sila_akcentu = 0.8;
uniform vec3 korona : source_color = vec3(0.55);
uniform float normalna = 1.2;
uniform float zar = 0.0;
uniform vec3 kolor_zaru : source_color = vec3(1.0, 0.3, 0.06);

varying vec3 swiat;
varying vec3 nsw;

void vertex() {
	swiat = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	nsw = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 an = abs(nsw);
	vec2 uv;
	if (an.y > 0.7) {
		uv = swiat.xz * skala;
	} else if (an.x > an.z) {
		uv = vec2(swiat.z, -swiat.y) * skala;
	} else {
		uv = vec2(swiat.x, -swiat.y) * skala;
	}
	vec3 alb = texture(m_alb, uv).rgb;
	vec3 nrm = texture(m_nrm, uv).rgb;
	vec2 rh = texture(m_rh, uv).rg;
	vec3 n = texture(szum, swiat.xz * 0.11 + swiat.y * 0.07).rgb;
	float h = swiat.y;
	// podstawa: wilgoć, mech albo sadza wspinają się nierówno po murze
	float granica = wys_akcentu * (0.55 + 0.9 * n.r);
	float dol = (1.0 - smoothstep(granica - 0.25, granica + 0.05, h + (rh.g - 0.5) * 0.35)) * sila_akcentu;
	vec3 akc = texture(d_alb, uv * d_skala / skala).rgb;
	alb = mix(alb, akc, dol * step(an.y, 0.7));
	// kontakt z podłogą
	float kontakt = mix(0.45, 1.0, smoothstep(0.0, 0.35, h));
	// korona muru: ciemniejsza, chropowata
	if (an.y > 0.7) {
		alb = alb * korona * (0.75 + 0.5 * n.g);
	}
	float makro = mix(0.8, 1.1, n.b);
	vec3 kolm = alb * ton * makro * kontakt * jasnosc;
	float pamiec = 1.0 - smoothstep(0.6, 0.95, COLOR.r);
	kolm = mix(kolm, vec3(dot(kolm, vec3(0.3, 0.59, 0.11))) * vec3(0.8, 0.88, 1.05), pamiec * 0.75);
	ALBEDO = kolm * COLOR.rgb;
	ROUGHNESS = mix(rh.r, 1.0, 0.2);
	NORMAL_MAP = nrm;
	NORMAL_MAP_DEPTH = normalna;
	AO = 0.4 + 0.6 * rh.g;
	AO_LIGHT_AFFECT = 0.35;
	if (zar > 0.0) {
		float g = clamp((alb.r - alb.b * 1.4 - 0.1) * 4.0, 0.0, 1.0) * (1.0 - smoothstep(0.0, 0.8, h));
		EMISSION = kolor_zaru * g * zar * (0.7 + 0.3 * sin(TIME * 1.3 + n.r * 9.0)) * COLOR.r;
	}
}
