extends RefCounted

var world
var art
var wood := Color("84674e")
var trim := Color("c7bba1")
var dark := Color("5d5145")
var glass := Color("577479")

func _init(land, artist) -> void:
	world = land
	art = artist

func cube(x: float,y: float,z: float,sx: float,sy: float,sz: float,c: Color) -> void:
	art.box(Vector3(x,y,z),Vector3(sx,sy,sz),c)

func house(x: float,z: float,sx: float,sz: float,wall: Color,roof: Color,kind: String) -> void:
	var y: float = world.ground_height(x,z)
	var w := sx*0.5
	var d := sz*0.5
	var h := 3.02 if kind != "oficina" else 3.48
	var door := 1.17 if kind != "oficina" else 2.0
	var hi := y+h
	cube(x,y+0.012,z,sx+0.5,0.07,sz+0.52,Color("807a67"))
	cube(x,y+0.055,z,sx-0.18,0.065,sz-0.18,wood)
	# The front doorway is physically open. Position and width match the collision grid.
	world.wall_rect(Rect2(x-w-0.08,z-d-0.08,0.16,sz+0.16))
	world.wall_rect(Rect2(x+w-0.08,z-d-0.08,0.16,sz+0.16))
	world.wall_rect(Rect2(x-w,z-d-0.09,sx,0.18))
	for s in [-1.0,1.0]:
		var span := w-door
		var cx: float = x+s*(door+0.5*span)
		world.wall_rect(Rect2(cx-span*0.5,z+d-0.12,span,0.24))
		# Front windows with deep sills and wood uprights.
		cube(cx,y+0.50,z+d,span,1.0,0.18,wall)
		cube(cx,hi-0.39,z+d,span,0.78,0.18,wall)
		cube(cx,y+(1.0+h-0.78)/2.0,z+d-0.035,span-0.18,h-1.78,0.063,glass)
		for side in [-1.0,1.0]:
			cube(cx+side*(span*0.5-0.092),y+h*0.5,z+d,0.18,h,0.21,trim)
		cube(cx,y+1.025,z+d+0.07,span,0.09,0.30,trim)
		cube(cx,y+1.63,z+d+0.049,0.06,1.32,0.07,dark)
		var side_x: float = x+s*w
		cube(side_x,y+0.55,z,0.21,1.10,sz,wall)
		cube(side_x,hi-0.40,z,0.21,0.8,sz,wall)
		cube(side_x,y+h*0.50,z,0.11,h-1.2,sz-0.18,glass)
		for part in [-0.46,-0.24,0.0,0.25,0.46]:
			cube(side_x,y+h*0.5,z+sz*part,0.24,h,0.21,trim)
	cube(x,hi-0.28,z+d,door*2,0.56,0.23,wall)
	cube(x,y+h*0.5,z-d,sx,h,0.20,wall)
	var pitch := 1.40 if kind!="oficina" else 0.82
	var a := Vector3(x-w-0.39,hi,z-d-0.45)
	var b := Vector3(x-w-0.39,hi,z+d+0.45)
	var ridge_a := Vector3(x,hi+pitch,z-d-0.45)
	var ridge_b := Vector3(x,hi+pitch,z+d+0.45)
	var c := Vector3(x+w+0.39,hi,z+d+0.45)
	var e := Vector3(x+w+0.39,hi,z-d-0.45)
	art.panel(a,b,ridge_b,ridge_a,Vector3.UP,roof.darkened(0.06))
	art.panel(ridge_a,ridge_b,c,e,Vector3.UP,roof)
	for side in [-1.0,1.0]:
		var zz: float = z+side*d
		art.face(Vector3(x-w,hi,zz),Vector3(x+w,hi,zz),Vector3(x,hi+pitch,zz),Vector3(0,0,side),wall)
		world.rod(Vector3(x-w-0.41,hi,zz+side*0.455),Vector3(x,hi+pitch,zz+side*0.455),0.083,trim)
		world.rod(Vector3(x,hi+pitch,zz+side*0.455),Vector3(x+w+0.41,hi,zz+side*0.455),0.083,trim)
	for i in range(1,19):
		var f := i/19.0
		world.rod(a.lerp(b,f),ridge_a.lerp(ridge_b,f),0.024,roof.lightened(0.075))
		world.rod(e.lerp(c,f),ridge_a.lerp(ridge_b,f),0.024,roof.lightened(0.075))
	if kind=="abrigo":
		# Cot with a folded blanket, table, open shutter and old brick chimney.
		cube(x-w+1.1,y+0.28,z-0.7,1.15,0.42,2.2,dark)
		cube(x-w+1.1,y+0.52,z-0.7,1.16,0.16,2.17,Color("8e947c"))
		cube(x-w+1.1,y+0.62,z-1.40,0.72,0.12,0.42,trim)
		cube(x-w+1.1,y+0.615,z-0.24,1.17,0.045,1.10,Color("915847"))
		cube(x+w-0.9,y+0.79,z-1.18,1.4,0.13,1.06,wood)
		for side in [-0.52,0.52]:
			cube(x+w-0.9+side,y+0.39,z-1.18,0.11,0.76,0.85,dark)
		cube(x-w*0.48,hi+0.81,z-d*0.3,0.67,1.59,0.64,Color("a6775f"))
		cube(x-w*0.48,hi+1.60,z-d*0.3,0.75,0.12,0.74,dark)
		cube(x+door-0.045,y+1.11,z+d-0.69,0.11,2.12,1.35,Color("71806c"))
		world.plate("CASA DO VALE",Vector3(x,hi-0.24,z+d+0.14),0.0067)
	elif kind=="mercado":
		cube(x,hi-0.14,z+d+0.11,sx-0.42,0.61,0.14,Color("474f43"))
		world.plate("ARMAZÉM  •  SERRA",Vector3(x,hi-0.15,z+d+0.20),0.010)
		var awning_width := sx*0.95
		for j in range(11):
			var px := x-awning_width*0.5+awning_width*j/11
			var pw := awning_width/11
			art.panel(Vector3(px,hi-0.52,z+d),Vector3(px+pw,hi-0.52,z+d),Vector3(px+pw,hi-0.83,z+d+1.32),Vector3(px,hi-0.83,z+d+1.32),Vector3.UP,Color("b17a57") if j%2==0 else trim)
			cube(px+pw*0.5,hi-0.92,z+d+1.32,pw,0.19,0.045,Color("b17a57") if j%2==0 else trim)
		for i in range(3):
			cube(x-w+0.65,y+0.35+i*0.69,z-0.22,0.88,0.11,sz*0.72,wood)
			for j in range(5):
				cube(x-w+0.63,y+0.51+i*0.69,z-d+0.78+j*0.77,0.28,0.22,0.29,Color("a59968") if j%2==0 else Color("987155"))
	else:
		cube(x,hi-0.24,z+d+0.1,sx*0.78,0.57,0.19,Color("555f5b"))
		world.plate("OFICINA  •  ESTAÇÃO",Vector3(x,hi-0.25,z+d+0.21),0.0094)
		cube(x-w+0.88,y+0.86,z-0.55,1.46,0.18,sz*0.65,wood)
		for j in range(3):
			cube(x-w+0.87,y+0.42,z-d+1.23+j*1.45,1.02,0.77,0.57,Color("6e776b"))
		for j in range(3):
			art.band(Vector3(x+w-1.03,y+0.15+0.24*j,z-d+1.05),0.24,Vector2(0.55,0.55),Vector2(0.55,0.55),Color("414641"),12)

