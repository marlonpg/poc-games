extends Node
class_name SaveManager

const SAVE_PATH := "user://save.cfg"

static func load_stats() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	var best_distance := 0.0
	var best_time := 0.0
	if err == OK:
		best_distance = float(cfg.get_value("stats", "best_distance", 0.0))
		best_time = float(cfg.get_value("stats", "best_time", 0.0))
	return {
		"best_distance": best_distance,
		"best_time": best_time,
	}

static func save_stats(best_distance: float, best_time: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("stats", "best_distance", best_distance)
	cfg.set_value("stats", "best_time", best_time)
	cfg.save(SAVE_PATH)

static func load_settings() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	var audio_enabled := true
	var sfx_enabled := true
	if err == OK:
		audio_enabled = bool(cfg.get_value("settings", "audio_enabled", true))
		sfx_enabled = bool(cfg.get_value("settings", "sfx_enabled", true))
	return {
		"audio_enabled": audio_enabled,
		"sfx_enabled": sfx_enabled,
	}

static func save_settings(audio_enabled: bool, sfx_enabled: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("settings", "audio_enabled", audio_enabled)
	cfg.set_value("settings", "sfx_enabled", sfx_enabled)
	cfg.save(SAVE_PATH)
