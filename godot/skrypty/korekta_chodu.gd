extends SkeletonModifier3D
## Korekta chodu Hadræna (autor 26.11: „chodzi rozkrokiem jak kowboj po zejściu z konia”).
## Animacje chodu i biegu z Mixamo mają kolana o ok. 25–40% szerzej niż biodra. Po animacji (modyfikator
## szkieletu) przesuwamy kolano ku linii biodra: ściągamy boczną część kierunku uda o „sila”.
## Siłę (influence) ustawia swiat3d według ruchu: w biegu i chodzie pełna, w postoju zero (postawa bojowa zostaje).

@export var sila := 0.75   # 0 = animacja bez zmian, 1 = kolano dokładnie pod stawem biodrowym (do strojenia)
var _udo := [-1, -1]
var _kolano := [-1, -1]


func _ready() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	_udo = [sk.find_bone("mixamorig_LeftUpLeg"), sk.find_bone("mixamorig_RightUpLeg")]
	_kolano = [sk.find_bone("mixamorig_LeftLeg"), sk.find_bone("mixamorig_RightLeg")]


func _process_modification_with_delta(_delta: float) -> void:

	var sk := get_skeleton()
	if sk == null or _udo[0] < 0 or _udo[1] < 0 or _kolano[0] < 0 or _kolano[1] < 0:
		return
	var biodro := [sk.get_bone_global_pose(_udo[0]).origin, sk.get_bone_global_pose(_udo[1]).origin]
	for s in 2:
		var udo: int = _udo[s]
		var g := sk.get_bone_global_pose(udo)
		var kol := sk.get_bone_global_pose(_kolano[s]).origin
		var na_zewn: Vector3 = (biodro[s] - biodro[1 - s])
		if na_zewn.length() < 0.0001:
			continue
		na_zewn = na_zewn.normalized()
		var v := kol - g.origin
		var bok := v.dot(na_zewn)
		if bok <= 0.0:
			continue  # kolano już pod biodrem albo do środka — nic nie ruszamy
		var v2 := v - na_zewn * bok * sila
		var q := Quaternion(v.normalized(), v2.normalized())
		var nowa := Basis(q) * g.basis
		var rodzic := sk.get_bone_parent(udo)
		var lok := nowa if rodzic < 0 else sk.get_bone_global_pose(rodzic).basis.inverse() * nowa
		sk.set_bone_pose_rotation(udo, lok.get_rotation_quaternion())
