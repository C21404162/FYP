extends Resource
class_name SaveGame

@export var global_position: Vector3 = Vector3.ZERO

const SAVE_GAME_PATH := "user://savegame.tres"

func write_savegame() -> void:
	ResourceSaver.save(self, SAVE_GAME_PATH)

static func load_savegame() -> Resource:
	if ResourceLoader.exists(SAVE_GAME_PATH):
		return load(SAVE_GAME_PATH)
	return null
