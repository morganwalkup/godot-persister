class_name SaveFile
extends Resource

# Schema version of this save file on disk. Persister stamps this on store and
# SaveMigrations advances it on load. Don't mutate from _init() — the file's
# version must always win, never the script's default.
@export var version: int = SaveMigrations.CURRENT_VERSION