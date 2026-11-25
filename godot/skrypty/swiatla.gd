extends Node
## Wspólna tekstura światła i fabryka świateł 2D (pochodnie, kosze, kręgi).

var tekstura: GradientTexture2D


func _ready() -> void:
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1, 1, 1, 1))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	g.set_offset(g.get_point_count() - 1, 1.0)
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	tekstura = GradientTexture2D.new()
	tekstura.gradient = g
	tekstura.fill = GradientTexture2D.FILL_RADIAL
	tekstura.fill_from = Vector2(0.5, 0.5)
	tekstura.fill_to = Vector2(1.0, 0.5)
	tekstura.width = 256
	tekstura.height = 256


## promien w pikselach ekranu (jak w wersji JS)
func nowe(kolor: Color, energia: float, promien: float) -> PointLight2D:
	var s := PointLight2D.new()
	s.texture = tekstura
	s.color = kolor
	s.energy = energia
	s.texture_scale = promien * 2.0 / 256.0
	return s
