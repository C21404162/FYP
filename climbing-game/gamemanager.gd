extends Node

signal player_position_updated(position)
signal player_rotation_updated(rotation)
signal fov_updated(fov_value)  # Signal for FOV changes

var player_position: Vector3 = Vector3.ZERO
var player_rotation: Basis = Basis()
var fov: float = 90.0  # Default FOV value

func update_player_position(new_position: Vector3):
	player_position = new_position
	emit_signal("player_position_updated", player_position)

func update_player_rotation(new_rotation: Basis):
	player_rotation = new_rotation
	emit_signal("player_rotation_updated", player_rotation)

func set_fov(new_fov: float):
	fov = new_fov
	emit_signal("fov_updated", fov)  # Notify listeners of FOV change

func save_game_data():
	print("Saving game data... Player position: ", player_position)
	print("Saving game data... Player rotation: ", player_rotation)
	print("Saving game data... FOV: ", fov)  # Log FOV
	var save_game = SaveGame.new()
	save_game.player_position = player_position
	save_game.player_rotation = player_rotation
	save_game.fov = fov  # Save FOV
	if save_game.write_savegame():
		print("Game saved successfully!")
	else:
		print("Failed to save game.")

func load_game_data():
	print("Attempting to load game data...")
	var loaded_save = SaveGame.load_savegame()
	if loaded_save:
		print("Loaded player position: ", loaded_save.player_position)
		print("Loaded player rotation: ", loaded_save.player_rotation)
		print("Loaded FOV: ", loaded_save.fov)  # Log FOV
		update_player_position(loaded_save.player_position)
		update_player_rotation(loaded_save.player_rotation)
		set_fov(loaded_save.fov)  # Load FOV
	else:
		print("Failed to load game data.")
