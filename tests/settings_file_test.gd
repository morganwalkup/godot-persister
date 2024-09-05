extends Node

func _ready() -> void:
    _test_saves_and_reloads()
    _test_saves_and_loads_extended_class()

func _test_saves_and_reloads():
    print("SettingsFile Test: Saves a resource to the filesystem and reloads it")
    var settings_file_path = "res://addons/persister/tests/test_settings.tres"
    var settings_file: SettingsFile = SettingsFile.new()
    settings_file.version = "1.2.3"
    ResourceSaver.save(settings_file, settings_file_path)
    assert(FileAccess.file_exists(settings_file_path), "❌")

    var loaded_settings_file = ResourceLoader.load(settings_file_path)
    DirAccess.remove_absolute(settings_file_path)
    assert(loaded_settings_file.version == "1.2.3", "❌")
    print("✅")

func _test_saves_and_loads_extended_class():
    print("SettingsFile Test: Saves an extended resource to the filesystem and reloads it")
    var settings_file_path = "res://addons/persister/tests/test_extended_settings.tres"
    var settings_file: ExampleSettingsFile = ExampleSettingsFile.new()
    settings_file.version = "3.2.1"
    settings_file.some_value = 5.1 # Calls some_value.set
    ResourceSaver.save(settings_file, settings_file_path) # Calls some_value.get (twice, for some reason)
    assert(FileAccess.file_exists(settings_file_path), "❌")

    var loaded_settings_file = ResourceLoader.load(settings_file_path) # Calls some_value.set
    DirAccess.remove_absolute(settings_file_path)
    assert(loaded_settings_file.getter_was_called == false, "❌")
    assert(loaded_settings_file.setter_was_called == true, "❌")
    assert(loaded_settings_file.version == "3.2.1", "❌")
    assert(loaded_settings_file.some_value == 5.1, "❌")
    assert(loaded_settings_file.getter_was_called == true, "❌")
    assert(loaded_settings_file.input_dictionary["ui_down"] != null, "❌")
    print("✅")
