extends Node3D

const Art = preload("res://world/actor_art.gd")
const START := Vector2(-7, 41)
const PARKING := Vector2(4, 33)
const WALK_RADIUS := 0.29
const NEAR_RANGE := 3.65
const CAR_RANGE := 3.15

# Supplied by the game before this node enters the scene tree.
var terrain
var active := false
var driving := false
var walk_point := START
var car_point := PARKING
var facing := 0.0
var car_yaw := -0.18
var orbit := 0.19
var elevation := 0.28
var car_speed := 0.0
var touch_axis := Vector2.ZERO
var touch_sprint := false
var moving_speed := 0.0
var walking_phase := 0.0
var limb_weight := 0.0
var next_step := PI
var orbit_delay := 0.0
var headlamp := false

var hiker := Node3D.new()
var car := Node3D.new()
var lens := Camera3D.new()
var lamp := SpotLight3D.new()
var hiker_parts: Dictionary
var wheels: Array = []
var footsteps := AudioStreamPlayer.new()
var engine := AudioStreamPlayer.new()

func _ready() -> void:
	hiker.name = "Viajante"
	car.name = "Perua"
	add_child(hiker)
	add_child(car)
	var art := Art.new()
	hiker_parts = art.build_hiker(hiker)
	wheels = art.build_car(car)
	lens.name = "CameraOrbital"
	lens.fov = 64
	lens.near = 0.08
	lens.far = 650
	add_child(lens)
	lens.make_current()
	lamp.name = "Lanterna"
	lamp.light_color = Color(1.0, 0.87, 0.60)
	lamp.spot_range = 19.0
	lamp.spot_angle = 30.0
	lamp.light_energy = 2.5
	lamp.shadow_enabled = false
	add_child(lamp)
	lamp.visible = false
	add_child(footsteps)
	add_child(engine)
	footsteps.stream = _make_audio(false)
	engine.stream = _make_audio(true)
	footsteps.volume_db = -15
	engine.volume_db = -21
	_place_models()
	_position_camera(1.0, true)

func set_active(on: bool) -> void:
	if active == on:
		return
	active = on
	touch_axis = Vector2.ZERO
	touch_sprint = false
	if not on:
		car_speed = 0.0
		moving_speed = 0.0
		engine.stop()
		footsteps.stop()
	elif driving:
		engine.play()

func set_touch_move(axis: Vector2) -> void:
	touch_axis = axis.limit_length(1.0) if active else Vector2.ZERO

func set_sprinting(on: bool) -> void:
	touch_sprint = on and active

func is_driving() -> bool:
	return driving

func set_lantern(on: bool) -> void:
	headlamp = on
	lamp.visible = headlamp

func look_delta(delta: Vector2) -> void:
	if not active:
		return
	orbit = wrapf(orbit - delta.x * 0.006, -PI, PI)
	elevation = clampf(elevation + delta.y * 0.0045, 0.025, 1.0)
	orbit_delay = 2.0

func _unhandled_input(event: InputEvent) -> void:
	if not active or OS.has_feature("mobile"):
		return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT):
		look_delta(event.relative)
		get_viewport().set_input_as_handled()

func _axis() -> Vector2:
	var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y := float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	return (Vector2(x, y) + touch_axis).limit_length(1.0)

func _forward(angle: float) -> Vector2:
	return Vector2(-sin(angle), -cos(angle))

func _side(angle: float) -> Vector2:
	return Vector2(cos(angle), -sin(angle))

func _free(point: Vector2, radius: float) -> bool:
	if point.x < -84 or point.x > 84 or point.y < -87 or point.y > 79:
		return false
	return not terrain.blocked(point, radius)

func _car_clear(point: Vector2, heading: float) -> bool:
	var longitudinal := _forward(heading) * 1.33
	return _free(point,0.91) and _free(point+longitudinal,0.87) and _free(point-longitudinal,0.87)

func _can_walk(point: Vector2) -> bool:
	if not _free(point, WALK_RADIUS):
		return false
	var offset := point-car_point
	var along := absf(offset.dot(_forward(car_yaw)))
	var across := absf(offset.dot(_side(car_yaw)))
	return along > 2.16+WALK_RADIUS or across > 0.86+WALK_RADIUS

