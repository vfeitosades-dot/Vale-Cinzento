extends CanvasLayer

signal command(action: String, arg: String)
signal move_input(axis: Vector2)
signal look_input(delta: Vector2)
signal sprint_input(on: bool)

const Art = preload("res://ui/field_art.gd")
const TouchField = preload("res://ui/touch_field.gd")
const FOREST := Color("#202d28")
const DEEP := Color("#15211e")
const CREAM := Color("#f3ebd2")
const QUIET := Color("#c4c9b6")
const SUN := Color("#edba78")
const MOSS := Color("#9eab87")
const EDGE := Color("#55665a")
const PAGES := {"bag":"Mochila","craft":"Fabricação","map":"Mapa","journal":"Diário"}
const KEYS := {"bag":"I","craft":"C","map":"M","journal":"J"}

var surface: Control
var title_layer: Control
var hud: Control
var modal: Control
var touch
var data: Dictionary = {}
var mode := "title"
var page := ""
var has_campaign := false
var clock_label: Label
var weather_label: Label
var objective_label: Label
var action_btn: Button
var stats: Dictionary = {}
var toast_box: PanelContainer
var toast_label: Label
var toast_timer: Timer
var content: VBoxContainer
var scroller: ScrollContainer
var last_list := ""
var map_view
var native_touch := false
var in_title_help := false
var modal_title: Label

func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	native_touch = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	surface = Control.new()
	add_child(surface)
	_fill(surface)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_make_title()
	_make_hud()
	_make_toast()
	show_title(false)

