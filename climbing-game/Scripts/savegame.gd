class_name SaveGame
extends Resource

@export var player_position: Vector3 = Vector3.ZERO
@export var player_rotation: Basis = Basis()
@export var fov: float = 75.0

const SAVE_GAME_PATH := "user://savegame.tres"

func write_savegame() -> bool:
	print("Attempting to save game data...")
	print("Position to save: ", player_position)
	print("Rotation to save: ", player_rotation)
	print("FOV to save: ", fov)  # Log FOV
	var save_result = ResourceSaver.save(self, SAVE_GAME_PATH)
	if save_result == OK:
		print("Game saved successfully!")
		return true
	else:
		print("ERROR: Failed to save game. Error code: ", save_result)
		return false

static func load_savegame() -> SaveGame:
	print("Attempting to load game data...")
	if not ResourceLoader.exists(SAVE_GAME_PATH):
		print("No save game file found!")
		return null
	var loaded_resource = load(SAVE_GAME_PATH)
	if loaded_resource is SaveGame:
		print("Successfully loaded save game!")
		print("Loaded Position: ", loaded_resource.player_position)
		print("Loaded Rotation: ", loaded_resource.player_rotation)
		print("Loaded FOV: ", loaded_resource.fov)  # Log FOV
		return loaded_resource
	else:
		print("ERROR: Loaded resource is not a valid SaveGame!")
		return null
