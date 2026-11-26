extends Node

const Land = preload("res://world/landscape.gd")
const Traveller = preload("res://world/traveller.gd")
const FieldUI = preload("res://ui/field_ui.gd")
const Book = preload("res://gameplay/field_book.gd")
const Store = preload("res://gameplay/save_store.gd")
const Soundscape = preload("res://gameplay/soundscape.gd")

var field
var actor
var hud
var sound
var data: Dictionary = {}
var playing := false
var suspended := false
var muted := false
var refresh := 0.0
var autosave := 0.0
var camp_visuals: Node3D
var verify := false

func _ready() -> void:
	verify = "--verificar-travessia" in OS.get_cmdline_user_args()
	sound = Soundscape.new()
	add_child(sound)
	hud = FieldUI.new()
	add_child(hud)
	hud.command.connect(_command)
	hud.move_input.connect(func(axis: Vector2): 
		if playing and not suspended: actor.set_touch_move(axis))
	hud.look_input.connect(func(delta: Vector2):
		if playing and not suspended: actor.look_delta(delta))
	hud.sprint_input.connect(func(on: bool):
		if playing and not suspended: actor.set_sprinting(on))
	var prefs := ConfigFile.new()
	if prefs.load("user://preferencias.cfg") == OK:
		muted = prefs.get_value("audio","silencio",false)
	AudioServer.set_bus_mute(0,muted)
	hud.show_title(not Store.load_campaign().is_empty())
	if verify:
		call_deferred("_smoke")
	elif "--capturar-vale" in OS.get_cmdline_user_args():
		call_deferred("_capture")

func _fresh() -> Dictionary:
	return {"version":1,"seed":randi_range(10,999999),"clock":8.25,"energy":94.0,"thirst":88.0,"hunger":90.0,
		"inventory":{"I083":1},"water":0,"visited":{},"built":{},"daily":{},"position":{},
		"journal":["Você chegou ao Abrigo da Figueira. Há uma carta de papel sobre a mesa."],
		"crop":-1,"ending":false,"lantern":false}

func _start(snapshot: Dictionary) -> void:
	if is_instance_valid(field):
		remove_child(field)
		field.queue_free()
	field = Land.new()
	field.world_seed = int(snapshot.seed)
	add_child(field)
	actor = Traveller.new()
	actor.terrain = field
	field.add_child(actor)
	camp_visuals = Node3D.new()
	field.add_child(camp_visuals)
	data = snapshot.duplicate(true)
	if not data.position.is_empty():
		actor.set_player_state(data.position)
	actor.set_lantern(data.get("lantern",false))
	playing = true
	suspended = false
	refresh = 0.0
	autosave = 0.0
	actor.set_active(true)
	_refresh_props()
	hud.show_game()
	_refresh_view()

func _process(delta: float) -> void:
	if not playing or suspended:
		return
	var dt := minf(delta,0.2)
	var elapsed_hours := dt / 120.0
	data.clock += elapsed_hours
	data.energy = maxf(8.0,data.energy-elapsed_hours*(2.5 if not actor.is_driving() else 1.1))
	data.thirst = maxf(0.0,data.thirst-elapsed_hours*4.1)
	data.hunger = maxf(0.0,data.hunger-elapsed_hours*2.7)
	if data.hunger < 10 or data.thirst < 10:
		data.energy = maxf(8.0,data.energy-elapsed_hours*2.0)
	refresh += dt
	autosave += dt
	if refresh >= 0.22:
		refresh = 0.0
		_refresh_view()
	if autosave >= 45:
		autosave = 0
		if not _persist():
			hud.toast("Não foi possível salvar a expedição.")

func _day() -> int:
	return floori(float(data.clock)/24.0)+1

func _hour() -> float:
	return fposmod(float(data.clock),24.0)

func _weather() -> String:
	var patterns := ["Céu aberto","Nublado","Neblina","Garoa","Céu aberto","Chuva","Nublado"]
	if data.clock < 15.0:
		return "Céu aberto"
	var period := floori(float(data.clock)/7.0)
	return patterns[posmod(int(data.seed)+period,patterns.size())]

func _add(id: String, amount: int) -> void:
	var next := int(data.inventory.get(id,0))+amount
	if next <= 0:
		data.inventory.erase(id)
	else:
		data.inventory[id] = next

func _journal(message: String) -> void:
	data.journal.append("Dia %02d  ·  %s" % [_day(),message])
	if data.journal.size() > 100:
		data.journal.remove_at(0)

func _bench() -> bool:
	return actor.get_nearest() in ["abrigo","oficina"] and not actor.is_driving()

