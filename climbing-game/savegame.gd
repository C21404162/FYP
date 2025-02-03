extends Resource
class_name SaveGame

# Explicitly typed vector for position
@export var player_position: Vector3 = Vector3.ZERO

const SAVE_GAME_PATH := "user://savegame.tres"

func write_savegame() -> bool:
	# More robust saving with error checking
	print("Attempting to save game data...")
	print("Position to save: ", player_position)
	
	var save_result = ResourceSaver.save(self, SAVE_GAME_PATH)
	
	if save_result == OK:
		print("Game saved successfully!")
		return true
	else:
		print("ERROR: Failed to save game. Error code: ", save_result)
		return false

static func load_savegame() -> SaveGame:
	# More detailed load process
	print("Attempting to load game data...")
	
	if not ResourceLoader.exists(SAVE_GAME_PATH):
		print("No save game file found!")
		return null
	
	var loaded_resource = load(SAVE_GAME_PATH)
	
	if loaded_resource is SaveGame:
		print("Successfully loaded save game!")
		print("Loaded Position: ", loaded_resource.player_position)
		return loaded_resource
	else:
		print("ERROR: Loaded resource is not a valid SaveGame!")
		return null
