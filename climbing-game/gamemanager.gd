extends Node
signal player_position_updated(position)

var player_position: Vector3 = Vector3.ZERO

# In GameManager.gd
func update_player_position(new_position: Vector3):
	print("Updating player position: ", new_position)
	player_position = new_position
	emit_signal("player_position_updated", player_position)

func save_game_data():
	print("Saving game data... Player position: ", player_position)
	var save_game = SaveGame.new()
	save_game.player_position = player_position
	if save_game.write_savegame():
		print("Game saved successfully!")
	else:
		print("Failed to save game.")

func load_game_data():
	print("Attempting to load game data...")
	var loaded_save = SaveGame.load_savegame()
	if loaded_save:
		print("Loaded player position: ", loaded_save.player_position)
		update_player_position(loaded_save.player_position)
	else:
		print("Failed to load game data.")
