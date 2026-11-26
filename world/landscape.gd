extends Node3D

const Art = preload("res://world/actor_art.gd")
const Landmarks = preload("res://world/landmarks.gd")
const POIS = {
	"abrigo":{"name":"Abrigo do Vale","x":-8.0,"z":39.0},
	"mercado":{"name":"Armazém da Serra","x":14.0,"z":15.0},
	"oficina":{"name":"Oficina Estação","x":-29.0,"z":42.0},
	"ponte":{"name":"Ponte de Madeira","x":-4.0,"z":-16.0},
	"mirante":{"name":"Mirante da Serra","x":16.0,"z":-63.0},
	"reservatorio":{"name":"Reservatório","x":-36.0,"z":-52.0}
}
const SPINE = [Vector2(2,90),Vector2(4,60),Vector2(4,33),Vector2(3,10),Vector2(-4,-8),Vector2(-4,-24),Vector2(-11,-36),Vector2(-2,-45),Vector2(10,-55),Vector2(16,-63)]
const PATHS = [
	[Vector2(4,43),Vector2(-7,42),Vector2(-18,45),Vector2(-29,42)],
	[Vector2(3,15),Vector2(9,17),Vector2(14,15)],
	[Vector2(-11,-36),Vector2(-21,-44),Vector2(-29,-47),Vector2(-36,-52)]
]
const PADS = [[-8.0,35.7,5.5,5.6],[14.0,11.25,6.0,4.8],[-29.0,38.1,6.3,5.6],[16.0,-67.6,4.0,3.3],[-37.0,-57.1,3.5,3.5]]
var world_seed := 3215
var art := Art.new()
var walls: Array[Rect2] = []
var tree_cells: Dictionary = {}
var observer := Vector2(-7,41)
var environment := Environment.new()
var sunlight := DirectionalLight3D.new()
var sky_material := ShaderMaterial.new()
var rain_node := MultiMeshInstance3D.new()
var river_material := ShaderMaterial.new()
var current_hour := -100.0
var current_weather := ""
var camp_node: Node3D
var camp_cache: Array = []
var random := RandomNumberGenerator.new()

func set_world_seed(value: int) -> void:
	world_seed = value

func _ready() -> void:
	random.seed = world_seed
	_build_environment()
	art.begin_part()
	_ground_mesh()
	_roads()
	Landmarks.new(self,art).build()
	_village_details()
	art.finish(self)
	_water()
	_forest()
	_ridges()
	_rain()
	set_environment(8.2,"Limpo")

func _river_z(x: float) -> float:
	return -16.0 + 1.68*sin((x+4.0)*0.057) + 0.62*sin((x+4.0)*0.108)

func _base_height(x: float,z: float) -> float:
	return 1.92 + 0.66*sin(x*0.041)*cos(z*0.038) + 0.34*sin(z*0.079+x*0.036) + 9.9*smoothstep(28.0,78.0,-z) + 0.035*maxf(0,absf(x)-48.0)

func _terrain_height(x: float,z: float) -> float:
	var rd := absf(z-_river_z(x))
	var y := lerpf(-1.07,_base_height(x,z),smoothstep(3.42,7.2,rd))
	for entry: Array in PADS:
		var dx := absf(x-float(entry[0]))-float(entry[2])
		var dz := absf(z-float(entry[1]))-float(entry[3])
		var weight := 1.0-smoothstep(0.0,3.0,maxf(dx,dz))
		if weight>0:
			y = lerpf(y,_base_height(entry[0],entry[1]),weight)
	return y

func _bridge_height(z: float) -> float:
	var t := clampf((z+23.7)/15.4,0,1)
	return lerpf(_terrain_height(-4.0,-23.7),_terrain_height(-4.0,-8.3),t) + 0.34*sin(t*PI)

func ground_height(x: float,z: float) -> float:
	if absf(x+4.0)<=2.77 and z>=-23.72 and z<=-8.28:
		return _bridge_height(z)+0.02
	return _terrain_height(x,z)

func wall_rect(rect: Rect2) -> void:
	walls.append(rect)

func _tree_obstacle(point: Vector2,radius: float) -> void:
	var cell := Vector2i(floori(point.x/8),floori(point.y/8))
	if not tree_cells.has(cell):
		tree_cells[cell] = []
	tree_cells[cell].append(Vector3(point.x,radius,point.y))

