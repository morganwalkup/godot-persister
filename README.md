# Persister

A Godot plugin for managing save files and settings files.

```py
# Extend the SaveFile, SettingsFile, SaveMigrations, and SettingsMigrations
# base classes to fit your game
Persister.save = MyGameSaveFile.new()
Persister.settings = MyGameSettingsFile.new()
Persister.migrations = MyGameSaveMigrations.new()
Persister.settings_migrations = MyGameSettingsMigrations.new()

# Load existing SaveFile data and SettingsFile data from disk
Persister.load_save("user://slot_0.sav")
Persister.load_settings()

# Write to and read from SaveFile and SettingsFile data during runtime
Persister.save.player_health = 100
print(Persister.save.player_name)
Persister.settings.window_size = Vector2i(1920, 1080)

# Save modifications to disk as needed
Persister.store_save("user://slot_0.sav")
Persister.store_settings()
```

### Persister Singleton

The Persister plugin declares a `Persister` singleton for managing save files and system settings files.

#### Persister properties

- save - SaveFile - A reference to the active `SaveFile` resource.
- settings - SettingsFile - A reference to the active `SettingsFile` resource.
- migrations - SaveMigrations - The migration chain Persister consults when loading saves and stamping versions. Defaults to a no-op base instance. Project code should replace this with a `SaveMigrations` subclass before any load_save / store_save call.
- settings_migrations - SettingsMigrations - The migration chain Persister consults when loading settings and stamping versions. Defaults to a no-op base instance. Project code should replace this with a `SettingsMigrations` subclass before any load_settings / store_settings call.

#### Persister methods

Save-file-related methods:
- load_save(path: FilePath) -> void - Finds the `.sav` or `.tsav` file stored at `path`, runs it through `Persister.migrations.migrate(...)`, and loads its values into the `save` variable
- store_save(path: FilePath, saveFile: SaveFile = Persister.save) -> void - Stamps `saveFile.version` with `Persister.migrations.current_version()` and stores the resource at the specified file path. By default, stores the value of the `save` variable
- list_saves() -> FilePath[] - Returns a list of all `.sav` or `.tsav` files stored in `user://`
- view_save(path: FilePath) -> SaveFile - Returns a `SaveFile` resource loaded from `path` (with migrations applied). Does not change the value of `save`.
- delete_save(path: FilePath) -> void - Deletes the `.sav` or `.tsav` file stored at `path`

Settings-file-related methods:
- load_settings(path: FilePath = "user://settings.tcfg") -> void - Reads the `.tcfg` file at `path`, runs it through `Persister.settings_migrations.migrate(...)`, and loads its values into the `settings` variable
- store_settings(path: FilePath = "user://settings.tcfg", settingsFile: SettingsFile = Persister.settings) -> void - Stamps `settingsFile.version` with `Persister.settings_migrations.current_version()` and stores the resource at the specified file path. By default, stores the value of the `settings` variable
- delete_settings(path: FilePath = "user://settings.tcfg") -> void - Deletes the `.tcfg` file at `path`. Does not modify the `settings` variable or any related runtime values

#### Persister signals

- before_load_save - Emitted just before a new `SaveFile` is loaded from the file system
- after_load_save - Emitted just after a new `SaveFile` is loaded from the file system, and just after the value of `Persister.save` is updated
- before_store_save - Emitted just before `Persister.save` is written to the file system
- after_store_save - Emitted just after `Persister.save` is written to the file system
- before_load_settings - Emitted just before a new `SettingsFile` is loaded from the file system
- after_load_settings - Emitted just after a new `SettingsFile` is loaded from the file system, and just after the value of `Persister.settings` is updated
- before_store_settings - Emitted just before `Persister.settings` is written to the file system
- after_store_settings - Emitted just after `Persister.settings` is written to the file system

### Save Files

Save Files track the player's progress and achievements within the game.

They should be saved on the user's local machine, should be regularly cloud-synced between devices, and should persist between gameplay sessions.

As a game designer, you should decide how many save files your game allows, and how often save data is updated.

Persister uses a custom `SaveFile` class for storing save data.

Save data can be stored in human-readable `.tsav` files or compressed `.sav` files depending on the needs of your game.

#### On-disk format

Save files are written as a versioned `Dictionary` serialized via `var_to_str`. This means:

- **Every property is written**, including ones still at their script-declared default. Compare this with `ResourceSaver`, which silently omits fields that match defaults — that omission makes deterministic migrations between schema versions effectively impossible.
- **Built-in types like `Vector2`, `Color`, `Rect2`, `NodePath`, `StringName`, etc. round-trip losslessly** thanks to `var_to_str`/`str_to_var`. No hand-written converters per type.
- **Script paths are not embedded.** Resources are looked up by their `class_name` at load time via `ProjectSettings.get_global_class_list`. You can move or rename a script in `res://` without bricking shipped saves.
- **The top-level dict carries a `version` int** that drives the migration chain (see below).

A `.tsav` file looks roughly like this:

```py
{
"_class": "ExampleSaveFile",
"version": 1,
"player_health": 50.0,
"player_position": Vector2(83.5, 348.9),
"inventory": {},
"opened_door": false
}
```