func _can_craft(recipe: Array) -> bool:
	return _bench() and int(data.inventory.get(recipe[1],0))>0 and int(data.inventory.get(recipe[2],0))>0

func _craft(id: String) -> void:
	if not Book.RECIPES.has(id):
		return
	var r: Array = Book.RECIPES[id]
	if not _can_craft(r):
		hud.toast("Use a bancada do abrigo ou da oficina e confira os materiais.")
		return
	_add(r[1],-1)
	_add(r[2],-1)
	_add(r[0],1)
	hud.toast("Fabricado: "+str(Book.NAMES[r[0]]))
	_journal("Você fabricou "+str(Book.NAMES[r[0]]).to_lower()+".")
	sound.chime()

func _goal() -> Array:
	if not data.visited.has("abrigo"):
		return ["abrigo","Examine a mesa do abrigo"]
	if not data.visited.has("oficina"):
		return ["oficina","Procure ripas na oficina"]
	if not data.visited.has("ponte"):
		return ["ponte","Encontre o pigmento na ponte"]
	if not data.built.has("I093") and not data.inventory.has("I093"):
		return ["oficina","Fabrique um marcador na bancada"]
	if not data.visited.has("reservatorio"):
		return ["reservatorio","Anote a leitura do reservatório"]
	if not data.built.has("I093"):
		return ["mirante","Instale o marcador no mirante"]
	if not data.get("ending",false):
		return ["mirante","Transmita o boletim no mirante"]
	if data.visited.size() < 6:
		return ["mercado","Complete a carta dos seis lugares"]
	return ["","Travessia registrada. O vale é seu para explorar."]

func _usable(id: String) -> bool:
	return Book.FOOD.has(id) or id in ["I040","I053","I060","I079","I084"] or (id>="I091" and id<="I100")

func _use(id: String) -> void:
	if not data.inventory.has(id):
		return
	var near: String = actor.get_nearest()
	if Book.FOOD.has(id):
		if data.hunger >= 99:
			hud.toast("Você já comeu o suficiente.")
			return
		_add(id,-1)
		data.hunger = minf(100.0,data.hunger+float(Book.FOOD[id]))
		hud.toast("Você comeu "+str(Book.NAMES[id]).to_lower()+".")
	elif id == "I040":
		if data.thirst >= 99 and data.hunger >= 99:
			hud.toast("Guarde o suco para a caminhada.")
			return
		_add(id,-1)
		data.thirst = minf(100.0,data.thirst+32.0)
		data.hunger = minf(100.0,data.hunger+6.0)
		hud.toast("Você bebeu o suco.")
	elif id == "I060":
		if int(data.water) <= 0:
			hud.toast("Garrafa vazia. Reabasteça na ponte ou no reservatório.")
		elif data.thirst >= 99:
			hud.toast("Sua sede já está saciada.")
		else:
			data.water -= 1
			data.thirst = minf(100.0,data.thirst+37.0)
			hud.toast("Você bebeu água. Restam %d de 3 porções." % int(data.water))
	elif id == "I053":
		data.lantern = not data.get("lantern",false)
		actor.set_lantern(data.lantern)
		hud.toast("Lanterna acesa." if data.lantern else "Lanterna apagada.")
	elif id == "I084":
		hud.toast("Boletim do vale · "+_weather()+". "+str(_goal()[1])+".")
	elif id == "I079":
		_plant(near)
	elif id>="I091" and id<="I100":
		_install(id,near)

func _plant(near: String) -> void:
	if near != "abrigo" or not data.built.has("I099"):
		hud.toast("Instale uma caixa de mudas no abrigo primeiro.")
	elif float(data.get("crop",-1)) >= 0:
		hud.toast("Já há um plantio na caixa.")
	else:
		_add("I079",-1)
		data.crop = float(data.clock)+20.0
		_journal("Você semeou a caixa de mudas. A colheita leva cerca de um dia.")
		hud.toast("Sementes plantadas.")
		_refresh_props()

func _install(id: String, near: String) -> void:
	if data.built.has(id):
		hud.toast("Este projeto já foi instalado.")
		return
	var target := "abrigo"
	if id=="I093": target="mirante"
	if id=="I098": target="carro"
	if near != target:
		hud.toast("Use este item "+("perto da perua." if target=="carro" else "no "+str(Book.LABELS.get(target,target))+"."))
		return
	_add(id,-1)
	data.built[id] = true
	if id=="I091":
		_add("I029",2)
		_add("I038",1)
	_journal(str(Book.NAMES[id])+" instalado.")
	_refresh_props()
	hud.toast("Instalado: "+str(Book.NAMES[id]))
	sound.chime()