func bridge() -> void:
	var x := -4.0
	var low := -23.7
	var high := -8.3
	for j in range(49):
		var z := lerpf(low,high,j/48.0)
		var y: float = world.ground_height(x,z)
		cube(x,y-0.105,z,5.12,0.215,0.305,wood.lightened(0.025*(j%3)))
	for s in [-1.0,1.0]:
		var px: float = x+2.61*s
		for j in range(8):
			var z := lerpf(low,high,j/7.0)
			var y: float = world.ground_height(x,z)
			cube(px,y-0.35,z,0.21,2.73,0.22,dark)
			if j<7:
				var nz := lerpf(low,high,(j+1)/7.0)
				var ny: float = world.ground_height(x,nz)
				for lift in [0.46,0.95]:
					world.rod(Vector3(px,y+lift,z),Vector3(px,ny+lift,nz),0.089,trim)

func reservoir() -> void:
	var x := -37.0
	var z := -57.1
	var y: float = world.ground_height(x,z)
	world.wall_rect(Rect2(x-2.43,z-2.43,4.86,4.86))
	for sx in [-1.65,1.65]:
		for sz in [-1.65,1.65]:
			cube(x+sx,y+1.87,z+sz,0.29,3.74,0.29,dark)
			world.rod(Vector3(x+sx,y+0.48,z+sz),Vector3(x-sx,y+3.37,z+sz),0.11,trim)
			world.rod(Vector3(x+sx,y+0.48,z+sz),Vector3(x+sx,y+3.37,z-sz),0.11,trim)
	var tank := Color("8e9d94")
	art.band(Vector3(x,y+5.03,z),3.31,Vector2(2.23,2.23),Vector2(2.27,2.27),tank,20)
	art.band(Vector3(x,y+6.96,z),0.65,Vector2(2.40,2.40),Vector2(0.71,0.71),Color("65786c"),20)
	for lift in [3.66,4.61,5.64,6.62]:
		art.band(Vector3(x,y+lift,z),0.095,Vector2(2.30,2.30),Vector2(2.30,2.30),Color("657365"),20)
	for sx in [-0.26,0.26]:
		cube(x+sx,y+3.49,z+2.43,0.072,6.73,0.072,wood)
	for j in range(20):
		cube(x,y+0.38+j*0.32,z+2.43,0.53,0.045,0.06,wood)
	world.signboard("RESERVATÓRIO",Vector2(-38.8,-52.9))

func lookout() -> void:
	var x := 16.0
	var z := -67.6
	var y: float = world.ground_height(x,z)
	cube(x,y+0.08,z,6.18,0.18,4.5,wood)
	for side in [-1.0,1.0]:
		for zz in [-2.1,2.1]:
			cube(x+side*2.93,y+1.50,z+zz,0.22,3.0,0.24,dark)
		cube(x+side*2.94,y+0.86,z,0.11,0.13,4.34,trim)
		cube(x+side*2.94,y+0.55,z,0.09,0.085,4.34,trim)
	cube(x,y+0.86,z-2.1,5.88,0.14,0.12,trim)
	cube(x,y+3.12,z,6.73,0.17,4.96,Color("737c67"))
	cube(x-1.1,y+0.54,z-1.10,2.2,0.15,0.56,wood)
	for xx in [-1.89,-0.31]:
		cube(x+xx,y+0.32,z-1.11,0.12,0.48,0.41,dark)
	world.signboard("MIRANTE  •  823 m",Vector2(18.9,-63.2))

func build() -> void:
	house(-8,35.7,7.6,7.8,Color("b69770"),Color("87554a"),"abrigo")
	house(14,11.25,8.85,5.92,Color("a9afa0"),Color("7b7d69"),"mercado")
	house(-29,38.1,9.65,7.05,Color("909b94"),Color("687874"),"oficina")
	bridge()
	reservoir()
	lookout()