`.sav` files contain the same payload, ZSTD-compressed.

### Save File Examples

First, extend the `SaveFile` class to suit your game data.

Declare export vars to store any data that should persist between gameplay sessions.

```py
    class_name ExampleSaveFile
    extends SaveFile

    @export var player_health: float = 100.0
    @export var inventory: Dictionary = {}
    @export var opened_door: bool = false
```

Don't redeclare or initialize the inherited `version: int` field — Persister manages it for you on store, and `SaveMigrations` manages it on load.

Next, initialize `Persister` with your extended save file when the game starts:

```py
    Persister.save = ExampleSaveFile.new()
```

Finally, you may edit, store, and load data in your save file as needed:
```py
    Persister.load_save("user://slot_0.sav")
    Persister.save.player_health = 50.0
    Persister.store_save("user://slot_0.sav")
```

The finer details, like when to save and how many save files to maintain, are outside the scope of `Persister`.

### Save File Migrations

When you ship a game, save files written by old versions need to keep loading after you change the schema. Persister handles this through a `SaveMigrations` class that converts older dicts forward through a chain of small, focused transforms until the dict matches the current schema.

#### Why migrations are first-class here

The dict format above makes the rest of this easy:

- Adding a field is automatic — `from_dict` falls back to the script default if the key is missing.
- Renaming a field is a one-line migrator: `d["new_name"] = d.get("old_name", default); d.erase("old_name")`.
- Changing a field's type is a small migrator that converts the value.
- Removing a field is a one-line migrator that calls `d.erase(...)`.

Each migrator is a pure `Dictionary -> Dictionary` transform with no engine or scene tree dependencies, which makes them trivial to test.

#### Defining migrations

Extend `SaveMigrations` once per project:

```py
    class_name ExampleSaveMigrations
    extends SaveMigrations

    const CURRENT_VERSION: int = 2

    func current_version() -> int:
        return CURRENT_VERSION

    func _step(d: Dictionary, from_version: int) -> Dictionary:
        match from_version:
            0:
                return _migrate_v0_to_v1(d)
            1:
                return _migrate_v1_to_v2(d)
            _:
                return super._step(d, from_version)

    # v0 is anything written before this migration chain existed. Nothing to
    # transform — just stamp it forward.
    func _migrate_v0_to_v1(d: Dictionary) -> Dictionary:
        d["version"] = 1
        return d

    # Renamed player_world_position -> player_position.
    func _migrate_v1_to_v2(d: Dictionary) -> Dictionary:
        d["player_position"] = d.get("player_world_position", Vector2.ZERO)
        d.erase("player_world_position")
        d["version"] = 2
        return d
```

Then tell Persister to use it, **before any load_save or store_save call**:

```py
    func _ready() -> void:
        Persister.migrations = ExampleSaveMigrations.new()
        # ... load saves, etc. ...
```

The default `SaveMigrations` base class is a working no-op (`current_version() == 0`, `_step` warns and stamps to current), so saves still round-trip if you forget to wire up a subclass — you just don't get any real migration logic. For prototyping that's fine; for a shipped game you want a real subclass.

#### Migration rules of thumb

- **Migrations only ever move forward.** Never write a v(N) → v(N-1) step. If a user downgrades, they restore from a backup.
- **Bump `CURRENT_VERSION` and add a `_step` case in the same change.** Don't ship a schema change without the migrator that handles old saves.
- **Treat dict keys as a wire format.** Once a key name ships, it lives in your migration code forever, even if the corresponding GDScript field is later renamed.
- **Don't touch the engine, scene tree, or autoloads from inside a migrator.** They're pure data transforms.
- **Commit golden save files at each shipped version** (e.g. `tests/saves/v1_minimal.tsav`, `v2_full.tsav`) so future migrators can be exercised against real-shaped data.

### Save System Inspiration

Persister's approach to save files is heavily influenced by Godotneer's video here: https://www.youtube.com/watch?v=43BZsLZheA4&ab_channel=Godotneers

The following examples demonstrate how Persister might be used to recreate the save systems from several popular games.

**Pokemon Yellow**
- Number of save files: 1
- Save strategy: Manual, outside combat
- At startup, the player can select `Continue`, `New Game`, or `Options`
- `Options` are stored in `user://settings.tcfg`
- `New Game` loads nothing, playing the game from the default project state
- `Continue` loads data from `user://pokemon_yellow.sav`
- While playing, the player can save their progress manually by accessing the save menu
- Save menu stores data in `user://pokemon_yellow.sav`

**Kingdom Hearts**
- Number of save files: 99
- Save strategy: Manual, at save points
- At startup, the player can select `New Game` or `Load`
- Settings are basically non-existent, as this is an older, console-exclusive game
- `New Game` loads nothing, playing the game from the default project state
- `Load` allows the player to select a previous save file such as `user://kingdom_hearts_00.sav`
- While playing, the player can save their progress manually by reaching a save point
- The save point menu allows the player to select any save slot from 0 to 99, storing data in `user://kingdom_hearts_99.sav` (filename based on selected slot)

