class_name DictSerializer
extends RefCounted

# Generic Resource <-> Dictionary serialization.
#
# Used by Persister to convert save files into plain Dictionaries that can be
# written to disk via var_to_str, fed through versioned migrations, and
# rehydrated into Resource instances on load.
#
# Resources are looked up by their script class_name (the "_class" key in the
# dict) via ProjectSettings.get_global_class_list. This avoids embedding script
# paths on disk, so renaming or moving a script doesn't brick saved files.

const _SKIP_PROPS: Array[StringName] = [
	&"resource_local_to_scene",
	&"resource_path",
	&"resource_name",
	&"resource_scene_unique_id",
	&"script",
]

# Cache of class_name -> Script. Populated lazily on first lookup.
static var _class_to_script: Dictionary[StringName, Script] = {}


static func to_dict(r: Resource) -> Dictionary:
	if r == null:
		return {}
	var d: Dictionary = {}
	var script: Script = r.get_script() as Script
	if script != null:
		var cn: StringName = script.get_global_name()
		if cn != &"":
			d["_class"] = String(cn)
	for prop in r.get_property_list():
		if not (prop.usage & PROPERTY_USAGE_STORAGE):
			continue
		var prop_name: StringName = prop.name
		if prop_name in _SKIP_PROPS:
			continue
		if String(prop_name).begins_with("metadata/"):
			continue
		d[String(prop_name)] = _encode_value(r.get(prop_name))
	return d


static func from_dict(d: Dictionary) -> Resource:
	if d.is_empty():
		return null
	var cn_str: String = d.get("_class", "")
	if cn_str == "":
		push_error("DictSerializer.from_dict: dict is missing required '_class' key")
		return null
	var script: Script = _find_script_for_class(StringName(cn_str))
	if script == null:
		push_error("DictSerializer.from_dict: no script found for class '%s'" % cn_str)
		return null
	var r: Resource = script.new()
	for key_variant in d.keys():
		var key: String = key_variant
		if key == "_class":
			continue
		_apply_value(r, key, d[key])
	return r


static func _encode_value(value: Variant) -> Variant:
	if value is Resource:
		return to_dict(value)
	if value is Array:
		var out: Array = []
		for item in value:
			out.append(_encode_value(item))
		return out
	if value is Dictionary:
		var out_d: Dictionary = {}
		for k in value.keys():
			out_d[k] = _encode_value(value[k])
		return out_d
	return value


# Apply an encoded value to a property on the given resource. Handles typed
# arrays by mutating the existing array in place (Array.assign), which is the
# only way to push values into a typed array via reflection.
static func _apply_value(r: Resource, key: String, encoded: Variant) -> void:
	var existing: Variant = r.get(key)
	if existing is Array and encoded is Array:
		var decoded_items: Array = []
		for item in encoded:
			decoded_items.append(_decode_value(item))
		var typed: Array = existing
		typed.clear()
		typed.assign(decoded_items)
		return
	r.set(key, _decode_value(encoded))


static func _decode_value(encoded: Variant) -> Variant:
	if encoded is Dictionary and encoded.has("_class"):
		return from_dict(encoded)
	if encoded is Array:
		var out: Array = []
		for item in encoded:
			out.append(_decode_value(item))
		return out
	if encoded is Dictionary:
		var out_d: Dictionary = {}
		for k in encoded.keys():
			out_d[k] = _decode_value(encoded[k])
		return out_d
	return encoded


static func _find_script_for_class(cn: StringName) -> Script:
	if _class_to_script.has(cn):
		return _class_to_script[cn]
	for entry in ProjectSettings.get_global_class_list():
		if StringName(entry["class"]) == cn:
			var script: Script = load(entry["path"]) as Script
			_class_to_script[cn] = script
			return script
	return null
