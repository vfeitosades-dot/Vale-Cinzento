extends "res://world/geometry.gd"

const WOOD := Color("#765438")
const BARK := Color("#51473b")
const BEAM := Color("#453e33")
const METAL := Color("#525d59")
const STONE := Color("#919387")
const CREAM := Color("#dfd2ab")
const GLASS := Color("#516b6c")
const TILE := Color("#a15f41")
const RED := Color("#a7593c")
const GREEN := Color("#526952")

var walls: Array[Rect2] = []
var home_roof: MeshInstance3D

func ground_height(_x: float, _z: float) -> float:
	return 0.0

func obstacle(p: Vector3, sx: float, sz: float) -> void:
	walls.append(Rect2(p.x - sx * 0.5, p.z - sz * 0.5, sx, sz))

func column(p: Vector3, height: float, width: float, color: Color) -> void:
	block(p + Vector3.UP * height * 0.5, Vector3(width, height, width), color)

func wall(p: Vector3, sx: float, sy: float, sz: float, color: Color) -> void:
	block(p + Vector3.UP * sy * 0.5, Vector3(sx, sy, sz), color)
	obstacle(p, sx, sz)

func label_at(p: Vector3, words: String, scale_px: float, tint := Color("#eee4c8")) -> void:
	var sign_text := Label3D.new()
	sign_text.text = words
	sign_text.font_size = 48
	sign_text.pixel_size = scale_px
	sign_text.outline_size = 0
	sign_text.modulate = tint
	sign_text.position = p
	sign_text.double_sided = true
	add_child(sign_text)

func facade_window(p: Vector3, w: float, h: float, shutters := true) -> void:
	block(p, Vector3(w + 0.18, h + 0.18, 0.10), BEAM)
	block(p + Vector3(0, 0, 0.07), Vector3(w, h, 0.08), GLASS)
	block(p + Vector3(0, 0, 0.14), Vector3(0.06, h, 0.06), CREAM)
	block(p + Vector3(0, -0.11, 0.14), Vector3(w, 0.06, 0.06), CREAM)
	block(p + Vector3(0, -h * 0.55, 0.13), Vector3(w+0.32, 0.11, 0.30), STONE)
	if shutters:
		for side in [-1, 1]:
			var offset := Vector3(side * (w * 0.5 + 0.24), 0, 0.035)
			block(p + offset, Vector3(0.35, h + 0.14, 0.12), GREEN)
			for row in range(4):
				block(p + offset + Vector3(0, h * (row - 1.5) * 0.20, 0.08), Vector3(0.31, 0.043, 0.04), BEAM)

func crate(p: Vector3, size: float, color: Color) -> void:
	block(p + Vector3.UP * size * 0.46, Vector3(size, size * 0.92, size * 0.84), color)
	for y in [0.15, 0.74]:
		block(p + Vector3(0, y*size, size*0.425), Vector3(size*1.04, size*0.09, 0.055), BEAM)
	beam(p + Vector3(-0.44*size,0.14*size,0.45*size), p + Vector3(0.44*size,0.79*size,0.45*size),size*0.09,WOOD)

func bench(p: Vector3, w := 2.3) -> void:
	for side in [-1, 1]:
		column(p+Vector3(side*w*0.34,0,0),0.48,0.18,METAL)
	block(p+Vector3(0,0.49,0),Vector3(w,0.13,0.57),WOOD)
	block(p+Vector3(0,0.90,-0.24),Vector3(w,0.35,0.10),WOOD)

func signpost(x: float, z: float, words: String) -> void:
	var p := Vector3(x,ground_height(x,z),z)
	column(p,2.12,0.14,WOOD)
	block(p+Vector3(0,1.85,0), Vector3(3.16,0.65,0.16), GREEN)
	block(p+Vector3(0,1.51,0), Vector3(3.26,0.085,0.18), CREAM)
	label_at(p+Vector3(0,1.85,0.095),words,0.006)

