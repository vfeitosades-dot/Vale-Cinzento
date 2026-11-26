extends Node3D

# Static geometry shares one surface per batch. Coordinates use metres and +Z is south.
var _surface: SurfaceTool
var _paint: StandardMaterial3D

func begin_batch() -> void:
	if _paint == null:
		_paint = StandardMaterial3D.new()
		_paint.vertex_color_use_as_albedo = true
		_paint.vertex_color_is_srgb = true
		_paint.roughness = 0.94
	_surface = SurfaceTool.new()
	_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface.set_material(_paint)

func finish_batch(label: String) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = label
	_surface.index()
	result.mesh = _surface.commit()
	add_child(result)
	return result

func tri(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.length_squared() < 0.5:
		return
	# Godot's front faces wind clockwise viewed from outside.
	for point: Vector3 in [a, c, b]:
		_surface.set_color(color)
		_surface.set_normal(n)
		_surface.add_vertex(point)

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	tri(a, b, c, color)
	tri(a, c, d, color)

func block(p: Vector3, dimensions: Vector3, color: Color) -> void:
	var h := dimensions * 0.5
	var a := p - h
	var b := p + h
	var v0 := Vector3(a.x, a.y, a.z)
	var v1 := Vector3(b.x, a.y, a.z)
	var v2 := Vector3(b.x, a.y, b.z)
	var v3 := Vector3(a.x, a.y, b.z)
	var v4 := Vector3(a.x, b.y, a.z)
	var v5 := Vector3(b.x, b.y, a.z)
	var v6 := Vector3(b.x, b.y, b.z)
	var v7 := Vector3(a.x, b.y, b.z)
	quad(v0, v4, v5, v1, color)
	quad(v1, v5, v6, v2, color)
	quad(v2, v6, v7, v3, color)
	quad(v3, v7, v4, v0, color)
	quad(v4, v7, v6, v5, color)
	quad(v0, v1, v2, v3, color.darkened(0.1))

func frustum(base: Vector3, height: float, bottom: float, top: float, sides: int, color: Color, shift := Vector2.ZERO, angle := 0.0) -> void:
	var summit := base + Vector3(shift.x, height, shift.y)
	for i in range(sides):
		var a := TAU * float(i) / sides + angle
		var b := TAU * float(i + 1) / sides + angle
		var u := Vector3(cos(a), 0, sin(a))
		var v := Vector3(cos(b), 0, sin(b))
		var low_a := base + u * bottom
		var low_b := base + v * bottom
		var high_a := summit + u * top
		var high_b := summit + v * top
		var tint := color.darkened(0.038 * float(i % 3))
		quad(low_a, high_a, high_b, low_b, tint)
		if top > 0.001:
			tri(summit, high_b, high_a, color)
		if bottom > 0.001:
			tri(base, low_a, low_b, color)

func beam(a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var axis := (b - a).normalized()
	var reference := Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT
	var ex := reference.cross(axis).normalized() * width * 0.5
	var ey := axis.cross(ex).normalized() * width * 0.5
	var corners: Array[Vector3] = [-ex-ey, ex-ey, ex+ey, -ex+ey]
	for i in range(4):
		var j := (i + 1) % 4
		quad(a + corners[i], a + corners[j], b + corners[j], b + corners[i], color)
	quad(b+corners[0], b+corners[1], b+corners[2], b+corners[3], color)
	quad(a+corners[3], a+corners[2], a+corners[1], a+corners[0], color)

func pitched_roof(p: Vector3, w: float, d: float, rise: float, color: Color) -> void:
	var a := p + Vector3(-w * 0.5, 0, -d * 0.5)
	var b := p + Vector3(w * 0.5, 0, -d * 0.5)
	var c := p + Vector3(w * 0.5, 0, d * 0.5)
	var e := p + Vector3(-w * 0.5, 0, d * 0.5)
	var r1 := p + Vector3(-w * 0.5, rise, 0)
	var r2 := p + Vector3(w * 0.5, rise, 0)
	quad(a, r1, r2, b, color.darkened(0.06))
	quad(e, c, r2, r1, color)
	tri(a, e, r1, color.darkened(0.2))
	tri(b, r2, c, color.darkened(0.2))
	quad(a, b, c, e, color.darkened(0.24))
