class_name SaveMigrations
extends RefCounted

# Base class for save-file migration chains.
#
# This base is a no-op: current_version() returns 0 and _step() just stamps the
# dict to current. Project code should subclass this, override current_version()
# and _step(), and tell Persister to use the subclass:
#
#     # In main.gd, before any Persister.load_save / store_save calls:
#     Persister.migrations = KinspritSaveMigrations.new()
#
# Subclasses must follow two rules:
#   - Migrations only ever move forward. Never write a v(N) -> v(N-1) step.
#   - Treat dict keys as a wire format. Once a key ships, it lives in this file
#     forever, even if the corresponding GDScript field is later renamed.


# Override in subclasses to return the latest known schema version.
func current_version() -> int:
	return 0


# Walk the dict forward through _step() until it reaches current_version().
# Subclasses generally shouldn't need to override this — override _step instead.
func migrate(d: Dictionary) -> Dictionary:
	var version: int = int(d.get("version", 0))
	var target: int = current_version()
	if version > target:
		push_warning("SaveMigrations.migrate: save was written by a newer version (%d > %d). Loading as-is." % [version, target])
		return d
	while version < target:
		d = _step(d, version)
		version = int(d.get("version", version + 1))
	return d


# Apply a single forward migration step. Override in subclasses and dispatch
# off `from_version` to the appropriate migrator. The default implementation
# warns and stamps the dict to current_version() so loads don't get stuck.
func _step(d: Dictionary, from_version: int) -> Dictionary:
	push_warning("SaveMigrations: no migrator registered from version %d; stamping to %d and continuing" % [from_version, current_version()])
	d["version"] = current_version()
	return d