func build_home() -> void:
	var p := Vector3(-8,ground_height(-8,35),35)
	var plaster := Color("#bbc0a6")
	block(p+Vector3(0,-0.04,0),Vector3(8.8,0.20,7.1),STONE)
	# South wall has a generous opening exactly in line with the approach.
	wall(p+Vector3(-2.63,0,3.32),3.04,2.76,0.24,plaster)
	wall(p+Vector3(2.63,0,3.32),3.04,2.76,0.24,plaster)
	wall(p+Vector3(-4.10,0,0),0.26,2.76,6.9,plaster)
	wall(p+Vector3(4.10,0,0),0.26,2.76,6.9,plaster)
	wall(p+Vector3(0,0,-3.31),8.32,2.76,0.26,plaster)
	block(p+Vector3(0,2.56,3.32),Vector3(2.28,0.39,0.26),plaster)
	for side in [-1,1]:
		facade_window(p+Vector3(side*2.72,1.5,3.47),1.16,0.98)
		column(p+Vector3(side*3.68,0,4.84),2.26,0.14,WOOD)
		block(p+Vector3(side*1.07,1.15,3.48),Vector3(0.13,2.30,0.18),BEAM)
	block(p+Vector3(0,2.29,3.48),Vector3(2.24,0.14,0.18),BEAM)
	block(p+Vector3(0,0.01,4.09),Vector3(8.0,0.14,1.66),WOOD)
	# Cot, hand-woven blanket, table and an enamel mug.
	block(p+Vector3(-2.65,0.24,-0.8),Vector3(1.62,0.42,2.42),WOOD)
	block(p+Vector3(-2.65,0.52,-0.78),Vector3(1.58,0.22,2.34),CREAM)
	block(p+Vector3(-2.65,0.65,-0.27),Vector3(1.60,0.06,1.22),RED)
	for stripe in range(3):
		block(p+Vector3(-2.65,0.69,-0.70+stripe*0.22),Vector3(1.59,0.018,0.065),CREAM)
	block(p+Vector3(-2.66,0.69,-1.55),Vector3(1.29,0.20,0.47),Color("#cec7ae"))
	obstacle(p+Vector3(-2.65,0,-0.8),1.65,2.45)
	for x in [-0.65,0.65]:
		for z in [-0.34,0.34]:
			column(p+Vector3(2.15+x,0,-1.45+z),0.86,0.12,WOOD)
	block(p+Vector3(2.15,0.90,-1.45),Vector3(1.66,0.13,1),WOOD)
	frustum(p+Vector3(2.32,0.97,-1.42),0.21,0.13,0.15,8,CREAM)
	obstacle(p+Vector3(2.15,0,-1.45),1.75,1.0)
	var porch := p+Vector3(0,2.28,4.1)
	block(porch,Vector3(8.3,0.15,1.85),TILE.darkened(0.17))
	label_at(p+Vector3(0,2.58,3.49),"POSTO DO VALE",0.0045)
	finish_batch("Abrigo")
	begin_batch()
	pitched_roof(p+Vector3(0,2.8,0),9.3,7.75,1.67,TILE)
	for row in range(13):
		var x := -4.45 + row * 0.73
		beam(p+Vector3(x,2.83,3.88),p+Vector3(x,4.50,0),0.065,TILE.lightened(0.12))
	block(p+Vector3(-2.7,3.79,-1.21),Vector3(0.60,1.76,0.63),RED)
	block(p+Vector3(-2.7,4.68,-1.21),Vector3(0.78,0.19,0.82),BEAM)
	home_roof = finish_batch("Telhado_do_posto")
	begin_batch()

func build_market() -> void:
	var p := Vector3(14,ground_height(14,10.1),10.1)
	wall(p,8.8,3.10,6.5,Color("#cfb481"))
	facade_window(p+Vector3(-2.63,1.55,3.30),1.55,1.28,false)
	facade_window(p+Vector3(2.64,1.55,3.30),1.50,1.28,false)
	block(p+Vector3(0,1.15,3.31),Vector3(1.36,2.3,0.12),BEAM)
	pitched_roof(p+Vector3(0,3.1,0),9.58,7.4,1.18,Color("#8a6245"))
	block(p+Vector3(0,2.93,3.44),Vector3(6.36,0.59,0.18),GREEN)
	label_at(p+Vector3(0,2.94,3.55),"ARMAZÉM  DO  VALE",0.007)
	for i in range(12):
		var x := -4.18 + i * 0.76
		var tint := CREAM if i%2==0 else RED
		var a := p+Vector3(x-0.38,2.64,3.41)
		var b := p+Vector3(x+0.38,2.64,3.41)
		var c := p+Vector3(x+0.38,2.25,4.9)
		var d := p+Vector3(x-0.38,2.25,4.9)
		quad(d,c,b,a,tint)
		block(p+Vector3(x,2.13,4.9),Vector3(0.76,0.25,0.075),tint)
	for side in [-1,1]:
		column(p+Vector3(side*4.28,0,4.85),2.29,0.09,BEAM)
		crate(p+Vector3(side*3.16,0,4.05),0.77,WOOD)
		for apple in range(5):
			var fruit := p+Vector3(side*3.16-0.25+(apple%3)*0.21,0.71,3.93+floori(apple/3.0)*0.22)
			frustum(fruit,0.16,0.11,0.067,6,RED if side>0 else Color("#9ba944"))

