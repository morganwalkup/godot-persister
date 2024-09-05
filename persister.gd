extends Node

var save: SaveFile = SaveFile.new()
var settings: SettingsFile = SettingsFile.new()

const SETTINGS_PATH = "user://settings.tres"

signal before_load_save()
signal after_load_save()
signal before_store_save()
signal after_store_save()

func load_save(path: String) -> void:
    before_load_save.emit()
    save = ResourceLoader.load(path)
    after_load_save.emit()

func store_save(path: String, save_file: SaveFile = save) -> void:
    before_store_save.emit()
    ResourceSaver.save(save_file, path)
    after_store_save.emit()

func list_saves() -> Array[String]:
    var save_filenames = []
    for filename in DirAccess.get_files_at("user://"):
        if filename.ends_with(".sav") || filename.ends_with(".tsav"):
            save_filenames.push_back(filename)
    return save_filenames

func view_save(path: String) -> SaveFile:
    return ResourceLoader.load(path)

func delete_save(path: String) -> void:
    DirAccess.remove_absolute(path)

func load_settings(path: String = SETTINGS_PATH) -> void:
    settings = ResourceLoader.load(path) # Automatically calls all property setters

func store_settings(path: String = SETTINGS_PATH, settings_file: SettingsFile = settings) -> void:
    ResourceSaver.save(settings_file, path) # Automatically calls all property getters (twice, for some reason)

func delete_settings(path: String = SETTINGS_PATH) -> void:
    DirAccess.remove_absolute(path)
