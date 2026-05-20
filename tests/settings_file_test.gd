extends Node
# TODO: Update tests now that settings files are serialized as dictionaries

# func _ready() -> void:
#     _test_stores_and_loads_base_class()
#     _test_stores_and_loads_extended_class()


# func _test_stores_and_loads_base_class():
#     print("SettingsFile Test: Stores a base SettingsFile via Persister and reloads it")
#     var settings_path := "user://test_settings.tcfg"

#     var settings_file := SettingsFile.new()
#     Persister.store_settings(settings_path, settings_file)
#     assert(FileAccess.file_exists(settings_path), "❌ settings file was not written to disk")

#     Persister.load_settings(settings_path)
#     DirAccess.remove_absolute(settings_path)

#     var loaded := Persister.settings
#     assert(loaded is SettingsFile, "❌ loaded value is not a SettingsFile")
#     assert(loaded.version == Persister.settings_migrations.current_version(), "❌ loaded version was not stamped on store")
#     print("✅")


# func _test_stores_and_loads_extended_class():
#     print("SettingsFile Test: Stores an ExampleSettingsFile via Persister and reloads it")
#     var settings_path := "user://test_extended_settings.tcfg"

#     var settings_file := ExampleSettingsFile.new()
#     settings_file.some_value = 5.1 # Calls some_value.set
#     Persister.store_settings(settings_path, settings_file) # Calls some_value.get
#     assert(FileAccess.file_exists(settings_path), "❌ settings file was not written to disk")

#     Persister.load_settings(settings_path) # Calls some_value.set on the rebuilt instance
#     DirAccess.remove_absolute(settings_path)

#     var loaded := Persister.settings as ExampleSettingsFile
#     assert(loaded != null, "❌ loaded value is not an ExampleSettingsFile")
#     assert(loaded.getter_was_called == false, "❌ getter was called before we read some_value")
#     assert(loaded.setter_was_called == true, "❌ setter was not called when load_settings rebuilt the resource")
#     assert(loaded.version == Persister.settings_migrations.current_version(), "❌ loaded version was not stamped on store")
#     assert(loaded.some_value == 5.1, "❌ some_value did not round-trip")
#     assert(loaded.getter_was_called == true, "❌ getter was not called when we read some_value")
#     assert(loaded.input_dictionary["ui_down"] != null, "❌ input_dictionary did not round-trip")
#     print("✅")
