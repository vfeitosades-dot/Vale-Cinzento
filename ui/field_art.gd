extends Control

# Original two-dimensional artwork for the title and the survey map.
var sheet := "valley"
var survey: Dictionary = {}
const INK := Color("#242e2c")
const PAPER := Color("#e3dfc8")
const ORANGE := Color("#c66e42")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	if sheet == "valley":
		draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(1152, 648))
		_valley()
	else:
		_chart()

func _ridge(heights: Array, tint: Color) -> void:
	var points := PackedVector2Array([Vector2(-3, 652)])
	for i in heights.size():
		points.append(Vector2(1152.0 * i / (heights.size() - 1), float(heights[i])))
	points.append(Vector2(1155, 652))
	draw_colored_polygon(points, tint)

func _pine(x: float, y: float, h: float, color: Color) -> void:
	draw_line(Vector2(x, y - h * 0.8), Vector2(x, y + 1), color, maxf(1.0, h * 0.055))
	for tier in 3:
		var apex := Vector2(x, y - h + h * 0.19 * tier)
		var half_width := h * (0.14 + 0.035 * tier)
		var level := h * (0.43 + 0.03 * tier)
		draw_colored_polygon(PackedVector2Array([apex, apex + Vector2(half_width, level), apex + Vector2(-half_width, level * 0.96)]), color)

func _valley() -> void:
	draw_rect(Rect2(0,0,1152,648), Color("#d0be94"))
	draw_circle(Vector2(846,154), 65, Color("#e8c382"))
	for i in 38:
		var y := 36 + (i * 41) % 233
		var x := (i * 167) % 1147
		draw_line(Vector2(x,y), Vector2(x + 9 + (i * 13) % 93, y), Color("#e0cda6"), 1)
	_ridge([245,235,258,234,209,226,189,180,201,210,172,182,141,153,117,152,161,193,177,181,168,188,154,181,162], Color("#aaac94"))
	_ridge([302,288,288,281,269,277,245,256,233,215,225,241,231,235,211,206,215,203,183,193,217,208,226,217,227,205,209], Color("#8e9b86"))
	_ridge([349,343,319,323,300,304,275,281,296,297,306,278,266,256,274,247,252,233,247,216,236,230,249,258,254], Color("#687e73"))
	for i in 74:
		var x := 385.0 + i * 11
		var y := 347.0 + sin(x * 0.008) * 21 - (x - 385) * 0.078
		_pine(x, y, 9 + (i * 41) % 25, Color("#718479"))
	_ridge([386,361,372,348,350,336,353,359,374,353,338,347,335,349,355,340,347,334,341], Color("#708678"))
	_ridge([424,401,385,388,399,411,424,431,428,417,413,421,398,392,395,386,364,355], Color("#536c60"))
	var water := PackedVector2Array([Vector2(648,403),Vector2(738,407),Vector2(901,410),Vector2(925,422),Vector2(826,445),Vector2(762,453),Vector2(861,476),Vector2(1092,510),Vector2(1152,523),Vector2(1152,570),Vector2(816,501),Vector2(708,460),Vector2(727,447),Vector2(836,422),Vector2(858,416)])
	draw_colored_polygon(water, Color("#a3ad96"))
	for i in 16:
		var x := 750 + (i * 17) % 62
		var y := 412 + (i * 9) % 6
		draw_line(Vector2(x,y),Vector2(x+12,y), Color("#bcbea5"),1)
	for i in 55:
		var x := 470.0 + i * 13 + sin(i * 9) * 3
		var y := 453.0 + sin(x * 0.009) * 11
		if (x > 903 and x < 1004) or x < 622:
			_pine(x, y, 14 + (i * 13) % 32, Color("#3d594f"))
	# A field cabin and a triangulated fire lookout on the ridge.
	draw_colored_polygon(PackedVector2Array([Vector2(965,394),Vector2(997,389),Vector2(1010,404),Vector2(974,409)]), Color("#824f3e"))
	draw_colored_polygon(PackedVector2Array([Vector2(974,409),Vector2(1010,404),Vector2(1010,421),Vector2(974,426)]), Color("#b6a27b"))
	draw_colored_polygon(PackedVector2Array([Vector2(962,408),Vector2(965,394),Vector2(974,409),Vector2(974,426),Vector2(962,421)]), Color("#8b795e"))
	draw_rect(Rect2(981,410,8,8), Color("#47544c"))
	draw_rect(Rect2(994,408,6,14), Color("#586354"))
	var tower := Color("#4e5b51")
	draw_line(Vector2(1030,389),Vector2(1039,313),tower,3,true)
	draw_line(Vector2(1062,389),Vector2(1052,313),tower,3,true)
	for k in 4:
		var y := 321.0 + k * 16
		var left := 1038.0 - k * 1.7
		var right := 1053.0 + k * 1.7
		draw_line(Vector2(left,y),Vector2(right+2,y+16),tower,1.5,true)
		draw_line(Vector2(right,y),Vector2(left-2,y+16),tower,1.5,true)
	draw_rect(Rect2(1034,308,23,10),tower)
	draw_colored_polygon(PackedVector2Array([Vector2(1029,308),Vector2(1046,298),Vector2(1062,308)]),tower)
	for i in 5:
		var p := Vector2(749.0 + i*15, 117.0 + sin(i*4.1)*7)
		draw_polyline(PackedVector2Array([p-Vector2(5,2),p,p+Vector2(4,-3)]), Color("#717b6b"),1.3,true)
	_ridge([555,542,532,540,534,518,522,519,537,547,556,562,579,581,592,582,567,552,551], Color("#344c43"))
	for i in 27:
		var x := 400.0 + i*31.0
		var y := 555.0 + sin(x * 0.017) * 16.0 + (x-400.0)*0.045
		if x < 545 or x > 952:
			_pine(x, y, 20 + (i*29)%80, Color("#344c43"))
	_ridge([599,587,578,574,585,593,602,608,619,616,609,603,602,592,581,563], Color("#293c36"))

