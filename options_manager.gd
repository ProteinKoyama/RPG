extends Node

const CONFIG_PATH := "user://options.cfg"
const SECTION_AUDIO := "audio"
const DEFAULT_VOLUME := 80

var master_volume := DEFAULT_VOLUME
var bgm_volume := DEFAULT_VOLUME
var se_volume := DEFAULT_VOLUME

func _ready() -> void:
	_ensure_audio_buses()
	load_options()
	apply_audio_settings()

func set_master_volume(value: int) -> void:
	master_volume = clampi(value, 0, 100)
	apply_audio_settings()
	save_options()

func set_bgm_volume(value: int) -> void:
	bgm_volume = clampi(value, 0, 100)
	apply_audio_settings()
	save_options()

func set_se_volume(value: int) -> void:
	se_volume = clampi(value, 0, 100)
	apply_audio_settings()
	save_options()

func apply_audio_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("BGM", bgm_volume)
	_set_bus_volume("SE", se_volume)

func load_options() -> void:
	var config := ConfigFile.new()
	var error = config.load(CONFIG_PATH)
	if error != OK:
		return
	master_volume = int(config.get_value(SECTION_AUDIO, "master_volume", DEFAULT_VOLUME))
	bgm_volume = int(config.get_value(SECTION_AUDIO, "bgm_volume", DEFAULT_VOLUME))
	se_volume = int(config.get_value(SECTION_AUDIO, "se_volume", DEFAULT_VOLUME))

func save_options() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION_AUDIO, "master_volume", master_volume)
	config.set_value(SECTION_AUDIO, "bgm_volume", bgm_volume)
	config.set_value(SECTION_AUDIO, "se_volume", se_volume)
	config.save(CONFIG_PATH)

func _ensure_audio_buses() -> void:
	_ensure_audio_bus("BGM")
	_ensure_audio_bus("SE")

func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus(AudioServer.get_bus_count())
	var index = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")

func _set_bus_volume(bus_name: String, value: int) -> void:
	var index = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var volume = clampi(value, 0, 100)
	AudioServer.set_bus_mute(index, volume <= 0)
	AudioServer.set_bus_volume_db(index, _percent_to_db(volume))

func _percent_to_db(value: int) -> float:
	if value <= 0:
		return -80.0
	return linear_to_db(float(value) / 100.0)