func blocked(pos: Vector2,radius: float) -> bool:
	var water_distance := absf(pos.y-_river_z(pos.x))
	if water_distance<4.4+radius and absf(pos.x+4.0)>2.48-radius:
		return true
	if pos.y < -8.3 and pos.y > -23.7 and absf(absf(pos.x+4.0)-2.61)<0.12+radius:
		return true
	for w in walls:
		if w.grow(radius).has_point(pos):
			return true
	var cx := floori(pos.x/8)
	var cz := floori(pos.y/8)
	for xx in range(cx-1,cx+2):
		for zz in range(cz-1,cz+2):
			for trunk: Vector3 in tree_cells.get(Vector2i(xx,zz),[]):
				if pos.distance_squared_to(Vector2(trunk.x,trunk.z))<pow(radius+trunk.y,2):
					return true
	return false

func _ground_mesh() -> void:
	var bottom := Color("8b8b67")
	var top := Color("b0a779")
	var bank := Color("9c9076")
	var meadow := Color("798869")
	for iz in range(-38,39):
		for ix in range(-40,41):
			var x := ix*3.2
			var z := iz*3.2
			var a := Vector3(x,_terrain_height(x,z),z)
			var b := Vector3(x+3.2,_terrain_height(x+3.2,z),z)
			var c := Vector3(x+3.2,_terrain_height(x+3.2,z+3.2),z+3.2)
			var d := Vector3(x,_terrain_height(x,z+3.2),z+3.2)
			var w := 0.5+0.25*sin(x*0.102+z*0.086)+0.25*cos(z*0.172-x*0.094)
			var tint := bottom.lerp(top,w*0.75).lerp(meadow,0.30+0.24*sin(z*0.076-x*0.041))
			tint = tint.lerp(bank,1.0-smoothstep(4.1,7.6,absf(z+1.6-_river_z(x))))
			art.face(a,b,c,Vector3.UP,tint)
			art.face(a,c,d,Vector3.UP,tint.darkened(0.009))

func road_distance(p: Vector2,line: Array) -> float:
	var near := INF
	for i in range(line.size()-1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i+1]
		var ab := b-a
		var t := clampf((p-a).dot(ab)/ab.length_squared(),0,1)
		near = minf(near,p.distance_to(a+ab*t))
	return near

func _road_vertex(p: Vector2,lift: float) -> Vector3:
	return Vector3(p.x,_terrain_height(p.x,p.y)+lift,p.y)

func _ribbon(line: Array,width: float,color: Color,lift: float) -> void:
	for i in range(line.size()-1):
		var a: Vector2 = line[i]
		var b: Vector2 = line[i+1]
		var steps := ceili(a.distance_to(b)/0.89)
		var side := (b-a).normalized().orthogonal()*width*0.5
		for j in range(steps):
			var p := a.lerp(b,j/float(steps))
			var q := a.lerp(b,(j+1)/float(steps))
			if absf((p.x+q.x)*0.5+4)<3.12 and (p.y+q.y)*0.5 < -8.2 and (p.y+q.y)*0.5 > -23.8:
				continue
			art.panel(_road_vertex(p+side,lift),_road_vertex(q+side,lift),_road_vertex(q-side,lift),_road_vertex(p-side,lift),Vector3.UP,color)
		if i>0 and absf(a.y-_river_z(a.x))>7.65:
			art.band(_road_vertex(a,lift-0.012),0.026,Vector2(width,width)*0.5,Vector2(width,width)*0.5,color,12)

func _roads() -> void:
	var gravel := Color("af9d7e")
	_ribbon(SPINE,5.2,gravel,0.089)
	_ribbon(SPINE,4.15,Color("998b71"),0.11)
	for line: Array in PATHS:
		_ribbon(line,3.15,gravel,0.087)
		_ribbon(line,2.19,Color("a79778"),0.12)

