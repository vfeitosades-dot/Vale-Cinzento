extends RefCounted

const FILE := "user://travessia.json"
const BAK := "user://travessia.bak"
const TMP := "user://travessia.tmp"

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
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if valid(value) else {}

static func load_campaign() -> Dictionary:
	for path in [FILE, BAK]:
		var data := read_one(path)
		if not data.is_empty():
			return data
	return {}

static func write_campaign(data: Dictionary) -> bool:
	if not valid(data):
		return false
	var file := FileAccess.open(TMP, FileAccess.WRITE)
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
	if not read_one(FILE).is_empty() and dir.copy(FILE, BAK) != OK:
		return false
	if dir.file_exists(FILE) and dir.remove(FILE) != OK:
		return false
	return dir.rename(TMP, FILE) == OK
