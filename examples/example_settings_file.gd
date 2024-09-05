class_name ExampleSettingsFile
extends SettingsFile

var getter_was_called = false
var setter_was_called = false

@export var some_value: float = 0.0:
    get:
        getter_was_called = true
        return some_value
    set(value):
        setter_was_called = true
        some_value = value

# Window settings
@export var window_size: Vector2i = Vector2i(1920, 1080):
    get:
        return window_size
    set(value):
        DisplayServer.window_set_size(value)
        window_size = value

# Audio settings
@export var master_volume_db: float = 0.0:
    get:
        return master_volume_db
    set(value):
        AudioServer.set_bus_volume_db(
            AudioServer.get_bus_index("Master"),
            value
        )
        master_volume_db = value

# Input settings
func _input_map_to_dictionary() -> Dictionary:
    var actions = {}
    for action_name in InputMap.get_actions():
        actions[action_name] = {
            "deadzone": InputMap.action_get_deadzone(action_name),
            "events": InputMap.action_get_events(action_name)
        }
    return actions

func _input_dictionary_to_map(value: Dictionary) -> void:
    for action_name in value:
        InputMap.erase_action(action_name)
        InputMap.add_action(action_name)
        InputMap.action_set_deadzone(action_name, value[action_name].deadzone)
        for event in value[action_name].events:
            InputMap.action_add_event(action_name, event)

@export var input_dictionary: Dictionary = _input_map_to_dictionary():
    get:
        return _input_map_to_dictionary()
    set(value):
        _input_dictionary_to_map(value)
        input_dictionary = value

# Revert values
func _property_can_revert(property: StringName) -> bool:
    if property == "some_value": return true
    if property == "window_size": return true
    if property == "master_volume_db": return true
    if property == "input_map": return true
    return false

func _property_get_revert(property: StringName) -> Variant:
    if property == "some_value": return 0.0
    if property == "window_size": return Vector2i(1920, 1080)
    if property == "master_volume_db": return 0.0
    if property == "input_map":
        InputMap.load_from_project_settings()
        return _input_map_to_dictionary()
    return false