func rod(a: Vector3,b: Vector3,radius: float,tint: Color) -> void:
	var axis := (b-a).normalized()
	var reference := Vector3.UP if absf(axis.y)<0.9 else Vector3.RIGHT
	var u := axis.cross(reference).normalized()*radius
	var v := axis.cross(u).normalized()*radius
	var ring := [u+v,u-v,-u-v,-u+v]
	for j in range(4):
		var p: Vector3 = ring[j]
		var q: Vector3 = ring[(j+1)%4]
		art.panel(a+p,b+p,b+q,a+q,(p+q).normalized(),tint)
		art.face(a,a+q,a+p,-axis,tint)
		art.face(b,b+p,b+q,axis,tint)

func plate(txt: String,location: Vector3,scale_factor: float) -> void:
	var label := Label3D.new()
	label.text = txt
	label.font_size = 32
	label.pixel_size = scale_factor
	label.modulate = Color("eee2bb")
	label.outline_size = 4
	label.outline_modulate = Color("4b473a")
	label.double_sided = true
	label.visibility_range_end = 42
	add_child(label)
	label.position = location

func signboard(txt: String,p: Vector2) -> void:
	var y := ground_height(p.x,p.y)
	art.box(Vector3(p.x,y+0.83,p.y),Vector3(0.14,1.65,0.14),Color("665943"))
	art.box(Vector3(p.x,y+1.51,p.y),Vector3(2.54,0.51,0.153),Color("565f4e"))
	plate(txt,Vector3(p.x,y+1.51,p.y+0.084),0.0068)

func _village_details() -> void:
	var wood := Color("81735a")
	for zz in [58.0,43.0,28.0,13.0,-2.0]:
		var px := 7.9 if zz>15 else 5.8
		var yy := ground_height(px,zz)
		art.band(Vector3(px,yy+3.52,zz),7.04,Vector2(0.152,0.152),Vector2(0.109,0.109),wood,7)
		art.box(Vector3(px,yy+6.54,zz),Vector3(2.06,0.15,0.15),wood)
		for k in [-0.77,0.77]:
			art.band(Vector3(px+k,yy+6.73,zz),0.32,Vector2(0.086,0.086),Vector2(0.08,0.08),Color("8d9a96"),7)
			if zz>-2:
				var nx := 7.9 if zz-15>15 else 5.8
				var u := Vector3(px+k,yy+6.83,zz)
				var v := Vector3(nx+k,ground_height(nx,zz-15)+6.83,zz-15)
				for j in range(5):
					var a := j/5.0
					var b := (j+1)/5.0
					rod(u.lerp(v,a)-Vector3.UP*sin(a*PI)*0.49,u.lerp(v,b)-Vector3.UP*sin(b*PI)*0.49,0.014,Color("514e46"))
	for x in [-14.2,-2.2]:
		for j in range(7):
			var z := 30.2+j*1.63
			var y := ground_height(x,z)
			art.box(Vector3(x,y+0.53,z),Vector3(0.13,1.06,0.14),wood)
			if j<6:
				var ny := ground_height(x,z+1.63)
				for h in [0.40,0.77]:
					rod(Vector3(x,y+h,z),Vector3(x,ny+h,z+1.63),0.048,wood)
		wall_rect(Rect2(x-0.07,30.2,0.14,9.8))
	signboard("PONTE DO VALE",Vector2(-7.65,-7.0))
	signboard("TRILHA DA SERRA",Vector2(-13.65,-37.4))

