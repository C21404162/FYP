class_name SaveGame
extends Resource

@export var player_position: Vector3 = Vector3.ZERO
@export var player_rotation: Basis = Basis()
@export var fov = 75.0
@export var sensitivity = 0.001
@export var speedrun_mode: bool = false
@export var best_time: float = 0.0

const SAVE_GAME_PATH := "user://savegame.tres"

func write_savegame() -> bool:
	print("Attempting to save game data...")
	print("Saving speedrun mode: ", speedrun_mode, " best time: ", best_time)
	print("Position to save: ", player_position)
	print("Rotation to save: ", player_rotation)
	print("FOV to save: ", fov) 
	print("Sensitivity to save: ", sensitivity)
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
		print("Loaded FOV: ", loaded_resource.fov)
		print("Loaded Sensitivity: ", loaded_resource.sensitivity)
		return loaded_resource
	else:
		print("ERROR: Loaded resource is not a valid SaveGame!")
		return null