func _prompt(near: String) -> String:
	if near=="carro":
		return "Descer da perua" if actor.is_driving() else "Dirigir a perua Estação"
	if near.is_empty(): return ""
	if not data.visited.has(near):
		return {"abrigo":"Examinar a mesa","mercado":"Vasculhar a mercearia","oficina":"Abrir o armário","ponte":"Examinar a caixa azul","reservatorio":"Ler a régua de nível","mirante":"Investigar o transmissor"}.get(near,"Examinar")
	if near=="abrigo":
		if _ripe(): return "Colher a caixa de mudas"
		return "Descansar por 8 horas"
	if near in ["ponte","reservatorio"]: return "Encher a garrafa"
	if near=="oficina": return "Recolher sobras da bancada"
	if near=="mercado": return "Colher no pomar"
	if near=="mirante":
		if not data.built.has("I093") and data.inventory.has("I093"): return "Instalar marcador de trilha"
		if not data.get("ending",false): return "Sintonizar o transmissor"
		return "Ouvir o vale"
	return ""

func _ripe() -> bool:
	return float(data.get("crop",-1))>=0 and float(data.clock)>=float(data.crop)

func _interact() -> void:
	var near: String = actor.get_nearest()
	if near.is_empty(): return
	if near=="carro":
		actor.toggle_vehicle()
		hud.toast("W/S ou manche para acelerar e frear." if actor.is_driving() else "Você desceu da perua.")
		return
	if not data.visited.has(near) and Book.LOOT.has(near):
		data.visited[near] = true
		for id in Book.LOOT[near]:
			_add(id,int(Book.LOOT[near][id]))
		_journal(Book.ENTRIES[near])
		if near in ["reservatorio","ponte"] and data.inventory.has("I060"): data.water=3
		hud.toast("Descoberta · "+str(Book.LABELS[near])+"  |  Veja os achados na mochila.")
		sound.chime()
		return
	match near:
		"abrigo":
			if _ripe():
				_add("I021",4)
				_add("I079",2)
				data.crop=-1
				_refresh_props()
				hud.toast("Colheita: quatro maçãs e duas sementes.")
			else:
				data.clock += 8
				data.energy=minf(100,data.energy+(72 if data.built.has("I094") else 58))
				data.hunger=maxf(0,data.hunger-13)
				data.thirst=maxf(0,data.thirst-18)
				hud.toast("Você descansou por oito horas.")
		"ponte","reservatorio":
			if data.inventory.has("I060"):
				data.water=3
				hud.toast("Garrafa cheia · 3 porções.")
			else: hud.toast("Há uma garrafa na mesa do abrigo.")
		"mercado","oficina":
			if int(data.daily.get(near,0))==_day():
				hud.toast("Você já passou aqui hoje.")
			else:
				data.daily[near]=_day()
				if near=="mercado":
					_add("I021",2)
					hud.toast("Duas maçãs maduras no pomar da mercearia.")
				else:
					for id in ["I066","I067","I073","I075","I068","I069"]: _add(id,1)
					hud.toast("Você separou materiais da pilha de sobras.")
		"mirante":
			if not data.built.has("I093") and data.inventory.has("I093"):
				_install("I093",near)
			elif data.built.has("I093") and data.visited.has("reservatorio") and not data.get("ending",false):
				data.ending=true
				_journal("O boletim atravessou o vale. Do outro lado do rádio, uma voz respondeu: «Passagem registrada. Bom caminho.»")
				hud.toast("«Recebido, Mirante.» O vale voltou a responder.")
				sound.chime(true)
			elif data.get("ending",false): hud.toast("Entre o vento e a estática, chega outra saudação.")
			else: hud.toast("O boletim precisa do marcador instalado e da leitura do reservatório.")

func _command(action: String, arg: String = "") -> void:
	if action=="new_game":
		_start(_fresh())
		_persist()
		return
	if action=="continue":
		var saved := Store.load_campaign()
		if saved.is_empty(): hud.toast("Nenhum registro de expedição disponível.")
		else: _start(saved)
		return
	if action=="mute":
		muted=arg=="on"
		AudioServer.set_bus_mute(0,muted)
		var config:=ConfigFile.new()
		config.set_value("audio","silencio",muted)
		config.save("user://preferencias.cfg")
		if playing: _refresh_view()
		return
	if not playing: return
	match action:
		"pause","resume":
			suspended=action=="pause"
			actor.set_active(not suspended)
		"save":
			hud.toast("Expedição salva." if _persist() else "Falha ao gravar o registro.")
		"menu":
			if not _persist():
				hud.toast("Não foi possível salvar a expedição.")
				return
			playing=false
			actor.set_active(false)
			hud.show_title(true)
		"interact":
			if suspended: return
			_interact()
		"craft": _craft(arg)
		"use": _use(arg)
	if playing:
		_refresh_view()
		if action in ["interact","craft","use"]: _persist()