func _water() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
varying vec2 coord;
void vertex() {
	coord = VERTEX.xz;
	VERTEX.y += 0.024*sin(VERTEX.x*1.4+TIME*1.55+sin(VERTEX.z*1.13))+0.013*cos(VERTEX.z*2.5-TIME*1.9);
}
void fragment() {
	float rip = sin(coord.y*6.3+sin(coord.x*0.91+TIME*1.1)*1.12+TIME*1.65);
	float wave = smoothstep(0.85,1.0,rip)*smoothstep(0.0,0.97,sin(coord.x*1.07-TIME*0.75));
	ALBEDO = mix(vec3(0.062,0.215,0.211),vec3(0.46,0.63,0.57),wave*0.56+0.10);
	ROUGHNESS = 0.36;
	SPECULAR = 0.72;
}
"""
	river_material.shader = shader
	st.set_material(river_material)
	for i in range(-89,90):
		var x := i*1.5
		var nx := x+1.5
		var a := Vector3(x,-0.22,_river_z(x)-4.28)
		var b := Vector3(nx,-0.22,_river_z(nx)-4.28)
		var c := Vector3(nx,-0.22,_river_z(nx)+4.28)
		var d := Vector3(x,-0.22,_river_z(x)+4.28)
		for vertex: Vector3 in [a,b,c,a,c,d]:
			st.set_normal(Vector3.UP)
			st.add_vertex(vertex)
	var water := MeshInstance3D.new()
	water.mesh = st.commit()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)

func _crown(at: Vector3,radii: Vector3,c: Color,n: int = 7) -> void:
	var top := at+Vector3(0.10,radii.y,0.04)
	var bot := at-Vector3(0,radii.y*0.7,0.09)
	for j in range(n):
		var a := TAU*j/n
		var b := TAU*(j+1)/n
		var m := Vector3(cos(a)*radii.x,-radii.y*0.12+0.21*sin(3*a),sin(a)*radii.z)
		var p := at+m
		var q := at+Vector3(cos(b)*radii.x,-radii.y*0.12+0.21*sin(3*b),sin(b)*radii.z)
		var tint := c.lightened(0.034*(j%3))
		art.face(p,q,top,m+Vector3.UP,tint)
		art.face(p,q,bot,m+Vector3.DOWN,tint.darkened(0.11))

func _tree_mesh(kind: int) -> Mesh:
	art.begin_part()
	var bark := Color("665640")
	if kind<3:
		var color: Color = [Color("929569"),Color("a17b4e"),Color("ad8f56")][kind]
		rod(Vector3.ZERO,Vector3(0.13,4.6,0.08),0.16,bark)
		for j in range(5):
			var a := j*2.4+kind
			var edge := Vector3(cos(a)*1.13,3.8+0.27*j,sin(a)*1.1)
			rod(Vector3(0,2.14+j*0.18,0),edge,0.067,bark)
			_crown(edge,Vector3(1.44,1.52,1.27),color.lightened((j%2)*0.034))
		_crown(Vector3(0,5.4,0),Vector3(1.6,1.43,1.55),color)
	else:
		rod(Vector3.ZERO,Vector3(0,7.25,0),0.15,bark)
		for j in range(4):
			var r := 1.69-0.26*j
			art.band(Vector3(0,2.55+j*1.12,0),2.41-j*0.19,Vector2(r,r),Vector2(0.07,0.07),Color("556d57").lightened(j*0.045),9)
	return art.batch.commit()

func _scatter(mesh: Mesh, transforms: Array, use_shadow: bool, limit: float = 0.0) -> void:
	if transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i,transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.visibility_range_end = limit
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if use_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

func _in_clearing(p: Vector2,room: float) -> bool:
	if road_distance(p,SPINE)<3.1+room:
		return true
	for line: Array in PATHS:
		if road_distance(p,line)<1.9+room:
			return true
	for zone: Array in PADS:
		if absf(p.x-zone[0])<zone[2]+room+1 and absf(p.y-zone[1])<zone[3]+room+1:
			return true
	return absf(p.y-_river_z(p.x))<5.3+room or p.distance_to(Vector2(4,33))<4.0

func _forest() -> void:
	var groups: Array = [[],[],[],[]]
	for i in range(1000):
		var p := Vector2(random.randf_range(-115,115),random.randf_range(-108,102))
		if _in_clearing(p,1.5):
			continue
		if absf(p.x)<36 and p.y > -5 and p.y < 53 and random.randf()<0.72:
			continue
		var scale_factor := random.randf_range(0.76,1.44)
		var basis := Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3.ONE*scale_factor)
		var kind := random.randi_range(0,3)
		groups[kind].append(Transform3D(basis,Vector3(p.x,_terrain_height(p.x,p.y)-0.08,p.y)))
		_tree_obstacle(p,0.19*scale_factor)
	for k in range(4):
		_scatter(_tree_mesh(k),groups[k],true)
	var grass: Array = []
	var stones: Array = []
	for j in range(1550):
		var p := Vector2(random.randf_range(-92,92),random.randf_range(-90,82))
		if _in_clearing(p,0):
			continue
		var basis := Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3.ONE*random.randf_range(0.6,1.32))
		var at := Vector3(p.x,_terrain_height(p.x,p.y),p.y)
		if j%7==0:
			stones.append(Transform3D(basis,at))
		else:
			grass.append(Transform3D(basis,at))
	art.begin_part()
	for j in range(7):
		var a := j*2.4
		var stem := Vector3(cos(a)*0.21,0,sin(a)*0.21)
		var w := Vector3(cos(a+1.5),0,sin(a+1.5))*0.055
		var tip := stem+Vector3(cos(a)*0.12,0.34+0.07*(j%3),sin(a)*0.12)
		art.face(stem-w,stem+w,tip,Vector3(sin(a),0,cos(a)),Color("99935d"))
		art.face(stem+w,stem-w,tip,Vector3(-sin(a),0,-cos(a)),Color("a49d6a"))
	_scatter(art.batch.commit(),grass,false)
	art.begin_part()
	_crown(Vector3(0,0.19,0),Vector3(0.60,0.43,0.37),Color("908e80"),7)
	_scatter(art.batch.commit(),stones,true)

func _ridges() -> void:
	art.begin_part()
	for layer in range(3):
		var radius := 126.0+layer*69.0
		var tint: Color = [Color("788b79"),Color("84978f"),Color("98a8a4")][layer]
		for i in range(81):
			var a := TAU*i/80.0
			var b := TAU*(i+1)/80.0
			var va := Vector3(sin(a),0,cos(a))
			var vb := Vector3(sin(b),0,cos(b))
			var height_a := _summit(a,layer)
			var height_b := _summit(b,layer)
			var hi_a := va*(radius+24)+Vector3.UP*height_a
			var hi_b := vb*(radius+24)+Vector3.UP*height_b
			var lo_a := va*(radius-12)+Vector3.DOWN*4
			var lo_b := vb*(radius-12)+Vector3.DOWN*4
			art.face(lo_a,hi_a,hi_b,-va,tint)
			art.face(lo_a,hi_b,lo_b,-va,tint.darkened(0.026))
	var instance := MeshInstance3D.new()
	instance.mesh = art.batch.commit()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

func _summit(a: float,layer: int) -> float:
	return 22 + layer*15 + 5.6*sin(a*3+layer)+4.8*sin(a*6-layer*0.4)+2.7*cos(a*13+layer)+2.2*sin(a*21)

func _build_environment() -> void:
	var sky_shader := Shader.new()
	sky_shader.code = """