func _chart() -> void:
	draw_rect(Rect2(Vector2.ZERO,size), PAPER)
	var pad := Vector2(39,19)
	var room := size - pad * 2
	if room.x <= 0 or room.y <= 0:
		return
	var factor := minf(room.x/167.0,room.y/158.0)
	var center := size * 0.5
	for i in 26:
		var x := i * size.x / 25.0
		draw_line(Vector2(x,0),Vector2(x,size.y),Color("#d3d2b9"),1)
	for i in 18:
		var y := i * size.y / 17.0
		draw_line(Vector2(0,y),Vector2(size.x,y),Color("#d3d2b9"),1)
	for k in 7:
		var contour := PackedVector2Array()
		for j in 63:
			var theta := TAU*j/62.0
			var r := 11.0 + k * 4.2 + sin(theta*3)*3.1 + cos(theta*5)*1.3
			contour.append(center + (Vector2(37,-51)+Vector2(cos(theta)*r*1.6,sin(theta)*r))*factor)
		draw_polyline(contour,Color("#b8bea2"),1,true)
	var river := PackedVector2Array()
	for i in 65:
		var wx := -200.0 + i*6.25
		var wz := -16.0 + 5.0*sin(wx*0.035)
		river.append(center+Vector2(wx,wz)*factor)
	draw_polyline(river,Color("#93b1aa"),maxf(4.0,5*factor),true)
	draw_polyline(river,Color("#b4c7bc"),1.5,true)
	var path := PackedVector2Array()
	for p in [Vector2(2,73),Vector2(4,33),Vector2(3,10),Vector2(-4,-8),Vector2(-4,-26),Vector2(-11,-36),Vector2(16,-63)]:
		path.append(center+p*factor)
	draw_polyline(path,Color("#b89e73"),4,true)
	draw_polyline(path,Color("#ebe2c4"),1.4,true)
	draw_line(center+Vector2(-11,-36)*factor,center+Vector2(-36,-52)*factor,Color("#b89e73"),2,true)
	draw_line(center+Vector2(4,42)*factor,center+Vector2(-29,42)*factor,Color("#b89e73"),2,true)
	draw_line(center+Vector2(3,15)*factor,center+Vector2(14,15)*factor,Color("#b89e73"),2,true)
	var font := ThemeDB.fallback_font
	for m in survey.get("markers",[]):
		var p := center + Vector2(float(m.get("x",0)),float(m.get("z",0)))*factor
		var ink := INK if bool(m.get("visited",false)) else Color("#6b715e")
		draw_circle(p,5,ink)
		draw_circle(p,2.2,PAPER)
		var name_text := str(m.get("name",""))
		var tw := font.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		var left_side := float(m.get("x",0)) < -18
		var tx := p.x-tw-9 if left_side else p.x+10
		var yshift := -5 if name_text.to_lower().contains("abrigo") else 5
		var label_at := Vector2(clampf(tx,4,size.x-tw-4),p.y+yshift)
		draw_string_outline(font,label_at,name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,4,PAPER)
		draw_string(font,label_at,name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
	var pos := center + Vector2(float(survey.get("player_x",0)),float(survey.get("player_z",0)))*factor
	var angle := deg_to_rad(float(survey.get("heading",0)))
	var point := PackedVector2Array()
	for v in [Vector2(0,-10),Vector2(6,6),Vector2(0,3),Vector2(-6,6)]:
		point.append(pos+v.rotated(angle))
	draw_circle(pos,11.5,Color("#fff3d8"))
	draw_colored_polygon(point,ORANGE)
	draw_string(font,Vector2(size.x-31,22),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,15,INK)
	draw_line(Vector2(size.x-25,29),Vector2(size.x-25,51),INK,1.6)
	draw_line(Vector2(size.x-25,29),Vector2(size.x-29,36),INK,1.6)
	draw_line(Vector2(size.x-25,29),Vector2(size.x-21,36),INK,1.6)
	draw_line(Vector2(15,size.y-11),Vector2(15+20*factor,size.y-11),INK,2)
	draw_string(font,Vector2(15,size.y-17),"20 m",HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)