func _fill(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _place(node: Control, anchor: Rect2, inset: Vector4) -> void:
	node.anchor_left = anchor.position.x
	node.anchor_top = anchor.position.y
	node.anchor_right = anchor.end.x
	node.anchor_bottom = anchor.end.y
	node.offset_left = inset.x
	node.offset_top = inset.y
	node.offset_right = inset.z
	node.offset_bottom = inset.w

func _skin(fill_color: Color, border: Color, pad_x: int = 14, pad_y: int = 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill_color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box

func _panel(parent: Control, background: Color = FOREST, padding: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	parent.add_child(p)
	p.add_theme_stylebox_override("panel",_skin(background,EDGE,padding,padding))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _vbox(parent: Control, gap: int = 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	parent.add_child(box)
	box.add_theme_constant_override("separation",gap)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box

func _hbox(parent: Control, gap: int = 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	parent.add_child(box)
	box.add_theme_constant_override("separation",gap)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box

func _label(parent: Control, value: String, pixels: int, ink: Color = CREAM, wraps: bool = false) -> Label:
	var lab := Label.new()
	lab.text = value
	lab.add_theme_font_size_override("font_size",pixels)
	lab.add_theme_color_override("font_color",ink)
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wraps:
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lab)
	return lab

func _button(parent: Control, value: String, callback: Callable, main: bool = false, compact: bool = false) -> Button:
	var btn := Button.new()
	btn.text = value
	btn.custom_minimum_size.y = 41 if compact else 47
	btn.add_theme_font_size_override("font_size",16 if compact else 18)
	var fill_color := SUN if main else Color("#33443a")
	btn.add_theme_stylebox_override("normal",_skin(fill_color,Color("#bc955e") if main else EDGE,12,5))
	btn.add_theme_stylebox_override("hover",_skin(Color("#f3cc96") if main else Color("#415849"),CREAM,12,5))
	btn.add_theme_stylebox_override("pressed",_skin(Color("#c89154") if main else Color("#52674f"),SUN,12,5))
	btn.add_theme_stylebox_override("disabled",_skin(Color("#29352f"),Color("#465248"),12,5))
	var focus := _skin(Color.TRANSPARENT,SUN,1,1)
	focus.draw_center = false
	focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus",focus)
	for part in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
		btn.add_theme_color_override(part,DEEP if main else CREAM)
	btn.add_theme_color_override("font_disabled_color",Color("#abb5a4"))
	parent.add_child(btn)
	btn.pressed.connect(callback)
	return btn

func _hr(parent: Control) -> void:
	var line := ColorRect.new()
	line.color = EDGE
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _spacer(parent: Control, pixels: int) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0,pixels)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(gap)

func _make_title() -> void:
	title_layer = Control.new()
	surface.add_child(title_layer)
	_fill(title_layer)
	var art = Art.new()
	title_layer.add_child(art)
	_fill(art)
	_title_buttons()

func _title_buttons() -> void:
	if title_layer.has_node("Intro"):
		var old := title_layer.get_node("Intro")
		title_layer.remove_child(old)
		old.queue_free()
	var frame := _panel(title_layer,Color("#23332e"),28)
	frame.name = "Intro"
	_place(frame, Rect2(0,0.50,0,0), Vector4(48,-227,470,227))
	var stack := _vbox(frame,4)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_label(stack,"TRAVESSIA DO VALE",15,SUN)
	var nameplate := _label(stack,"VALE\nCINZENTO",55)
	nameplate.add_theme_constant_override("line_spacing",-9)
	_spacer(stack,4)
	_hr(stack)
	_spacer(stack,4)
	_label(stack,"Um abrigo, um rádio e seis lugares para redescobrir.",19,QUIET,true)
	_spacer(stack,8)
	if has_campaign:
		_button(stack,"Continuar travessia",_emit.bind("continue",""),true)
	_button(stack,"Nova travessia",_new_game,not has_campaign)
	_button(stack,"Controles",_open.bind("help"),false,true)

func _new_game() -> void:
	if has_campaign:
		_open("confirm")
	else:
		_emit("new_game","")

func _make_hud() -> void:
	hud = Control.new()
	surface.add_child(hud)
	_fill(hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch = TouchField.new()
	hud.add_child(touch)
	_fill(touch)
	touch.move_vector.connect(func(axis: Vector2): move_input.emit(axis))
	touch.turn_camera.connect(func(delta: Vector2): look_input.emit(delta))
	touch.running.connect(func(on: bool): sprint_input.emit(on))
	var world_panel := _panel(hud, Color(0.09,0.14,0.12,0.91),11)
	_place(world_panel,Rect2(0,0,0,0),Vector4(20,18,254,88))
	var world_text := _vbox(world_panel,1)
	clock_label = _label(world_text,"",20)
	weather_label = _label(world_text,"",14,QUIET)
	var vitals_panel := _panel(hud,Color(0.09,0.14,0.12,0.91),9)
	_place(vitals_panel,Rect2(1,0,0,0),Vector4(-208,18,-20,91))
	var vitals := _vbox(vitals_panel,2)
	for pair in [["energy","Energia",Color("#c3ce9d")],["thirst","Água",Color("#91c5cc")],["hunger","Comida",Color("#efb882")]]:
		var row := _hbox(vitals,8)
		var caption := _label(row,str(pair[1]),13,QUIET)
		caption.custom_minimum_size.x = 50
		var gauge := ProgressBar.new()
		gauge.show_percentage = false
		gauge.custom_minimum_size = Vector2(89,7)
		gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gauge.add_theme_stylebox_override("background",_skin(Color("#495849"),Color.TRANSPARENT,0,0))
		gauge.add_theme_stylebox_override("fill",_skin(pair[2],Color.TRANSPARENT,0,0))
		row.add_child(gauge)
		stats[pair[0]] = gauge
	var objective_panel := _panel(hud,Color(0.10,0.15,0.13,0.85),9)
	_place(objective_panel,Rect2(0,0,0,0),Vector4(20,98,304,151))
	var obj := _vbox(objective_panel,1)
	_label(obj,"NO DIÁRIO",12,SUN)
	objective_label = _label(obj,"",15,CREAM,true)
	var bar := _hbox(hud,5)
	_place(bar,Rect2(0.5,1,0,0),Vector4(-237,-65,237,-19))
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	for key in ["bag","craft","map","journal"]:
		var caption := str(PAGES[key])
		if not native_touch:
			caption += " · " + str(KEYS[key])
		_button(bar,caption,_open.bind(key),false,true)
	_button(bar,"Pausa",_open.bind("pause"),false,true)
	action_btn = _button(hud,"Interagir",_emit.bind("interact",""),true,true)
	_place(action_btn,Rect2(1,1,0,0),Vector4(-252,-127,-20,-74))
	touch.blocked_controls = [bar,action_btn] as Array[Control]

func _make_toast() -> void:
	toast_box = _panel(surface,DEEP,12)
	_place(toast_box,Rect2(0.5,0,0,0),Vector4(-208,21,208,67))
	toast_box.z_index = 10
	toast_label = _label(toast_box,"",16,CREAM,true)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_box.hide()
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.timeout.connect(func(): toast_box.hide())
	add_child(toast_timer)

func toast(message: String) -> void:
	if not is_instance_valid(toast_box):
		return
	toast_label.text = message
	toast_box.show()
	toast_timer.start(3.8)

func _emit(action: String, arg: String = "") -> void:
	command.emit(action,arg)

func _clear_modal() -> void:
	if is_instance_valid(modal):
		modal.hide()
		surface.remove_child(modal)
		modal.queue_free()
	modal = null
	content = null
	scroller = null
	map_view = null
	page = ""
	last_list = ""

func show_title(has_save: bool) -> void:
	if not is_instance_valid(surface):
		return
	has_campaign = has_save
	mode = "title"
	_clear_modal()
	touch.active = false
	touch.reset()
	hud.hide()
	title_layer.show()
	_title_buttons()
	toast_box.hide()

func show_game() -> void:
	mode = "game"
	_clear_modal()
	title_layer.hide()
	hud.show()
	touch.active = true
	touch.queue_redraw()
	_sync_hud()

func set_state(value: Dictionary) -> void:
	data = value
	if not is_instance_valid(hud):
		return
	_sync_hud()
	if page == "map" and is_instance_valid(map_view):
		map_view.survey = data
		map_view.queue_redraw()
	elif is_instance_valid(content) and page in ["bag","craft","journal","pause"]:
		var key := _list_key()
		if key != last_list:
			_populate()

func _sync_hud() -> void:
	clock_label.text = "DIA %02d   /   %s" % [int(data.get("day",1)),str(data.get("time","07:30"))]
	weather_label.text = str(data.get("region","Vale Cinzento")) + "  ·  " + str(data.get("weather","Aberto"))
	objective_label.text = str(data.get("objective","Explore o vale."))
	for field in stats:
		stats[field].value = clampf(float(data.get(field,100)),0,100)
	var prompt := str(data.get("prompt",""))
	action_btn.visible = not prompt.is_empty()
	action_btn.text = prompt if native_touch else "E   " + prompt

func _open(which: String) -> void:
	if mode == "game" and page == which:
		_close()
		return
	var entering := page.is_empty()
	_clear_modal()
	page = which
	if entering and mode == "game":
		touch.active = false
		touch.reset()
		hud.hide()
		_emit("pause")
	modal = Control.new()
	surface.add_child(modal)
	_fill(modal)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	modal.add_child(shade)
	_fill(shade)
	shade.color = Color(0.05,0.09,0.08,0.75)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := _panel(modal,FOREST,19)
	_place(frame,Rect2(0.5,0.5,0,0),Vector4(-376,-263,376,263))
	var stack := _vbox(frame,8)
	var header := _hbox(stack,10)
	modal_title = _label(header,_page_name(),29)
	modal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header,"Voltar",_close,false,true)
	if which in PAGES:
		var tabs := _hbox(stack,6)
		for tab in PAGES:
			var b := _button(tabs,str(PAGES[tab]),_open.bind(str(tab)),tab == which,true)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.disabled = tab == which
	_hr(stack)
	if which == "map":
		map_view = Art.new()
		map_view.sheet = "map"
		map_view.survey = data
		map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stack.add_child(map_view)
		_label(stack,"▲  Sua posição       •  Ponto do vale",15,QUIET)
		return
	scroller = ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroller)
	content = _vbox(scroller,8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate()

func _page_name() -> String:
	if page in PAGES:
		return str(PAGES[page])
	return str({"pause":"Pausa","help":"Controles","confirm":"Iniciar nova travessia?"}.get(page,"Caderno"))

func _list_key() -> String:
	match page:
		"bag": return str(data.get("items",[]))
		"craft": return str(data.get("recipes",[]))
		"journal": return str(data.get("objective","")) + str(data.get("journal",[]))
		"pause": return str(data.get("muted",false))
	return page

func _populate() -> void:
	last_list = _list_key()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	match page:
		"bag":
			var items: Array = data.get("items",[])
			if items.is_empty():
				_label(content,"A mochila está vazia. Procure suprimentos nos pontos do vale.",19,QUIET,true)
			for it in items:
				var row := _entry(str(it.get("name","Item"))+"   ×"+str(it.get("count",1)),str(it.get("description","")))
				if bool(it.get("usable",false)):
					_button(row,"Usar",_emit.bind("use",str(it.get("id",""))),true,true)
		"craft":
			var recipes: Array = data.get("recipes",[])
			for recipe in recipes:
				var row := _entry(str(recipe.get("name","Receita")),str(recipe.get("requirements","")))
				var can_make := bool(recipe.get("can_craft",false))
				var b := _button(row,"Fabricar" if can_make else "Indisponível",_emit.bind("craft",str(recipe.get("id",""))),can_make,true)
				b.disabled = not can_make
			if recipes.is_empty():
				_label(content,"As receitas aparecem aqui quando disponíveis.",18,QUIET,true)
		"journal":
			_label(content,"OBJETIVO ATUAL",14,SUN)
			_label(content,str(data.get("objective","Explore o vale.")),22,CREAM,true)
			_spacer(content,6)
			_hr(content)
			var entries: Array = data.get("journal",[])
			for i in range(entries.size()-1,-1,-1):
				_label(content,"•  " + str(entries[i]),17,QUIET,true)
		"pause":
			_button(content,"Retomar travessia",_close,true)
			_button(content,"Salvar agora",_emit.bind("save",""))
			var muted := bool(data.get("muted",false))
			_button(content,"Ativar áudio" if muted else "Silenciar áudio",_emit.bind("mute","off" if muted else "on"))
			_button(content,"Controles",_open.bind("help"))
			_button(content,"Voltar ao menu inicial",_emit.bind("menu",""))
		"help":
			_label(content,"TECLADO E MOUSE",14,SUN)
			_entry("W A S D  ou  setas","Caminhar ou conduzir. Shift para correr a pé.")
			_entry("Arrastar o mouse","Girar a câmera em volta do personagem.")
			_entry("E  ·  I  ·  C  ·  M  ·  J","Interagir, abrir mochila, fabricação, mapa e diário. Esc pausa ou fecha o caderno.")
			_label(content,"TELA DE TOQUE",14,SUN)
			_entry("Esquerda para andar · direita para olhar","Arraste no lado esquerdo. Estenda o movimento para correr. Deslize no lado direito para girar a câmera.")
			_entry("Interagir","Toque na ação dourada ao chegar perto de um ponto do vale.")
		"confirm":
			_label(content,"A nova travessia substituirá a campanha salva neste aparelho.",20,CREAM,true)
			_spacer(content,12)
			_button(content,"Manter a campanha atual",_close,true)
			_button(content,"Substituir e começar",_emit.bind("new_game",""))

func _entry(title: String, detail: String) -> HBoxContainer:
	var card := _panel(content,Color("#2d3b33"),10)
	var row := _hbox(card,12)
	var words := _vbox(row,2)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(words,title,18,CREAM,true)
	if not detail.is_empty():
		_label(words,detail,15,QUIET,true)
	return row

func _close() -> void:
	if page == "help" and mode == "game":
		_open("pause")
		return
	_clear_modal()
	if mode == "game":
		hud.show()
		touch.active = true
		touch.queue_redraw()
		_emit("resume")
	else:
		title_layer.show()

func _back() -> void:
	if not page.is_empty():
		_close()
	elif mode == "game":
		_open("pause")
	elif OS.has_feature("mobile"):
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var code := (event as InputEventKey).keycode
	if code == KEY_ESCAPE:
		_back()
	elif mode == "game":
		match code:
			KEY_E:
				if page.is_empty() and action_btn.visible:
					_emit("interact")
			KEY_I, KEY_B: _open("bag")
			KEY_C: _open("craft")
			KEY_M: _open("map")
			KEY_J: _open("journal")
			_: return
	else:
		return
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(surface):
		_back()