shader_type sky;
uniform vec4 zenith : source_color = vec4(0.32,0.49,0.52,1.0);
uniform vec4 horizon : source_color = vec4(0.83,0.83,0.69,1.0);
uniform vec4 cloud_tint : source_color = vec4(0.88,0.86,0.75,1.0);
uniform vec3 sun_dir = vec3(-0.4,0.62,0.4);
uniform float cloudiness = 0.45;
uniform float advance = 0.0;
uniform float daylight = 1.0;
float rand2(vec2 p){ return fract(sin(dot(p,vec2(27.41,97.63)))*4382.45); }
float field(vec2 p){
	vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(rand2(i),rand2(i+vec2(1,0)),f.x),mix(rand2(i+vec2(0,1)),rand2(i+vec2(1)),f.x),f.y);
}
void sky(){
	vec3 d=EYEDIR;
	vec3 col=mix(horizon.rgb,zenith.rgb,pow(max(0.0,d.y),0.47));
	vec2 p=d.xz / (0.24 + max(d.y,0.0))*2.8 + vec2(advance,advance*0.26);
	float mask=field(p)*0.54+field(p*2.08)*0.28+field(p*4.6)*0.18;
	float cloud=smoothstep(0.81-cloudiness*0.51,0.94-cloudiness*0.42,mask)*smoothstep(-0.015,0.13,d.y);
	col=mix(col,cloud_tint.rgb,cloud*0.86);
	float disk = max(0.0,dot(d,normalize(sun_dir)));
	col += vec3(1.0,0.73,0.45)*daylight*(pow(disk,65.0)*0.16+smoothstep(0.99904,0.99968,disk)*0.95)*(1.0-cloud);
	float star=step(0.9974,rand2(floor(d.xz/(d.y+1.03)*811.0)))*smoothstep(0.03,0.26,d.y);
	col+=vec3(star*(1.0-daylight)*0.39*(1.0-cloud));
	COLOR=col;
}
"""
	sky_material.shader = sky_shader
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d2cbb1")
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_enabled = true
	environment.fog_density = 0.0031
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	add_child(env_node)
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sunlight.directional_shadow_max_distance = 47
	add_child(sunlight)

func _rain() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.041,0.55)
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded,cull_disabled,shadows_disabled;
void vertex(){
	vec3 offset = INSTANCE_CUSTOM.xyz;
	VERTEX.x += offset.x - mod(TIME*0.85+offset.y,2.0)*0.48;
	VERTEX.z += offset.z;
	VERTEX.y += mod(offset.y-TIME*10.3,12.0)-2.0;
}
void fragment(){ ALBEDO=vec3(0.70,0.78,0.75); ALPHA=0.36; }
"""
	mat.shader = shader
	mesh.material = mat
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	multi.mesh = mesh
	multi.instance_count = 144
	for j in range(144):
		multi.set_instance_transform(j,Transform3D.IDENTITY)
		# Mobile compatibility packs custom data on some devices, so use only 0–1 here.
		multi.set_instance_custom_data(j,Color(random.randf(),random.randf(),random.randf(),1))
	shader.code = shader.code.replace("INSTANCE_CUSTOM.xyz;", "(INSTANCE_CUSTOM.xyz * vec3(16.0,12.0,16.0) - vec3(8.0,0.0,8.0));")
	rain_node.multimesh = multi
	rain_node.custom_aabb = AABB(Vector3(-10,-3,-10),Vector3(20,16,20))
	rain_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain_node)
	rain_node.visible = false

func set_observer(value: Vector2) -> void:
	observer = value
	rain_node.position = Vector3(value.x,ground_height(value.x,value.y),value.y)

func set_environment(hour: float,weather: String) -> void:
	if not is_node_ready() and sunlight.get_parent()==null:
		return
	if absf(hour-current_hour)<0.025 and current_weather==weather:
		return
	current_hour = hour
	current_weather = weather
	var what := weather.to_lower()
	var rainy := "chuva" in what or "garoa" in what
	var cloudy := rainy or "nubl" in what or "encobert" in what
	var foggy := "névo" in what or "nebl" in what or "bruma" in what
	var phi := (hour-6.0)*TAU/24.0
	var altitude := sin(phi)
	var day := smoothstep(-0.25,0.27,altitude)
	var dusk := (1.0-smoothstep(0.01,0.47,absf(altitude)))*day
	var sun_dir := Vector3(cos(phi)*0.87,altitude,-0.43).normalized()
	var zcol := Color("182c43").lerp(Color("6e9caa"),day)
	var hcol := Color("546476").lerp(Color("e2d9b8"),day).lerp(Color("deb48d"),dusk*0.64)
	if cloudy or foggy:
		zcol = zcol.lerp(Color("849294"),day*0.59)
		hcol = hcol.lerp(Color("c2c3b1"),day*0.58)
	sky_material.set_shader_parameter("zenith",zcol)
	sky_material.set_shader_parameter("horizon",hcol)
	sky_material.set_shader_parameter("cloud_tint",hcol.lightened(0.1))
	sky_material.set_shader_parameter("cloudiness",0.92 if cloudy else 0.47)
	sky_material.set_shader_parameter("advance",hour*0.066)
	sky_material.set_shader_parameter("daylight",day)
	sky_material.set_shader_parameter("sun_dir",sun_dir)
	var source := sun_dir if altitude>0.02 else Vector3(-0.42,0.64,0.33).normalized()
	sunlight.look_at(sunlight.global_position-source,Vector3.UP)
	sunlight.light_color = Color("a5bed7").lerp(Color("ffe1ac").lerp(Color("ffbb80"),dusk*0.64),day)
	sunlight.light_energy = lerpf(0.31,1.04 if cloudy else 1.32,day)
	environment.ambient_light_color = Color("91a6bc").lerp(Color("dad3b7"),day)
	environment.ambient_light_energy = lerpf(0.58,1.02,day)
	environment.fog_light_color = hcol
	environment.fog_density = 0.017 if foggy else (0.0061 if rainy else 0.0029)
	rain_node.visible = rainy