func _walk(delta: float, axis: Vector2) -> void:
	var speed := 6.8 if (touch_sprint or Input.is_key_pressed(KEY_SHIFT)) else 3.9
	var wish := _side(orbit) * axis.x - _forward(orbit) * axis.y
	var motion := wish * speed * delta
	var old := walk_point
	var target := old + motion
	if _can_walk(target):
		walk_point = target
	else:
		target = Vector2(old.x + motion.x,old.y)
		if _can_walk(target):
			walk_point = target
		target = walk_point + Vector2(0, motion.y)
		if _can_walk(target):
			walk_point = target
	var travelled := walk_point - old
	moving_speed = travelled.length() / maxf(delta,0.0001)
	if travelled.length_squared() > 0.000001:
		facing = lerp_angle(facing,atan2(-travelled.x,-travelled.y),1.0-exp(-delta*15.0))
	var target_weight := clampf(moving_speed/3.9,0,1.25)
	limb_weight = lerpf(limb_weight,target_weight,1.0-exp(-delta*13.0))
	walking_phase += delta * (3.65 + moving_speed * 1.78)
	_animate_hiker()
	if walking_phase >= next_step:
		next_step = walking_phase + PI
		if moving_speed > 0.8:
			footsteps.pitch_scale = 0.9 + 0.12 * sin(walking_phase*1.75)
			footsteps.play()
	if walking_phase > 10000.0:
		walking_phase = fmod(walking_phase,TAU)
		next_step = walking_phase + PI

func _animate_hiker() -> void:
	var body: Node3D = hiker_parts.body
	body.position.y = 0.89 + (0.5-0.5*cos(2.0*walking_phase))*0.047*limb_weight
	body.rotation.x = -0.07*limb_weight
	body.rotation.z = sin(walking_phase)*0.029*limb_weight
	for j in range(2):
		var phase := walking_phase + j*PI
		var thigh: Node3D = hiker_parts.legs[j]
		var knee: Node3D = hiker_parts.knees[j]
		var arm: Node3D = hiker_parts.arms[j]
		thigh.rotation.x = sin(phase)*0.63*limb_weight
		knee.rotation.x = -maxf(0.0,sin(phase-1.5))*0.82*limb_weight
		arm.rotation.x = -sin(phase)*0.54*limb_weight
		arm.rotation.z = (-1.0 if j == 0 else 1.0) * (0.045 + 0.03*limb_weight)

func _drive(delta: float, axis: Vector2) -> void:
	var goal := -axis.y * (13.0 if axis.y < 0 else 5.0)
	var accel := 3.7 if absf(axis.y) < 0.1 else 6.5
	if goal * car_speed < 0:
		accel = 12
	car_speed = move_toward(car_speed,goal,accel*delta)
	var turn := -axis.x * clampf(car_speed/3.5,-1,1) * delta * 1.28
	var new_yaw := wrapf(car_yaw+turn,-PI,PI)
	if _car_clear(car_point,new_yaw):
		car_yaw = new_yaw
	var target := car_point + _forward(car_yaw) * car_speed * delta
	if _car_clear(target,car_yaw):
		car_point = target
	else:
		car_speed = 0
	walk_point = car_point
	moving_speed = absf(car_speed)
	for wheel: Node3D in wheels:
		wheel.rotate_x(-car_speed*delta/0.367)
	engine.pitch_scale = 0.78+absf(car_speed)*0.057
	if absf(car_speed)>1.0 and orbit_delay<=0.0:
		orbit = lerp_angle(orbit,car_yaw,1.0-exp(-1.85*delta))

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(terrain):
		return
	var axis := _axis()
	orbit_delay = maxf(0,orbit_delay-delta)
	if driving:
		_drive(delta,axis)
	else:
		_walk(delta,axis)
	_place_models()
	_position_camera(delta)

func _world_point(point: Vector2) -> Vector3:
	return Vector3(point.x,terrain.ground_height(point.x,point.y),point.y)

func _place_models() -> void:
	hiker.position = _world_point(walk_point)
	hiker.rotation.y = facing
	hiker.visible = not driving
	car.position = _world_point(car_point)
	car.rotation.y = car_yaw
	var fore := _forward(car_yaw)
	var side := _side(car_yaw)
	var height_delta := _world_point(car_point+fore).y - _world_point(car_point-fore).y
	var sideways := _world_point(car_point+side*0.7).y - _world_point(car_point-side*0.7).y
	car.rotation.x = clampf(atan2(height_delta,2),-0.20,0.20)
	car.rotation.z = clampf(atan2(sideways,1.4),-0.17,0.17)
	var frame := car if driving else hiker
	var light_angle := car_yaw if driving else facing
	var forward := _forward(light_angle)
	var origin := frame.position + Vector3.UP * (0.86 if driving else 1.37)
	lamp.position = origin + Vector3(forward.x,0,forward.y)*(2.18 if driving else 0.22)
	lamp.rotation = Vector3(-0.12,light_angle,0)
	lamp.visible = headlamp

