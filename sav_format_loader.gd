@tool
class_name SavFormatLoader
extends ResourceFormatLoader

const COMPRESSED_EXT = "sav"
const UNCOMPRESSED_EXT = "tsav"

# Returns all accepted extensions
func _get_recognized_extensions() -> PackedStringArray:
    return PackedStringArray([COMPRESSED_EXT, UNCOMPRESSED_EXT])


# Returns "Resource" if this file can/should be loaded by this script
func _get_resource_type(path: String) -> String:
    var ext = path.get_extension().to_lower()
    if ext == COMPRESSED_EXT || ext == UNCOMPRESSED_EXT: return "Resource"
    return ""


# Return true if this type is handled
func _handles_type(typename: StringName) -> bool:
    return ClassDB.is_parent_class(typename, "Resource")


# Read a string of resource file contents and return true if it contains malicious code
func _is_malicious(file_as_text: String):

    # Use a regex to find any instance of an embedded GDScript resource.
    var embeddedScriptRegex: RegEx = RegEx.new()
    embeddedScriptRegex.compile("type\\s*=\\s*\"GDScript\"\\s*")	
    if embeddedScriptRegex.search(file_as_text) != null: return true

    # Use a regex to find any reference to an external resource outside "res://"
    var extResourceRegex: RegEx = RegEx.new()
    extResourceRegex.compile("\\[\\s*ext_resource\\s*.*?path\\s*=\\s*\"([^\"]*)\".*?\\]")
    var matches: Array = extResourceRegex.search_all(file_as_text)
    for match in matches:
        var resourcePath: String = match.get_string(1)
        if not resourcePath.begins_with("res://"): return true
    
    return false


# Parse the file and return a resource
func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int):

    # Get file contents as text
    var file: FileAccess
    if path.ends_with("." + COMPRESSED_EXT): file = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
    elif path.ends_with("." + UNCOMPRESSED_EXT): file = FileAccess.open(path, FileAccess.READ)
    if not file: return file.get_open_error()
    var file_as_text = file.get_as_text()
    file.close()

    # Make sure save file doesn't contain malicious code
    if _is_malicious(file_as_text): return ERR_CANT_CREATE

    # Copy file text to a temporary tres file, use ResourceLoader to parse it and get a Resource
    var temp_path = "user://.temp_save_file.tres"
    var temp_file = FileAccess.open(temp_path, FileAccess.WRITE)
    temp_file.store_string(file_as_text)
    temp_file.close()
    var resource = ResourceLoader.load(temp_path)
    DirAccess.remove_absolute(temp_path)

    # Fix metadata on the Resource, like resource_path
    resource.resource_path = path

    return resource as SaveFile
    
