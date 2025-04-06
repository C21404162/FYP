extends Node

signal player_position_updated(position)
signal player_rotation_updated(rotation)
signal fov_updated(fov_value) 
signal sensitivity_updated(sensitivity_value)

var player_position: Vector3 = Vector3.ZERO
var player_rotation: Basis = Basis()
var fov: float = 90.0  
var sensitivity: float = 0.001
var speedrun_mode := false
var speedrun_time := 0.0
var speedrun_active := false
#var best_time := 0.0

func start_speedrun():
	print("speedrunmode: ", speedrun_mode)
	if speedrun_mode and not speedrun_active:
		speedrun_time = 0.0
		speedrun_active = true
		if is_instance_valid(get_tree().current_scene):
			get_tree().current_scene.update_speedrun_ui(true)

func stop_speedrun():
	if speedrun_active:
		speedrun_active = false
		#if speedrun_time < best_time or best_time == 0.0:
			#best_time = speedrun_time
		if is_instance_valid(get_tree().current_scene):
			get_tree().current_scene.update_speedrun_ui(false)

func set_speedrun_mode(enabled: bool):
	speedrun_mode = enabled
	if !speedrun_mode and speedrun_active:
		stop_speedrun()
	
	var current_scene = get_tree().current_scene
	if current_scene.has_method("update_speedrun_ui"):
		current_scene.update_speedrun_ui(enabled)

func get_formatted_time() -> String:
	var minutes := int(speedrun_time / 60)
	var seconds := fmod(speedrun_time, 60)
	return "%02d:%05.2f" % [minutes, seconds]

func update_player_position(new_position: Vector3):
	player_position = new_position
	emit_signal("player_position_updated", player_position)

func update_player_rotation(new_rotation: Basis):
	player_rotation = new_rotation
	emit_signal("player_rotation_updated", player_rotation)

func set_fov(new_fov: float):
	fov = new_fov
	emit_signal("fov_updated", fov)

func set_sensitivity(new_sensitivity: float):
	sensitivity = new_sensitivity
	emit_signal("sensitivity_updated", sensitivity)

func save_game_data():
	print("saving pos = ", player_position)
	print("saving rot = ", player_rotation)
	print("saving fov =", fov)  
	print("saving sens = ", sensitivity)
	var save_game = SaveGame.new()
	save_game.speedrun_mode = speedrun_mode
	save_game.player_position = player_position
	save_game.player_rotation = player_rotation
	save_game.fov = fov
	save_game.sensitivity = sensitivity
	if save_game.write_savegame():
		print("GAME SAVED")
	else:
		print("GAME SAVE FAILED")

func load_game_data():
	var loaded_save = SaveGame.load_savegame()
	if loaded_save:
		print("loaded pos ", loaded_save.player_position)
		print("loaded rot ", loaded_save.player_rotation)
		print("loaded fov ", loaded_save.fov) 
		print("loaded sens ", loaded_save.sensitivity)
		update_player_position(loaded_save.player_position)
		update_player_rotation(loaded_save.player_rotation)
		set_fov(loaded_save.fov) 
		set_sensitivity(loaded_save.sensitivity)
	else:
		print("GAME LOAD FAILED")
