extends Node

func _ready() -> void:
    _test_loads_settings_file()

func _test_loads_save_file():
    print("Persister Test: Loads a sav file into `save` and emits appropriate signals")
    pass

func _test_loads_settings_file():
    print("Persister Test: Loads a tres file into `settings` and calls setters on all properties")
    pass