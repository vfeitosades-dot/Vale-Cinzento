extends RefCounted

const FILE := "user://travessia.json"
const BAK := "user://travessia.bak"
const TMP := "user://travessia.tmp"

static func _path(path: String) -> String:
	if "--verificar-travessia" in OS.get_cmdline_user_args():
		return path.replace("user://","user://teste-")
	return path

static func valid(v: Variant) -> bool:
	if not v is Dictionary or v.get("version") != 1:
		return false
	for key in ["seed","clock","energy","hunger","thirst","water"]:
		if typeof(v.get(key)) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	for key in ["inventory","visited","built","daily","position"]:
		if not v.get(key) is Dictionary:
			return false
	return v.get("journal") is Array

static func read_one(path: String) -> Dictionary:
	path = _path(path)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not valid(value):
		return {}
	# JSON decodes all numbers as floats; restore integer game-state fields.
	var data: Dictionary = value
	data["version"] = int(data["version"])
	data["seed"] = int(data["seed"])
	data["water"] = int(data["water"])
	for section in ["inventory", "daily"]:
		var entries: Dictionary = data[section]
		for key in entries:
			entries[key] = int(entries[key])
	return data

static func load_campaign() -> Dictionary:
	for path in [FILE, BAK]:
		var data := read_one(path)
		if not data.is_empty():
			return data
	return {}

static func write_campaign(data: Dictionary) -> bool:
	if not valid(data):
		return false
	var file := FileAccess.open(_path(TMP), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if read_one(TMP).is_empty():
		return false
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if not read_one(FILE).is_empty() and dir.copy(_path(FILE), _path(BAK)) != OK:
		return false
	if dir.file_exists(_path(FILE)) and dir.remove(_path(FILE)) != OK:
		return false
	return dir.rename(_path(TMP), _path(FILE)) == OK
