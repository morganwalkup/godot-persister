# Persister

A Godot plugin for managing save files and settings files.

```py
# Extend SaveFile and SettingsFile base classes to fit your game
Persister.save = MyGameSaveFile.new()
Persister.settings = MyGameSettingsFile.new()

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

#### Persister methods

Save-file-related methods:
- load_save(path: FilePath) -> void - Finds the `.sav` or `.tsav` file stored at `path` and loads its values into the `sav` variable
- store_save(path: FilePath, saveFile: SaveFile = sav) -> void - Stores a `SaveFile` resource at the specified file path. By default, stores the value of the `sav` variable
- list_saves() -> FilePath[] - Returns a list of all `.sav` or `.tsav` files stored in `user://` and `res://`
- view_save(path: FilePath) -> SaveFile - Returns a `SaveFile` resource loaded from `path`. Does not change the value of `sav`.
- delete_save(path: FilePath) -> void - Deletes the `.sav` or `.tsav` file stored at `path`

Settings-file-related methods:
- load_settings() -> void - Finds the `user://settings.tres` file and loads its contents into `settings`
- store_settings() -> void - Stores the values from `settings` into `user://settings.tres`
- delete_settings() -> void - Deletes `settings.tres`. Does not modify the `settings` variable or any related runtime values

#### Persister signals

- before_load_save - Emitted just before a new `SaveFile` is loaded from the file system
- after_load_save - Emitted just after a new `SaveFile` is loaded from the file system, and just after the value of `Persister.sav` is updated
- before_store_save - Emitted just before `Persister.sav` is written to the file system
- after_store_save - Emitted just after `Persister.sav` is written to the file system

### Save Files

Save Files track the player's progress and achievements within the game.

They should be saved on the user's local machine, should be regularly cloud-synced between devices, and should persist between gameplay sessions.

As a game designer, you should decide how many save files your game allows, and how often save data is updated.

Persister uses a custom `SaveFile` class for storing save data.

Save data can be stored in human-readable `.tsav` files or compressed `.sav` files depending on the needs of your game.

Persister's approach to save files is heavily influenced by Godotneer's video here: https://www.youtube.com/watch?v=43BZsLZheA4&ab_channel=Godotneers

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

The following examples demonstrate how Persister might be used to recreate the save systems from several popular games.

**Pokemon Yellow**
- Number of save files: 1
- Save strategy: Manual, outside combat
- At startup, the player can select `Continue`, `New Game`, or `Options`
- `Options` are stored in `user://settings.tres`
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
- `Options` are stored in `user://settings.tres`
- `New Game` loads nothing, playing the game from the default project state
- `Master Mode` allows the player to select `user://botw_master_auto.sav` or `user://botw_master.sav`
- `Continue` allows the player to select a previous auto save or manual save such as `user://botw_auto_2.sav` or `user://botw.sav`
- While playing, progress is saved in one of five autosave slots automatically at key points, with oldest files gettings wiped out.
- The player can save their progress manually at any time through the save menu, overriding `user://botw.sav`

**Elden Ring**
- Number of save files: 1 save per character, up to five characters
- Save strategy: Autosaves constantly, no manual saves
- At startup, the player can select `Continue`, `Load Game`, `New Game`, or `System`
- `System` sets values stored in `user://settings.tres`
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

Settings data is stored in human-readable `.tres` files. By default, Persister creates a single settings file at `user://settings.tres`.

#### Settings File Examples

Compared to save files, settings files are straight-forward.

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