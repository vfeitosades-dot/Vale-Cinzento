extends Control

signal move_vector(value: Vector2)
signal turn_camera(delta: Vector2)
signal running(value: bool)

var active := false
var joystick := -1
var camera_finger := -1
var center := Vector2.ZERO
var thumb := Vector2.ZERO
var blocked_controls: Array[Control] = []

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process_input(true)

func reset() -> void:
	joystick = -1
	camera_finger = -1
	thumb = Vector2.ZERO
	move_vector.emit(Vector2.ZERO)
	running.emit(false)
	queue_redraw()

func _gui_target(point: Vector2) -> bool:
	for widget in blocked_controls:
		if is_instance_valid(widget) and widget.is_visible_in_tree() and widget.get_global_rect().has_point(point):
			return true
	return false

func _input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var e := make_input_local(event) as InputEventScreenTouch
		if e.pressed:
			if _gui_target(e.position):
				return
			if e.position.x < size.x*0.49 and joystick == -1:
				joystick = e.index
				center = e.position
				thumb = Vector2.ZERO
			elif e.position.x >= size.x*0.49 and camera_finger == -1:
				camera_finger = e.index
			else:
				return
		elif e.index == joystick:
			joystick = -1
			thumb = Vector2.ZERO
			move_vector.emit(Vector2.ZERO)
			running.emit(false)
		elif e.index == camera_finger:
			camera_finger = -1
		else:
			return
	elif event is InputEventScreenDrag:
		var e := make_input_local(event) as InputEventScreenDrag
		if e.index == joystick:
			var travel := (e.position-center)/45.0
			thumb = travel.limit_length(1.0)
			move_vector.emit(thumb)
			running.emit(travel.length() > 1.32)
		elif e.index == camera_finger:
			turn_camera.emit(e.relative)
		else:
			return
	else:
		return
	queue_redraw()
	get_viewport().set_input_as_handled()

func _draw() -> void:
	if not active or not (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()):
		return
	var c := center if joystick >= 0 else Vector2(94,size.y-96)
	draw_circle(c,52,Color(0.08,0.11,0.10,0.32))
	draw_arc(c,51,0,TAU,60,Color(0.90,0.92,0.81,0.56),1.4,true)
	draw_circle(c+thumb*34,18,Color(0.86,0.87,0.73,0.46))
