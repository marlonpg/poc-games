extends Node
class_name AudioManager

@export var engine_volume_db := -8.0
@export var sfx_volume_db := -8.0

var _engine_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _engine_playback: AudioStreamGeneratorPlayback
var _engine_phase := 0.0
var _engine_ratio := 0.0
var _sample_rate := 44100.0
var _audio_enabled := true
var _sfx_enabled := true

func _ready() -> void:
	_engine_player = AudioStreamPlayer.new()
	var engine_stream := AudioStreamGenerator.new()
	engine_stream.mix_rate = _sample_rate
	engine_stream.buffer_length = 0.2
	_engine_player.stream = engine_stream
	_engine_player.volume_db = engine_volume_db
	add_child(_engine_player)
	_engine_player.play()
	_engine_playback = _engine_player.get_stream_playback()

	_sfx_player = AudioStreamPlayer.new()
	var sfx_stream := AudioStreamGenerator.new()
	sfx_stream.mix_rate = _sample_rate
	sfx_stream.buffer_length = 0.2
	_sfx_player.stream = sfx_stream
	_sfx_player.volume_db = sfx_volume_db
	add_child(_sfx_player)

func _process(delta: float) -> void:
	if not _audio_enabled:
		return
	if _engine_playback == null:
		return
	var target_freq: float = lerp(120.0, 420.0, _engine_ratio)
	var frame_count: int = _engine_playback.get_frames_available()
	for i in range(frame_count):
		var v: float = sin(_engine_phase) * 0.12
		_engine_playback.push_frame(Vector2(v, v))
		_engine_phase += TAU * target_freq / _sample_rate

func set_engine_speed(speed: float, max_speed: float) -> void:
	_engine_ratio = clamp(speed / max_speed, 0.0, 1.0)

func set_audio_enabled(enabled: bool) -> void:
	_audio_enabled = enabled
	_engine_player.volume_db = engine_volume_db if enabled else -80.0
	_sfx_player.volume_db = sfx_volume_db if enabled and _sfx_enabled else -80.0

func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	_sfx_player.volume_db = sfx_volume_db if enabled and _audio_enabled else -80.0

func play_screech() -> void:
	if not _audio_enabled or not _sfx_enabled:
		return
	_play_noise(0.15, 0.18)

func play_collision() -> void:
	if not _audio_enabled or not _sfx_enabled:
		return
	_play_noise(0.08, 0.3)

func play_pickup() -> void:
	if not _audio_enabled or not _sfx_enabled:
		return
	_play_noise(0.07, 0.12)

func _play_noise(duration_sec: float, amplitude: float) -> void:
	_sfx_player.play()
	var playback: AudioStreamGeneratorPlayback = _sfx_player.get_stream_playback()
	if playback == null:
		return
	var frames: int = int(duration_sec * _sample_rate)
	for i in range(frames):
		var v: float = randf_range(-amplitude, amplitude)
		playback.push_frame(Vector2(v, v))
