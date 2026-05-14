class_name SaveMigrations
extends RefCounted

# Versioned migration chain for save file dictionaries.
#
# Disk format always carries a top-level "version" int. On load, this script
# walks the dict forward through every applicable migrator until it reaches
# CURRENT_VERSION, at which point Persister hands it to DictSerializer.from_dict
# for rehydration.
#
# Rules:
#   - Migrations only ever move forward. Never write a v(N) -> v(N-1) migrator.
#   - Each migrator is a pure Dictionary -> Dictionary transform. Don't touch
#     the engine, scene tree, or autoloads from in here.
#   - Treat dict keys as a wire format. Once a key name ships, it lives forever
#     in this file even if the corresponding GDScript field is renamed.

const CURRENT_VERSION: int = 1


static func migrate(d: Dictionary) -> Dictionary:
	var version: int = int(d.get("version", 0))
	if version > CURRENT_VERSION:
		push_warning("SaveMigrations.migrate: save was written by a newer version (%d > %d). Loading as-is." % [version, CURRENT_VERSION])
		return d
	while version < CURRENT_VERSION:
		d = _step(d, version)
		version = int(d.get("version", version + 1))
	return d


# Dispatch a single forward step. Each case bumps "version" to the target.
static func _step(d: Dictionary, from_version: int) -> Dictionary:
	match from_version:
		# Example for the future:
		# 1:
		#     d = _migrate_v1_to_v2(d)
		_:
			push_warning("SaveMigrations: no migrator from version %d; stamping to current and continuing" % from_version)
			d["version"] = CURRENT_VERSION
	return d


# Migrators go below as the schema evolves. Keep each one small and focused.
#
# static func _migrate_v1_to_v2(d: Dictionary) -> Dictionary:
#     d["player_position"] = d.get("player_world_position", Vector2.ZERO)
#     d.erase("player_world_position")
#     d["version"] = 2
#     return d
