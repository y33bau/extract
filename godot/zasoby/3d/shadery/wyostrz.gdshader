// Delikatne wyostrzenie obrazu 3D (maska nieostra): krawędzie postaci i faktury ostrzejsze.
shader_type canvas_item;
uniform sampler2D ekran : hint_screen_texture, filter_linear_mipmap;
uniform float sila = 0.45;
void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 c = texture(ekran, SCREEN_UV).rgb;
	vec3 b = (texture(ekran, SCREEN_UV + vec2(px.x, 0.0)).rgb + texture(ekran, SCREEN_UV - vec2(px.x, 0.0)).rgb
		+ texture(ekran, SCREEN_UV + vec2(0.0, px.y)).rgb + texture(ekran, SCREEN_UV - vec2(0.0, px.y)).rgb) * 0.25;
	COLOR = vec4(max(c + (c - b) * sila, vec3(0.0)), 1.0);
}