func _position_camera(delta: float, snap: bool = false) -> void:
	var point := car_point if driving else walk_point
	var focus := _world_point(point) + Vector3.UP * (1.33 if driving else 1.38)
	var distance := 7.0 if driving else 4.65
	var behind := -_forward(orbit)
	var offset := Vector3(behind.x*cos(elevation),sin(elevation),behind.y*cos(elevation))
	# Shorten the orbit progressively at solid walls. A clear sightline
	# expands smoothly when the traveller leaves the occluder.
	var available := distance
	for i in range(1,13):
		var t := distance * i / 12.0
		var check := focus + offset*t
		if terrain.blocked(Vector2(check.x,check.z),0.11):
			available = maxf(0.56,t-distance/12.0-0.16)
			break
	var end := focus + offset * available
	end.y = maxf(end.y,terrain.ground_height(end.x,end.z)+0.29)
	var t := 1.0 if snap else (1.0-exp(-delta*16.0))
	if focus.distance_to(lens.position) > available+0.22:
		t = 1.0
	lens.position = lens.position.lerp(end,t)
	if lens.position.distance_squared_to(focus)>0.001:
		lens.look_at(focus)

func get_player_map() -> Vector2:
	return car_point if driving else walk_point

func get_bearing() -> float:
	return fposmod(rad_to_deg(-orbit),360.0)

func get_nearest() -> String:
	if driving:
		return "carro"
	var best := ""
	var best_distance := NEAR_RANGE
	for id in terrain.POIS:
		var poi: Dictionary = terrain.POIS[id]
		var distance := walk_point.distance_to(Vector2(float(poi.x),float(poi.z)))
		if distance <= best_distance:
			best = str(id)
			best_distance = distance
	if walk_point.distance_to(car_point) <= minf(CAR_RANGE,best_distance):
		return "carro"
	return best

func toggle_vehicle() -> bool:
	if not driving:
		if walk_point.distance_to(car_point) > CAR_RANGE:
			return false
		driving = true
		walk_point = car_point
		orbit = car_yaw
		car_speed = 0
		if active:
			engine.play()
	else:
		var exit_found := false
		for offset: Vector2 in [Vector2(-1.65,0),Vector2(1.65,0),Vector2(-1.65,-1.2),Vector2(1.65,1.2),Vector2(0,-2.85),Vector2(0,2.85)]:
			var candidate := car_point + _side(car_yaw)*offset.x + _forward(car_yaw)*offset.y
			if _can_walk(candidate):
				walk_point = candidate
				exit_found = true
				break
		if not exit_found:
			return true
		driving = false
		facing = car_yaw
		car_speed = 0
		engine.stop()
	_place_models()
	_position_camera(1.0,true)
	return driving

func get_player_state() -> Dictionary:
	return {"x":walk_point.x,"z":walk_point.y,"yaw":orbit,"pitch":elevation,
		"facing":facing,"car_x":car_point.x,"car_z":car_point.y,
		"car_yaw":car_yaw,"driving":driving,"lamp":headlamp}

func set_player_state(state: Dictionary) -> void:
	var stored_car := Vector2(float(state.get("car_x",PARKING.x)),float(state.get("car_z",PARKING.y)))
	car_yaw = float(state.get("car_yaw",-0.18))
	car_point = stored_car if _car_clear(stored_car,car_yaw) else PARKING
	driving = bool(state.get("driving",false))
	var stored_player := Vector2(float(state.get("x",START.x)),float(state.get("z",START.y)))
	walk_point = stored_player if _can_walk(stored_player) else START
	if driving:
		walk_point = car_point
	facing = float(state.get("facing",0))
	orbit = float(state.get("yaw",0.19))
	elevation = clampf(float(state.get("pitch",0.28)),0.025,1.0)
	car_speed = 0
	moving_speed = 0
	limb_weight = 0
	headlamp = bool(state.get("lamp",false))
	engine.stop()
	if driving and active:
		engine.play()
	_animate_hiker()
	_place_models()
	_position_camera(1.0,true)

func _make_audio(motor: bool) -> AudioStreamWAV:
	var sample_rate := 16000
	var count := 16000 if motor else 2560
	var data := PackedByteArray()
	data.resize(count*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1485
	var noise := 0.0
	for i in range(count):
		var t := float(i)/sample_rate
		var value: float
		if motor:
			# Integer periods match at the loop seam.
			value = (sin(TAU*47*t)+0.46*sin(TAU*94*t)+0.19*sin(TAU*141*t))*(0.27+0.05*sin(TAU*9*t))
		else:
			noise = 0.68*noise + 0.32*rng.randf_range(-1,1)
			var envelope := minf(1,t*180)*exp(-28*t)
			value = (noise*0.84+sin(TAU*(100*t-155*t*t))*0.28)*envelope
		data.encode_s16(2*i,int(clampf(value,-1,1)*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	if motor:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream
