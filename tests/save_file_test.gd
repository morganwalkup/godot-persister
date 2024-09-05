extends Node

func _ready() -> void:
    _test_saves_and_reloads()


func _test_saves_and_reloads():
    print("SaveFile Test: Saves a resource to the filesystem and reloads it")
    var uncompressed_save_file_path = "user://save_file_uncompressed.tsav"
    var uncompressed_save_file: SaveFile = SaveFile.new()
    uncompressed_save_file.version = "1.2.3"
    ResourceSaver.save(uncompressed_save_file, uncompressed_save_file_path)
    var loaded_uncompressed_save_file = ResourceLoader.load(uncompressed_save_file_path)
    assert(FileAccess.file_exists(uncompressed_save_file_path), "❌")
    DirAccess.remove_absolute(uncompressed_save_file_path)
    assert(loaded_uncompressed_save_file.version == "1.2.3", "❌")

    var compressed_save_file_path = "user://save_file_compressed.sav"
    var compressed_save_file: SaveFile = SaveFile.new()
    compressed_save_file.version = "5.6.7"
    ResourceSaver.save(compressed_save_file, compressed_save_file_path)
    var loaded_compressed_save_file = ResourceLoader.load(compressed_save_file_path)
    assert(FileAccess.file_exists(compressed_save_file_path), "❌")
    DirAccess.remove_absolute(compressed_save_file_path)
    assert(loaded_compressed_save_file.version == "5.6.7", "❌")

    print("✅")