func _persist() -> bool:
	if not playing or not is_instance_valid(actor): return false
	data.position = actor.get_player_state()
	return Store.write_campaign(data)

func _notification(what: int) -> void:
	if (what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST) and playing:
		_persist()

func _refresh_view() -> void:
	if not playing: return
	var pos: Vector2=actor.get_player_map()
	var near: String=actor.get_nearest()
	var hour:=_hour()
	var weather:=_weather()
	field.set_environment(hour,weather)
	field.set_observer(pos)
	if actor.has_method("set_tired"):
		actor.set_tired(data.energy < 22 or data.thirst < 10 or data.hunger < 10)
	sound.environment(hour,weather)
	var rows: Array=[]
	for id in Book.NAMES:
		if data.inventory.has(id):
			var desc:=Book.description(id)
			if id=="I060": desc+="  •  %d/3 porções" % int(data.water)
			rows.append({"id":id,"name":Book.NAMES[id],"count":int(data.inventory[id]),"description":desc,"usable":_usable(id)})
	var recipes: Array=[]
	for id in Book.RECIPES:
		var r: Array=Book.RECIPES[id]
		var needs:="%s + %s" % [Book.NAMES[r[1]],Book.NAMES[r[2]]]
		if not _bench(): needs+="  ·  Bancada no abrigo ou na oficina"
		recipes.append({"id":id,"name":Book.NAMES[r[0]],"requirements":needs,"can_craft":_can_craft(r)})
	var marks: Array=[]
	var region:="Estrada do vale"
	var best:=INF
	for id in Book.LANDMARKS:
		var site: Dictionary=Land.POIS[id]
		var dist:=pos.distance_to(Vector2(site.x,site.z))
		if dist<best:
			best=dist
			region=Book.LABELS[id]
		marks.append({"id":id,"name":Book.LABELS[id],"x":site.x,"z":site.z,"visited":data.visited.has(id)})
	if best>20.0: region="Estrada do vale"
	if actor.is_driving(): region="Perua Estação · "+region
	var goal:=_goal()
	var message:=str(goal[1])
	if goal[0]!="":
		var site: Dictionary=Land.POIS[goal[0]]
		var offset:=Vector2(float(site.x),float(site.z))-pos
		var points:=["N","NE","L","SE","S","SO","O","NO"]
		var direction: String=points[posmod(roundi(rad_to_deg(atan2(offset.x,-offset.y))/45.0),8)]
		message+="  ·  %d m %s" % [roundi(offset.length()),direction]
	hud.set_state({"day":_day(),"time":"%02d:%02d" % [floori(hour),floori(fposmod(hour,1)*60)],
		"weather":weather,"region":region,"objective":message,"prompt":_prompt(near),"energy":roundi(data.energy),
		"thirst":roundi(data.thirst),"hunger":roundi(data.hunger),"items":rows,"recipes":recipes,"markers":marks,
		"player_x":pos.x,"player_z":pos.y,"heading":actor.get_bearing(),"journal":data.journal.duplicate(),"muted":muted})