func build_garage() -> void:
	var p := Vector3(-29,ground_height(-29,37),37)
	wall(p,10.1,3.7,7.1,Color("#84938c"))
	pitched_roof(p+Vector3(0,3.78,0),10.9,7.85,1.22,METAL)
	for i in range(13):
		var x := -4.7 + i*0.79
		block(p+Vector3(x,1.7,3.57),Vector3(0.068,3.35,0.06),Color("#a0aba0"))
	block(p+Vector3(0,1.37,3.61),Vector3(5.4,2.77,0.13),BEAM)
	for j in range(8):
		block(p+Vector3(0,0.22+j*0.33,3.70),Vector3(5.16,0.24,0.07),Color("#666e63"))
	block(p+Vector3(0,3.20,3.71),Vector3(5.73,0.63,0.15),CREAM)
	label_at(p+Vector3(0,3.21,3.81),"OFICINA  ESTAÇÃO",0.006,BEAM)
	for side in [-1,1]:
		var drum := p+Vector3(side*4.08,0,4.09)
		frustum(drum,1.0,0.45,0.45,12,RED)
		for y in [0.16,0.72]:
			frustum(drum+Vector3.UP*y,0.075,0.47,0.47,12,METAL)
	crate(p+Vector3(4.04,0,5.12),0.79,WOOD)

func build_reservoir() -> void:
	var p := Vector3(-36,ground_height(-36,-58),-58)
	for sx in [-1,1]:
		for sz in [-1,1]:
			var foot := p+Vector3(sx*2.00,0,sz*2.0)
			column(foot,4.95,0.24,METAL)
			obstacle(foot,0.28,0.28)
			if sx < 0:
				beam(foot+Vector3.UP*0.55,foot+Vector3(4,3.85,0),0.13,METAL)
			if sz < 0:
				beam(foot+Vector3.UP*0.55,foot+Vector3(0,3.85,4),0.13,METAL)
	frustum(p+Vector3.UP*4.7,0.8,2.36,3.24,18,Color("#748e87"))
	frustum(p+Vector3.UP*5.5,3.1,3.24,3.24,18,Color("#a4b8aa"))
	for y in [5.7,7.12,8.55]:
		frustum(p+Vector3.UP*y,0.12,3.31,3.31,18,METAL)
	frustum(p+Vector3.UP*8.66,0.82,3.43,0.20,18,GREEN)
	frustum(p+Vector3(3.0,0,1.2),5.7,0.17,0.17,8,Color("#779b92"))
	label_at(p+Vector3(0,7.32,3.32),"ÁGUA   •   03",0.011,BEAM)
	signpost(-39.1,-52.5,"RESERVATÓRIO")

func build_lookout() -> void:
	var p := Vector3(20,ground_height(20,-66),-66)
	for sx in [-1,1]:
		for sz in [-1,1]:
			var foot := p + Vector3(sx*1.85,0,sz*1.80)
			column(foot,6.12,0.26,WOOD)
			obstacle(foot,0.32,0.32)
			if sx < 0:
				beam(foot+Vector3.UP*0.3,foot+Vector3(3.7,3.78,0),0.18,WOOD)
			if sz < 0:
				beam(foot+Vector3.UP*0.3,foot+Vector3(0,3.78,3.6),0.18,WOOD)
	block(p+Vector3.UP*3.81,Vector3(4.36,0.23,4.19),WOOD)
	for side in [-1,1]:
		block(p+Vector3(0,4.83,side*1.84),Vector3(3.99,0.17,0.12),CREAM)
		block(p+Vector3(side*1.86,4.83,0),Vector3(0.12,0.17,3.8),CREAM)
	pitched_roof(p+Vector3.UP*6.1,4.99,4.80,1.15,GREEN)
	for sx in [-0.41,0.41]:
		beam(p+Vector3(sx,0,3.98),p+Vector3(sx,3.85,1.82),0.09,METAL)
	for i in range(11):
		var t := i/11.0
		block(p+Vector3(0,0.22+3.55*t,3.88-2.0*t),Vector3(0.89,0.075,0.17),WOOD)
	bench(p+Vector3(-5.0,0,-1.4))
	signpost(13.1,-63.8,"MIRANTE DO NORTE")

func set_observer(pos: Vector2) -> void:
	if is_instance_valid(home_roof):
		home_roof.visible = not Rect2(-12.2,31.4,8.4,7.4).has_point(pos)
