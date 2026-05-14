extends Node

# Save files are serialized as a versioned Dictionary written via var_to_str.
# - `.tsav` -> plain text (use in development; hand-editable)
# - `.sav`  -> ZSTD-compressed text (use in shipped builds)
#
# Settings still go through ResourceLoader/Saver for now; they're a separate
# concern and don't need versioned migrations.

const SETTINGS_PATH = "user://settings.tres"

const COMPRESSED_EXT = "sav"
const UNCOMPRESSED_EXT = "tsav"

var save: SaveFile = SaveFile.new()
var settings: SettingsFile = SettingsFile.new()

signal before_load_save()
signal after_load_save()
signal before_store_save()
signal after_store_save()


func load_save(path: String) -> void:
	before_load_save.emit()
	var text: String = _read_text(path)
	if text == "":
		push_error("Persister.load_save: could not read save at %s" % path)
		after_load_save.emit()
		return
	var parsed: Variant = str_to_var(text)
	if not (parsed is Dictionary):
		push_error("Persister.load_save: save at %s did not parse to a Dictionary" % path)
		after_load_save.emit()
		return
	var migrated: Dictionary = SaveMigrations.migrate(parsed)
	var loaded: Resource = DictSerializer.from_dict(migrated)
	if loaded is SaveFile:
		save = loaded
	else:
		push_error("Persister.load_save: deserialized save is not a SaveFile (got %s)" % type_string(typeof(loaded)))
	after_load_save.emit()


func store_save(path: String, save_file: SaveFile = save) -> void:
	before_store_save.emit()
	save_file.version = SaveMigrations.CURRENT_VERSION
	var dict: Dictionary = DictSerializer.to_dict(save_file)
	dict["version"] = SaveMigrations.CURRENT_VERSION
	var text: String = var_to_str(dict)
	_write_text(path, text)
	after_store_save.emit()


func list_saves() -> PackedStringArray:
	var save_filenames: PackedStringArray = []
	for filename in DirAccess.get_files_at("user://"):
		if filename.ends_with("." + COMPRESSED_EXT) || filename.ends_with("." + UNCOMPRESSED_EXT):
			save_filenames.push_back(filename)
	return save_filenames


func view_save(path: String) -> SaveFile:
	var text: String = _read_text(path)
	if text == "":
		return null
	var parsed: Variant = str_to_var(text)
	if not (parsed is Dictionary):
		return null
	var migrated: Dictionary = SaveMigrations.migrate(parsed)
	var resource: Resource = DictSerializer.from_dict(migrated)
	return resource as SaveFile


func delete_save(path: String) -> void:
	DirAccess.remove_absolute(path)


func load_settings(path: String = SETTINGS_PATH) -> void:
	settings = ResourceLoader.load(path)


func store_settings(path: String = SETTINGS_PATH, settings_file: SettingsFile = settings) -> void:
	ResourceSaver.save(settings_file, path)


func delete_settings(path: String = SETTINGS_PATH) -> void:
	DirAccess.remove_absolute(path)


func _read_text(path: String) -> String:
	var file: FileAccess
	if path.ends_with("." + COMPRESSED_EXT):
		file = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	else:
		file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _write_text(path: String, text: String) -> void:
	var file: FileAccess
	if path.ends_with("." + COMPRESSED_EXT):
		file = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Persister: could not open %s for writing (err %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(text)
	file.close()
