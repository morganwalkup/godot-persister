class_name SaveFile
extends Resource

# Schema version of this save file on disk. Persister stamps this on store
# (from Persister.migrations.current_version()) and SaveMigrations advances it
# on load. Don't mutate from _init() — the file's version must always win,
# never the script's default. Leave this at 0 here; it gets overwritten before
# anything that cares ever reads it.
@export var version: int = 0