**Breath of the Wild**
- Number of save files: 1 manual save + 5 autosaves, 1 master-mode manual save + 1 master-mode autosave
- Save strategy: Autosaves regularly, manual save can be created at any time
- At startup, the player can select `Continue`, `New Game`, `Master Mode`, or `Options`
- `Options` are stored in `user://settings.tcfg`
- `New Game` loads nothing, playing the game from the default project state
- `Master Mode` allows the player to select `user://botw_master_auto.sav` or `user://botw_master.sav`
- `Continue` allows the player to select a previous auto save or manual save such as `user://botw_auto_2.sav` or `user://botw.sav`
- While playing, progress is saved in one of five autosave slots automatically at key points, with oldest files gettings wiped out.
- The player can save their progress manually at any time through the save menu, overriding `user://botw.sav`

**Elden Ring**
- Number of save files: 1 save per character, up to five characters
- Save strategy: Autosaves constantly, no manual saves
- At startup, the player can select `Continue`, `Load Game`, `New Game`, or `System`
- `System` sets values stored in `user://settings.tcfg`
- `New Game` starts the game from the default project state, allowing the user to create and name a new character
- `Load Game` allows the player to select a previous character save, such as `user://elden_ring_warrior.sav`
- `Continue` loads the last active save (not sure how they know which one was active)
- While playing, the active save is wiped out by regular autosaves (most likely, a backup is created during file operations)
- The player cannot manually save their progress, but can quit at any time which prompts an autosave if it's appropriate

# Settings Files

Settings Files (also known as "Options", "Configs", or "System Settings") modify the basic functions of the game on a per-device basis.

Players typically choose their settings within some sort of an "Options" menu. They can tweak things like resolution, audio volume, shadow quality, etc.

Settings Files should be saved on the user's local machine, should never be cloud-synced between devices, and should persist between gameplay sessions.

Persister uses a custom `SettingsFile` class for storing settings data.

Settings data is stored in human-readable `.tcfg` (text config) files. By default, Persister reads and writes a single settings file at `user://settings.tcfg`.

#### On-disk format

Settings files use the same versioned `Dictionary` pipeline as save files (see [Save Files → On-disk format](#on-disk-format) above). They're written via `var_to_str`, looked up by `class_name` on load, and run through a `SettingsMigrations` chain. The only structural differences from save files are:

- Settings are always uncompressed text — the `.sav`/`.tsav` split doesn't apply, since settings are typically small and worth keeping hand-editable.
- The migration chain is a separate `SettingsMigrations` instance on `Persister.settings_migrations`, independent of `Persister.migrations`.

A `.tcfg` file looks roughly like this:

```py
{
"_class": "ExampleSettingsFile",
"version": 1,
"window_size": Vector2i(1920, 1080),
"master_volume_db": 0.0
}
```

#### Settings File Examples

First, extend the `SettingsFile` class to create a custom settings file structure for your game.

Declare export vars to store any data that should persist between gameplay sessions.

Add setters and getters to any export vars that should react to changes during runtime.

```py
    class_name ExampleSettingsFile
    extends SettingsFile

    @export var some_value: float = 0.0:
        get:
            return some_value
        set(value):
            print("Do something to the game when this value is loaded or changed!")
            some_value = value
```

Don't redeclare or initialize the inherited `version: int` field — Persister manages it for you on store, and `SettingsMigrations` manages it on load.

Next, initialize `Persister` with your extended settings file when the game starts:

```py
    Persister.settings = ExampleSettingsFile.new()
```

Finally, you may edit, store, and load data in your settings file as needed:
```py
    Persister.load_settings()
    Persister.settings.some_value = 1.0
    Persister.store_settings()
```

### Settings File Migrations

Settings files use the same migration approach as save files. The base class is `SettingsMigrations` instead of `SaveMigrations`, but the rules and shape are identical — see [Save File Migrations](#save-file-migrations) for the full discussion.

Extend `SettingsMigrations` once per project:

```py
    class_name ExampleSettingsMigrations
    extends SettingsMigrations

    const CURRENT_VERSION: int = 1

    func current_version() -> int:
        return CURRENT_VERSION

    func _step(d: Dictionary, from_version: int) -> Dictionary:
        match from_version:
            0:
                return _migrate_v0_to_v1(d)
            _:
                return super._step(d, from_version)

    # Renamed master_volume -> master_volume_db.
    func _migrate_v0_to_v1(d: Dictionary) -> Dictionary:
        d["master_volume_db"] = d.get("master_volume", 0.0)
        d.erase("master_volume")
        d["version"] = 1
        return d
```

Then tell Persister to use it, **before any load_settings or store_settings call**:

```py
    func _ready() -> void:
        Persister.settings_migrations = ExampleSettingsMigrations.new()
        # ... load settings, etc. ...
```

As with `SaveMigrations`, the default `SettingsMigrations` base class is a working no-op. For prototyping that's fine; for a shipped game you want a real subclass so old `.tcfg` files keep loading after you change the schema.

# Tests

The plugin includes a set of automated tests defined in the `tests/` folder.

To run the tests, open any of the `*_test.tscn` files within the Godot editor and choose `Run Current Scene`.

Test results will appear in the `Output` window.
