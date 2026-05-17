class_name SettingsFile
extends Resource

# Schema version of this settings file on disk. Persister stamps this on store
# (from Persister.settings_migrations.current_version()) and SettingsMigrations
# advances it on load. Don't mutate from _init() — the file's version must
# always win, never the script's default. Leave this at 0 here; it gets
# overwritten before anything that cares ever reads it.
@export var version: int = 0
