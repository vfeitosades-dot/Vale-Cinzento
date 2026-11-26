extends RefCounted

# Bake each rigid part into one vertex-coloured mesh and animate only its joints.
var batch: SurfaceTool
var material := StandardMaterial3D.new()

func _init() -> void:
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.84

func begin_part() -> void:
	batch = SurfaceTool.new()
	batch.begin(Mesh.PRIMITIVE_TRIANGLES)
	batch.set_material(material)

func joint(parent: Node3D, joint_name: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = joint_name
	parent.add_child(node)
	node.position = at
	return node

func finish(parent: Node3D) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = batch.commit()
	parent.add_child(instance)

func face(a: Vector3, b: Vector3, c: Vector3, outward: Vector3, tint: Color) -> void:
	var n := (b-a).cross(c-a)
	if n.length_squared() < 0.000000001:
		return
	n = n.normalized()
	if n.dot(outward) < 0.0:
		var swap := b
		b = c
		c = swap
		n = -n
	# Godot draws clockwise triangles on the front face.
	for vertex: Vector3 in [a,c,b]:
		batch.set_normal(n)
		batch.set_color(tint)
		batch.add_vertex(vertex)

func palette(hex: String) -> Color:
	return Color.from_string(hex,Color.WHITE)

func panel(a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3, tint: Color) -> void:
	face(a,b,c,outward,tint)
	face(a,c,d,outward,tint)

# y-up faceted oval with distinct widths at its two ends.
func band(at: Vector3, height: float, bottom: Vector2, top: Vector2, tint: Color, sides: int = 8) -> void:
	var low := at - Vector3.UP * height * 0.5
	var high := at + Vector3.UP * height * 0.5
	for j in range(sides):
		var a := TAU * (j + 0.5) / sides
		var b := TAU * (j + 1.5) / sides
		var up_a := high + Vector3(cos(a)*top.x,0,sin(a)*top.y)
		var up_b := high + Vector3(cos(b)*top.x,0,sin(b)*top.y)
		var lo_a := low + Vector3(cos(a)*bottom.x,0,sin(a)*bottom.y)
		var lo_b := low + Vector3(cos(b)*bottom.x,0,sin(b)*bottom.y)
		var outward := Vector3(cos((a+b)*0.5),0,sin((a+b)*0.5))
		panel(lo_a,lo_b,up_b,up_a,outward,tint)
		face(low,lo_a,lo_b,Vector3.DOWN,tint)
		face(high,up_b,up_a,Vector3.UP,tint)

func box(at: Vector3, size: Vector3, tint: Color) -> void:
	var e := size * 0.5
	var v: Array[Vector3] = []
	for sy in [-1,1]:
		for sz in [-1,1]:
			for sx in [-1,1]:
				v.append(at + Vector3(sx*e.x,sy*e.y,sz*e.z))
	panel(v[0],v[1],v[5],v[4],Vector3.FORWARD,tint)
	panel(v[2],v[3],v[7],v[6],Vector3.BACK,tint)
	panel(v[0],v[2],v[6],v[4],Vector3.LEFT,tint)
	panel(v[1],v[3],v[7],v[5],Vector3.RIGHT,tint)
	panel(v[0],v[1],v[3],v[2],Vector3.DOWN,tint)
	panel(v[4],v[5],v[7],v[6],Vector3.UP,tint)

func build_hiker(root: Node3D) -> Dictionary:
	var rust := palette("ad5939")
	var coat := palette("bc7146")
	var cloth := palette("43524c")
	var pants := palette("374849")
	var hide := palette("4a3630")
	var pack := palette("737657")
	var seam := palette("c59e6b")
	var strap := palette("4c4c3b")
	var skin := palette("b78364")
	var body := joint(root,"Tronco",Vector3(0,0.89,0))
	begin_part()
	band(Vector3(0,0.09,0),0.18,Vector2(0.205,0.154),Vector2(0.198,0.139),rust)
	band(Vector3(0,0.35,0),0.38,Vector2(0.201,0.14),Vector2(0.273,0.174),coat)
	band(Vector3(0,0.56,0),0.075,Vector2(0.273,0.172),Vector2(0.148,0.119),rust)
	band(Vector3(0,0.605,0),0.09,Vector2(0.15,0.124),Vector2(0.117,0.11),cloth)
	band(Vector3(0,0.731,-0.015),0.182,Vector2(0.095,0.094),Vector2(0.128,0.119),skin)
	band(Vector3(0,0.835,-0.006),0.1,Vector2(0.132,0.121),Vector2(0.131,0.119),hide)
	band(Vector3(0,0.857,-0.027),0.031,Vector2(0.173,0.179),Vector2(0.162,0.165),cloth)
	band(Vector3(0,0.908,0),0.081,Vector2(0.143,0.118),Vector2(0.104,0.085),cloth)
	box(Vector3(0,0.747,-0.121),Vector3(0.044,0.053,0.026),skin)
	for s in [-1.0,1.0]:
		box(Vector3(s*0.053,0.778,-0.115),Vector3(0.028,0.012,0.009),hide)
		box(Vector3(s*0.148,0.358,-0.132),Vector3(0.041,0.396,0.03),strap)
		box(Vector3(s*0.148,0.28,-0.153),Vector3(0.045,0.026,0.014),seam)
	band(Vector3(0,0.293,0.169),0.41,Vector2(0.188,0.1),Vector2(0.196,0.146),pack)
	band(Vector3(0,0.524,0.172),0.102,Vector2(0.207,0.153),Vector2(0.153,0.107),strap)
	box(Vector3(0,0.238,0.285),Vector3(0.235,0.154,0.056),hide)
	box(Vector3(0,0.298,0.316),Vector3(0.215,0.018,0.008),seam)
	for s in [-1.0,1.0]:
		box(Vector3(s*0.091,0.416,0.276),Vector3(0.029,0.17,0.032),seam)
	finish(body)
	var legs: Array = []
	var knees: Array = []
	var arms: Array = []
	for s in [-1.0,1.0]:
		var thigh := joint(root,"PernaE" if s < 0 else "PernaD",Vector3(s*0.112,0.91,0))
		begin_part()
		band(Vector3(0,-0.206,0),0.412,Vector2(0.089,0.1),Vector2(0.111,0.124),pants)
		finish(thigh)
		var knee := joint(thigh,"Joelho",Vector3(0,-0.402,0))
		begin_part()
		band(Vector3(0,-0.168,0),0.343,Vector2(0.068,0.075),Vector2(0.088,0.097),cloth)
		band(Vector3(0,-0.369,-0.01),0.149,Vector2(0.09,0.115),Vector2(0.078,0.092),hide)
		box(Vector3(0,-0.436,-0.041),Vector3(0.166,0.074,0.267),hide)
		box(Vector3(0,-0.473,-0.041),Vector3(0.173,0.034,0.273),strap)
		finish(knee)
		var arm := joint(body,"BracoE" if s < 0 else "BracoD",Vector3(s*0.244,0.488,0))
		begin_part()
		band(Vector3(s*0.028,-0.125,0),0.263,Vector2(0.072,0.078),Vector2(0.091,0.094),coat)
		band(Vector3(s*0.037,-0.338,-0.018),0.207,Vector2(0.057,0.062),Vector2(0.079,0.079),rust)
		band(Vector3(s*0.035,-0.45,-0.032),0.057,Vector2(0.054,0.058),Vector2(0.061,0.065),cloth)
		band(Vector3(s*0.034,-0.502,-0.042),0.085,Vector2(0.042,0.046),Vector2(0.055,0.053),skin)
		finish(arm)
		legs.append(thigh)
		knees.append(knee)
		arms.append(arm)
	return {"body":body,"legs":legs,"knees":knees,"arms":arms}

# A longitudinal body section with a narrower roof, suitable for the hood or cabin.
func car_section(z1: float,z2: float,base: float,h1: float,h2: float,lower_half: float,upper_half: float,tint: Color) -> void:
	var a := Vector3(-lower_half,base,z1)
	var b := Vector3(lower_half,base,z1)
	var c := Vector3(upper_half,h1,z1)
	var d := Vector3(-upper_half,h1,z1)
	var e := Vector3(-lower_half,base,z2)
	var f := Vector3(lower_half,base,z2)
	var g := Vector3(upper_half,h2,z2)
	var h := Vector3(-upper_half,h2,z2)
	panel(a,b,c,d,Vector3.FORWARD,tint)
	panel(e,f,g,h,Vector3.BACK,tint)
	panel(b,f,g,c,Vector3.RIGHT,tint)
	panel(a,e,h,d,Vector3.LEFT,tint)
	panel(d,c,g,h,Vector3.UP,tint)
	panel(a,b,f,e,Vector3.DOWN,tint)

func axle_disc(center: Vector3, radius: float, width: float, tint: Color) -> void:
	var start := center - Vector3.RIGHT * width*0.5
	var end := center + Vector3.RIGHT * width*0.5
	for j in range(14):
		var a := TAU*j/14.0
		var b := TAU*(j+1)/14.0
		var va := Vector3(0,cos(a),sin(a))
		var vb := Vector3(0,cos(b),sin(b))
		panel(start+va*radius,start+vb*radius,end+vb*radius,end+va*radius,(va+vb).normalized(),tint)
		face(start,start+va*radius,start+vb*radius,Vector3.LEFT,tint)
		face(end,end+va*radius,end+vb*radius,Vector3.RIGHT,tint)

func build_car(root: Node3D) -> Array:
	var olive := palette("65715b")
	var roof := palette("a4a087")
	var glass := palette("527078")
	var trim := palette("333e3d")
	var alloy := palette("bec0a9")
	var wheels: Array = []
	begin_part()
	car_section(-2.11,2.15,0.48,0.92,0.98,0.795,0.87,olive)
	car_section(-2.09,-0.84,0.89,0.90,1.055,0.855,0.83,olive)
	car_section(-0.87,1.92,0.94,1.02,1.05,0.858,0.816,olive)
	car_section(-0.46,1.81,1.549,1.615,1.60,0.707,0.687,roof)
	for s in [-1.0,1.0]:
		# Thin uprights incline with the glazing.
		for line: Vector2 in [Vector2(-0.85,-0.43),Vector2(0.35,0.35),Vector2(1.19,1.19),Vector2(1.93,1.77)]:
			panel(Vector3(s*0.835,1.03,line.x-0.038),Vector3(s*0.835,1.03,line.x+0.038),Vector3(s*0.694,1.554,line.y+0.038),Vector3(s*0.694,1.554,line.y-0.038),Vector3(s,0.15,0),roof)
		box(Vector3(s*0.864,0.812,0.04),Vector3(0.018,0.044,3.99),trim)
		for z in [0.245,1.10]:
			box(Vector3(s*0.867,0.943,z),Vector3(0.04,0.038,0.158),alloy)
		box(Vector3(s*0.905,1.059,-0.652),Vector3(0.215,0.114,0.17),olive)
		box(Vector3(s*0.589,0.796,-2.12),Vector3(0.369,0.156,0.046),palette("e4d6a6"))
		box(Vector3(s*0.702,0.799,2.16),Vector3(0.192,0.224,0.056),palette("a84b39"))
		for z in [-0.14,1.43]:
			box(Vector3(s*0.545,1.647,z),Vector3(0.055,0.107,0.068),trim)
		box(Vector3(s*0.545,1.714,0.66),Vector3(0.044,0.045,1.91),alloy)
	for z in [-2.132,2.181]:
		box(Vector3(0,0.552,z),Vector3(1.74,0.117,0.119),trim)
	box(Vector3(0,0.783,-2.122),Vector3(0.706,0.15,0.04),trim)
	for y in [0.757,0.803]:
		box(Vector3(0,y,-2.148),Vector3(0.683,0.015,0.014),alloy)
	box(Vector3(0,0.757,2.171),Vector3(0.333,0.10,0.027),palette("cbb793"))
	# Canvas roll tied to a weathered roof basket.
	box(Vector3(0.06,1.738,0.83),Vector3(0.72,0.058,1.04),strap_color())
	car_section(0.38,1.29,1.76,1.92,1.91,0.309,0.257,palette("98744e"))
	for z in [0.54,1.12]:
		box(Vector3(0,1.932,z),Vector3(0.51,0.02,0.06),trim)
	# Seat backs, headrests, dash and interior bench are visible through the glazing.
	for s in [-1.0,1.0]:
		box(Vector3(s*0.40,1.082,0.17),Vector3(0.55,0.107,0.49),trim)
		box(Vector3(s*0.40,1.221,0.37),Vector3(0.55,0.315,0.105),trim)
		box(Vector3(s*0.40,1.427,0.37),Vector3(0.25,0.13,0.099),trim)
	box(Vector3(0,1.083,1.14),Vector3(1.32,0.10,0.42),trim)
	box(Vector3(0,1.223,1.34),Vector3(1.31,0.31,0.105),trim)
	box(Vector3(0,1.103,-0.56),Vector3(1.49,0.145,0.26),trim)
	box(Vector3(-0.38,1.233,-0.32),Vector3(0.30,0.038,0.045),trim)
	box(Vector3(-0.38,1.158,-0.30),Vector3(0.22,0.037,0.046),trim)
	for s in [-1.0,1.0]:
		box(Vector3(-0.38+s*0.12,1.196,-0.31),Vector3(0.047,0.087,0.044),trim)
	finish(root)
	begin_part()
	panel(Vector3(-0.818,1.036,-0.875),Vector3(0.818,1.036,-0.875),Vector3(0.683,1.561,-0.43),Vector3(-0.683,1.561,-0.43),Vector3(0,0.65,-1),glass)
	panel(Vector3(-0.817,1.033,1.962),Vector3(0.817,1.033,1.962),Vector3(0.683,1.556,1.776),Vector3(-0.683,1.556,1.776),Vector3(0,0.3,1),glass)
	for s in [-1.0,1.0]:
		panel(Vector3(s*0.826,1.035,-0.871),Vector3(s*0.826,1.035,1.96),Vector3(s*0.686,1.552,1.773),Vector3(s*0.686,1.552,-0.43),Vector3(s,0.15,0),glass)
	var glazing := MeshInstance3D.new()
	glazing.mesh = batch.commit()
	var tint := StandardMaterial3D.new()
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.albedo_color = Color(0.40,0.55,0.57,0.27)
	tint.roughness = 0.23
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	glazing.material_override = tint
	glazing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glazing)
	for s in [-1.0,1.0]:
		for z in [-1.35,1.37]:
			var wheel := joint(root,"Roda",Vector3(s*0.81,0.374,z))
			begin_part()
			axle_disc(Vector3.ZERO,0.367,0.23,palette("303331"))
			axle_disc(Vector3(s*0.121,0,0),0.223,0.015,alloy)
			axle_disc(Vector3(s*0.133,0,0),0.135,0.016,trim)
			axle_disc(Vector3(s*0.145,0,0),0.06,0.017,alloy)
			for j in range(5):
				var a := j*TAU/5
				axle_disc(Vector3(s*0.148,cos(a)*0.102,sin(a)*0.102),0.012,0.015,alloy)
			finish(wheel)
			wheels.append(wheel)
	return wheels

func strap_color() -> Color:
	return palette("505348")

func build_seat_cover(root: Node3D) -> Node3D:
	var covers := joint(root,"CapasArtesanais",Vector3.ZERO)
	begin_part()
	for s in [-1.0,1.0]:
		var cx: float = s*0.40
		box(Vector3(cx,1.232,0.368),Vector3(0.561,0.324,0.121),palette("b17e50"))
		box(Vector3(cx,1.432,0.37),Vector3(0.266,0.139,0.112),palette("b17e50"))
		box(Vector3(cx,1.143,0.164),Vector3(0.548,0.022,0.48),palette("b17e50"))
		for dx in [-0.17,0.11]:
			for dz in [-0.063,0.063]:
				box(Vector3(cx+dx,1.232,0.368+dz),Vector3(0.042,0.307,0.008),palette("456960"))
			box(Vector3(cx+dx,1.157,0.164),Vector3(0.042,0.009,0.48),palette("456960"))
	finish(covers)
	return covers
