shader_type spatial;
render_mode cull_disabled, unshaded;  // stała, czytelna jasność (nie zależy od księżyca krainy)
// Głębia zamiast czarnej pustki (prośba autora 26.11): wierzch litej skały w lochu, korony lasu w Czarnoborze
// i to samo „dalej” poza granicą mapy, ciemniejące z odległością aż w tło (wewnątrz mapy płaszczyzna znika).
// COLOR (kolor instancji) = jasność mgły wojny (wierzch skały wewnątrz mapy); poza mapą COLOR = biały.
uniform sampler2D alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D szum : filter_linear_mipmap, repeat_enable;
uniform float skala = 0.25;
uniform vec4 ton : source_color = vec4(0.4, 0.4, 0.42, 1.0);
uniform float rozmiar_mapy = 128.0;
uniform float poza_mapa = 0.0;     // 1 = płaszczyzna poza mapą (gaśnie z odległością od krawędzi, wewnątrz czarna)
uniform float zasieg_gasniecia = 40.0;
uniform float jasnosc_poza = 1.6;   // poza mapą jaśniej niż wierzch w mapie: głębia ma być czytelna, nie czarna smuga
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

#include "res://zasoby/3d/shadery/mgla_gladka.gdshaderinc"

void vertex() {
	swiat = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = swiat.xz;
	vec3 a = texture(alb, p * skala).rgb;
	vec3 n = texture(szum, p * 0.018).rgb;
	// plamy i przebarwienia: nie powtarza się w kratkę
	float plamy = 0.62 + 0.55 * n.r + 0.25 * (n.g - 0.5);
	float jasn = mgla_gladka ? jas_gladka(p) : COLOR.r;
	if (poza_mapa > 0.5) {
		vec2 d = max(vec2(0.0) - p, p - vec2(rozmiar_mapy));
		float odl = length(max(d, vec2(0.0)));
		if (odl < 0.45) {
			discard;  // wewnątrz granic mapy nic nie zasłania (mapa ma własny wierzch skały / korony)
		}
		jasn = jasnosc_poza * (1.0 - smoothstep(0.0, zasieg_gasniecia, odl)) * (0.75 + 0.35 * n.b);
	}
	// kontrast faktury: kamień/liście widać jako fakturę, nie płaską plamę
	vec3 f = pow(a, vec3(0.85)) * (0.55 + 0.9 * dot(a, vec3(0.33)));
	// wierzch skały / korony: bez miękkiego brzegu — sama skała nigdy nie jest „odkryta” (wzrok staje na murze);
	// wyłania się płynnie razem z przejściem, przy którym leży (COLOR)
	ALBEDO = f * ton.rgb * plamy * jasn;
}
