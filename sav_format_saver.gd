@tool
extends ResourceFormatSaver
class_name SavFormatSaver

const COMPRESSED_EXT = "sav"
const UNCOMPRESSED_EXT = "tsav"

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
    return PackedStringArray([COMPRESSED_EXT, UNCOMPRESSED_EXT])


# Return true if this resource should be loaded as a SaveFile 
func _recognize(resource: Resource) -> bool:
    if resource.has_meta("savefile_as_resource"): return false
    if resource is SaveFile: return true
    return false


# Save the resource
func _save(resource: Resource, path: String = '', flags: int = 0) -> int:

    # Create a temporary duplicate and use ResourceSaver to convert it to file text
    var temp_resource = resource.duplicate(true)
    temp_resource.set_meta("savefile_as_resource", true)
    var temp_path = "user://.temp_save_file.tres"
    ResourceSaver.save(resource, temp_path)
    var file_as_string = FileAccess.get_file_as_string(temp_path).replace("metadata/savefile_as_resource = true", "")
    DirAccess.remove_absolute(temp_path)

    # Open the sav or tsav file and store the file text from earlier
    var file: FileAccess
    if path.ends_with("." + COMPRESSED_EXT): file = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
    elif path.ends_with("." + UNCOMPRESSED_EXT): file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(file_as_string)
    file.close()

    # Fix metadata on the Resource, like resource_path
    resource.take_over_path(path)

    return OK