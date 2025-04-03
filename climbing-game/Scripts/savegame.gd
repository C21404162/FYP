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
	print("Pos to save: ", player_position)
	print("Rot to save: ", player_rotation)
	print("fov to save: ", fov) 
	print("Sens to savbe: ", sensitivity)
	var save_result = ResourceSaver.save(self, SAVE_GAME_PATH)
	if save_result == OK:
		print("GAME SAVE SUCCESSFUL")
		return true
	else:
		print("ERROR SAVING")
		return false

static func load_savegame() -> SaveGame:
	if not ResourceLoader.exists(SAVE_GAME_PATH):
		print("NO FILE FOUND TO SAVE")
		return null
	var loaded_resource = load(SAVE_GAME_PATH)
	if loaded_resource is SaveGame:
		print("LOADED GAME SUCCESSFUL")
		print("Loaded pos: ", loaded_resource.player_position)
		print("Loaded rot: ", loaded_resource.player_rotation)
		print("Loaded fov: ", loaded_resource.fov)
		print("Loaded sens: ", loaded_resource.sensitivity)
		return loaded_resource
	else:
		print("ERROR LOADING")
		return null
