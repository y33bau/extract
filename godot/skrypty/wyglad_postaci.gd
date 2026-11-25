extends RefCounted
## Wygląd postaci 3D (bohater, wrogowie, NPC): zamiast jasnej nakładki na całą sylwetkę — krawędź światła
## wbudowana w materiał (świeci tylko tam, gdzie pada światło, w kolorze tego światła) i lekko cieplejsza skóra.
## Materiały z importu GLB są wspólne dla wszystkich kopii modelu, więc ustawiamy je raz na model.

static var _gotowe := {}


static func ozyw(n: Node, rim := 0.45, tint := 0.35) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.material_overlay = null
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
			if mat == null or _gotowe.has(mat.get_instance_id()):
				continue
			_gotowe[mat.get_instance_id()] = true
			mat.rim_enabled = true
			mat.rim = rim
			mat.rim_tint = tint
			mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
			mat.normal_scale = maxf(mat.normal_scale, 1.0)


## Własne światło postaci: ciepło-neutralna lampa nad postacią, oświetla TYLKO postacie (warstwa 2),
## więc ubrania i twarze mają prawdziwe kolory, a świat zostaje mroczny. Bez cieni (tanie).
const WARSTWA_POSTACI := 2


static func swiatlo_postaci(n: Node3D, energia := 1.1, zasieg := 3.6, wys := 2.3) -> OmniLight3D:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = 1 | WARSTWA_POSTACI
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.9, 0.78)
	l.light_energy = energia
	l.omni_range = zasieg
	l.omni_attenuation = 0.8
	l.light_cull_mask = WARSTWA_POSTACI
	l.shadow_enabled = false
	l.light_specular = 0.35
	l.position = Vector3(0.35, wys, 0.6)
	n.add_child(l)
	return l