func _piece(parent: Node3D, at: Vector3, size_m: Vector3, color: Color, tilt := 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size=size_m
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=0.94
	mesh.material=mat
	var block:=MeshInstance3D.new()
	block.mesh=mesh
	parent.add_child(block)
	block.position=at
	block.rotation.z=tilt

func _refresh_props() -> void:
	for child in camp_visuals.get_children():
		camp_visuals.remove_child(child)
		child.queue_free()
	var oak:=Color("#825d40")
	var cloth:=Color("#a28d58")
	var bronze:=Color("#48594f")
	for key in data.built:
		var id:=str(key)
		if id=="I098":
			continue
		var index:=int(id.substr(1))-91
		var pt:=Vector2(-14.0+float(index%3)*1.5,42.0+floori(index/3.0)*1.15)
		if id=="I093": pt=Vector2(17,-63)
		var prop:=Node3D.new()
		camp_visuals.add_child(prop)
		prop.position=Vector3(pt.x,field.ground_height(pt.x,pt.y),pt.y)
		match id:
			"I093","I100":
				_piece(prop,Vector3(0,0.8,0),Vector3(0.11,1.6,0.11),oak)
				_piece(prop,Vector3(0,1.4,0),Vector3(1.1,0.48,0.1),bronze)
				_piece(prop,Vector3(0,1.4,0.07),Vector3(0.63,0.06,0.04),Color("#ede3bf"))
			"I094": _piece(prop,Vector3(0,0.035,0),Vector3(1.2,0.05,0.8),cloth)
			"I095":
				for x in [-0.48,0.48]:
					_piece(prop,Vector3(x,0.6,0),Vector3(0.08,1.2,0.49),oak)
				for y in [0.12,0.63,1.13]:
					_piece(prop,Vector3(0,y,0),Vector3(1.0,0.08,0.53),cloth)
			_:
				var h:=0.3 if id in ["I096","I097","I099"] else 0.57
				var paint:=Color("#ac7153") if id=="I096" else oak
				for x in [-0.38,0.38]:
					_piece(prop,Vector3(x,h/2.0,0),Vector3(0.08,h,0.62),paint)
				for z in [-0.31,0.31]:
					_piece(prop,Vector3(0,h/2.0,z),Vector3(0.8,h,0.06),paint)
				_piece(prop,Vector3(0,h*0.55,0),Vector3(0.7,0.1,0.55),Color("#514435"))
				if id=="I099" and float(data.get("crop",-1))>=0:
					for x in [-0.21,0.0,0.22]:
						_piece(prop,Vector3(x,h+0.08,0),Vector3(0.09,0.27,0.08),Color("#7d9959"),x)
	if actor.has_method("set_seat_cover"):
		actor.set_seat_cover(data.built.has("I098"))

func _go_to(id: String) -> void:
	var p: Dictionary=Land.POIS[id]
	var snapshot: Dictionary=actor.get_player_state()
	snapshot.x=p.x
	snapshot.z=p.z
	snapshot.driving=false
	actor.set_player_state(snapshot)
	_refresh_view()

func _check(value: bool, note: String) -> bool:
	if not value:
		push_error("QA: "+note)
		get_tree().quit(1)
	return value

func _smoke() -> void:
	_command("new_game")
	for id in Book.LANDMARKS:
		_go_to(id)
		if not _check(actor.get_nearest()==id,"acesso ao ponto "+id): return
		_command("interact")
		if not _check(data.visited.has(id),"descoberta "+id): return
	_go_to("oficina")
	_command("craft","R03")
	if not _check(int(data.inventory.get("I093",0))==1,"marcador fabricado"): return
	_go_to("mirante")
	_command("interact")
	_command("interact")
	if not _check(data.get("ending",false),"final da travessia"): return
	_go_to("reservatorio")
	_command("interact")
	data.thirst=50
	_command("use","I060")
	if not _check(data.water==2 and data.thirst>50,"garrafa"): return
	var drive_state: Dictionary=actor.get_player_state()
	drive_state.x=float(drive_state.car_x)+2.0
	drive_state.z=drive_state.car_z
	actor.set_player_state(drive_state)
	_command("interact")
	if not _check(actor.is_driving(),"entrar na perua"): return
	_command("interact")
	if not _check(not actor.is_driving(),"descer da perua"): return
	_go_to("abrigo")
	_command("craft","R09")
	_command("use","I099")
	_command("use","I079")
	for i in 3: _command("interact")
	if not _check(_ripe(),"crescimento da horta"): return
	_command("interact")
	if not _check(int(data.inventory.get("I021",0))>=4,"colheita"): return
	_command("pause")
	var before: float=data.clock
	_process(1.0)
	if not _check(data.clock==before,"tempo parado no caderno"): return
	_command("resume")
	var old_inv: Dictionary=data.inventory.duplicate()
	_command("menu")
	_command("continue")
	if not _check(playing and data.get("ending",false) and data.inventory==old_inv,"save e retomada"): return
	print("TRAVESSIA_OK")
	get_tree().quit(0)

func _capture() -> void:
	var snap:=_fresh()
	snap.seed=718
	snap.clock=16.4
	_start(snap)
	_go_to("ponte")
	var camera_pose: Dictionary=actor.get_player_state()
	camera_pose.yaw=-0.52
	camera_pose.pitch=0.22
	actor.set_player_state(camera_pose)
	_refresh_view()
	for _i in range(8):
		await RenderingServer.frame_post_draw
	var screenshot:=get_viewport().get_texture().get_image()
	var result:=screenshot.save_png(OS.get_environment("VALE_CAPTURA"))
	get_tree().quit(0 if result==OK else 1)
