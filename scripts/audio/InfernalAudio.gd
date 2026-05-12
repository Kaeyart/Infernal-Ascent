extends Node

class_name InfernalAudio

## V32 — Audio Pass V1.
## Procedural demo audio manager. This avoids external assets for now while still
## giving every major action a readable sound hook. Later art/audio passes can
## replace these generated streams with authored WAV/OGG assets without changing
## gameplay scripts.

@export var sfx_enabled: bool = true
@export var music_enabled: bool = true
@export var master_sfx_volume_db: float = -7.5
@export var master_music_volume_db: float = -17.5
@export var max_simultaneous_sfx: int = 12
@export var mix_rate: int = 22050

var _sfx_cache: Dictionary = {}
var _loop_cache: Dictionary = {}
var _active_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null
var _music_context: String = ""

static func play_event_from_node(source_node: Node, event_name: String, world_position: Vector2 = Vector2.ZERO) -> void:
	if source_node == null or not is_instance_valid(source_node):
		return
	var tree: SceneTree = source_node.get_tree()
	if tree == null:
		return
	var audio_node: Node = InfernalAudio._get_or_create_audio_node(tree)
	if audio_node != null and audio_node.has_method("play_event"):
		audio_node.call("play_event", event_name, world_position)

static func set_context_from_node(source_node: Node, context_name: String) -> void:
	if source_node == null or not is_instance_valid(source_node):
		return
	var tree: SceneTree = source_node.get_tree()
	if tree == null:
		return
	var audio_node: Node = InfernalAudio._get_or_create_audio_node(tree)
	if audio_node != null and audio_node.has_method("set_music_context"):
		audio_node.call("set_music_context", context_name)

static func _get_or_create_audio_node(tree: SceneTree) -> Node:
	var root: Node = tree.root
	if root == null:
		return null
	var existing: Node = root.get_node_or_null("InfernalAudio")
	if existing != null:
		return existing
	var script_resource: Script = load("res://scripts/audio/InfernalAudio.gd")
	if script_resource == null:
		return null
	var audio_node: Node = script_resource.new()
	audio_node.name = "InfernalAudio"
	root.add_child(audio_node)
	return audio_node

func _ready() -> void:
	_ensure_music_player()

func play_event(event_name: String, _world_position: Vector2 = Vector2.ZERO) -> void:
	if not sfx_enabled:
		return
	var clean_name: String = event_name.strip_edges()
	if clean_name == "":
		return
	_cleanup_finished_players()
	if _active_players.size() >= max_simultaneous_sfx:
		var oldest: AudioStreamPlayer = _active_players.pop_front()
		if oldest != null and is_instance_valid(oldest):
			oldest.queue_free()
	var stream: AudioStreamWAV = _get_sfx_stream(clean_name)
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = "SFX_" + clean_name
	player.stream = stream
	player.volume_db = master_sfx_volume_db + _event_volume_offset(clean_name)
	player.pitch_scale = _event_pitch(clean_name)
	add_child(player)
	_active_players.append(player)
	player.finished.connect(Callable(self, "_on_sfx_finished").bind(player))
	player.play()

func set_music_context(context_name: String) -> void:
	if not music_enabled:
		_stop_music()
		return
	var clean_context: String = context_name.strip_edges()
	if clean_context == "":
		clean_context = "silence"
	if clean_context == _music_context:
		return
	_music_context = clean_context
	if clean_context == "silence":
		_stop_music()
		return
	_ensure_music_player()
	var stream: AudioStreamWAV = _get_loop_stream(clean_context)
	if stream == null or _music_player == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = master_music_volume_db + _context_volume_offset(clean_context)
	_music_player.pitch_scale = _context_pitch(clean_context)
	_music_player.play()

func _ensure_music_player() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "InfernalMusicLoop"
	add_child(_music_player)

func _stop_music() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stop()
	_music_context = ""

func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	_active_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()

func _cleanup_finished_players() -> void:
	for i: int in range(_active_players.size() - 1, -1, -1):
		var p: AudioStreamPlayer = _active_players[i]
		if p == null or not is_instance_valid(p):
			_active_players.remove_at(i)

func _get_sfx_stream(event_name: String) -> AudioStreamWAV:
	if _sfx_cache.has(event_name):
		return _sfx_cache[event_name] as AudioStreamWAV
	var stream: AudioStreamWAV = _build_sfx_stream(event_name)
	_sfx_cache[event_name] = stream
	return stream

func _get_loop_stream(context_name: String) -> AudioStreamWAV:
	if _loop_cache.has(context_name):
		return _loop_cache[context_name] as AudioStreamWAV
	var stream: AudioStreamWAV = _build_loop_stream(context_name)
	_loop_cache[context_name] = stream
	return stream

func _build_sfx_stream(event_name: String) -> AudioStreamWAV:
	var duration: float = _event_duration(event_name)
	var samples: int = maxi(1, int(float(mix_rate) * duration))
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)
	for i: int in range(samples):
		var t: float = float(i) / float(mix_rate)
		var u: float = float(i) / float(maxi(1, samples - 1))
		var value: float = _sample_sfx(event_name, t, u)
		var sample_value: int = int(clampf(value, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_value)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream

func _build_loop_stream(context_name: String) -> AudioStreamWAV:
	var duration: float = 3.0
	if context_name == "combat":
		duration = 2.25
	elif context_name == "boss":
		duration = 2.00
	elif context_name == "hub":
		duration = 3.80
	var samples: int = maxi(1, int(float(mix_rate) * duration))
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)
	for i: int in range(samples):
		var t: float = float(i) / float(mix_rate)
		var u: float = float(i) / float(maxi(1, samples - 1))
		var value: float = _sample_loop(context_name, t, u)
		var sample_value: int = int(clampf(value, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_value)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = 1 # LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream

func _sample_sfx(event_name: String, t: float, u: float) -> float:
	var env: float = _env_percussive(u)
	var noise: float = _noise(t * 971.0 + float(event_name.hash() % 999))
	match event_name:
		"player_light_attack":
			return _sine(520.0 + 360.0 * u, t) * env * 0.40 + noise * env * 0.08
		"player_heavy_attack":
			return _sine(180.0 + 180.0 * u, t) * env * 0.48 + noise * env * 0.14
		"player_dash":
			return _sine(340.0 + 760.0 * u, t) * _env_fast(u) * 0.36 + noise * _env_fast(u) * 0.10
		"player_hit":
			return _sine(130.0, t) * env * 0.36 + noise * env * 0.20
		"player_death":
			return _sine(160.0 - 70.0 * u, t) * _env_slow(u) * 0.42 + noise * _env_slow(u) * 0.12
		"player_respawn":
			return _sine(220.0 + 440.0 * u, t) * _env_slow(u) * 0.34 + noise * _env_slow(u) * 0.08
		"enemy_hit", "boss_hit", "player_light_hit", "player_heavy_hit":
			return _sine(210.0, t) * env * 0.32 + noise * env * 0.18
		"enemy_death":
			return _sine(190.0 - 85.0 * u, t) * _env_slow(u) * 0.38 + noise * _env_slow(u) * 0.16
		"enemy_spawn":
			return _sine(95.0 + 180.0 * u, t) * _env_slow(u) * 0.22 + noise * _env_slow(u) * 0.08
		"enemy_attack_warning", "hazard_warning":
			return _sine(440.0 + 70.0 * sin(t * 18.0), t) * _env_slow(u) * 0.24
		"enemy_attack_active", "hazard_active", "boss_attack":
			return _sine(120.0, t) * env * 0.40 + noise * env * 0.25
		"projectile_fire":
			return _sine(620.0 + 220.0 * u, t) * _env_fast(u) * 0.31 + noise * _env_fast(u) * 0.08
		"projectile_hit":
			return _sine(170.0, t) * env * 0.36 + noise * env * 0.22
		"gate_open":
			return _sine(92.0 + 66.0 * u, t) * _env_slow(u) * 0.40 + _sine(184.0, t) * _env_slow(u) * 0.18
		"reward_claim", "reliquary_purchase", "hub_ui_select":
			return _sine(420.0, t) * _env_slow(u) * 0.24 + _sine(630.0, t) * _env_slow(u) * 0.18
		"fountain_use":
			return _sine(330.0 + 170.0 * u, t) * _env_slow(u) * 0.22 + _sine(660.0, t) * _env_slow(u) * 0.10
		"forge_use", "shop_buy":
			return _sine(150.0, t) * env * 0.30 + noise * env * 0.16
		"boss_phase_changed":
			return _sine(110.0 + 85.0 * u, t) * _env_slow(u) * 0.50 + noise * _env_slow(u) * 0.10
		"boss_death":
			return _sine(150.0 - 80.0 * u, t) * _env_slow(u) * 0.55 + noise * _env_slow(u) * 0.17
		"victory_sting":
			return (_sine(392.0, t) + _sine(523.25, t) * 0.75 + _sine(659.25, t) * 0.55) * _env_slow(u) * 0.25
		"death_sting":
			return (_sine(196.0 - 65.0 * u, t) + _sine(98.0, t) * 0.85) * _env_slow(u) * 0.35 + noise * _env_slow(u) * 0.11
		_:
			return _sine(260.0, t) * env * 0.25

func _sample_loop(context_name: String, t: float, u: float) -> float:
	var fade: float = minf(1.0, minf(u * 10.0, (1.0 - u) * 10.0))
	var noise: float = _noise(t * 127.0) * 0.025
	match context_name:
		"hub":
			return ((_sine(82.0, t) * 0.12) + (_sine(123.0, t) * 0.05) + noise) * fade
		"combat":
			var pulse: float = 0.5 + 0.5 * sin(t * TAU * 1.35)
			return ((_sine(72.0, t) * 0.12) + (_sine(144.0, t) * 0.05) + noise + pulse * 0.025) * fade
		"boss":
			var boss_pulse: float = 0.5 + 0.5 * sin(t * TAU * 1.8)
			return ((_sine(55.0, t) * 0.17) + (_sine(110.0, t) * 0.08) + noise + boss_pulse * 0.035) * fade
		"victory":
			return ((_sine(196.0, t) * 0.08) + (_sine(392.0, t) * 0.05)) * fade
		"death":
			return ((_sine(65.0, t) * 0.14) + (_sine(98.0, t) * 0.05) + noise) * fade
		_:
			return 0.0

func _event_duration(event_name: String) -> float:
	match event_name:
		"player_death", "boss_death", "victory_sting", "death_sting":
			return 1.20
		"gate_open", "boss_phase_changed":
			return 0.78
		"player_respawn", "fountain_use":
			return 0.62
		"player_heavy_attack", "enemy_death", "forge_use", "shop_buy":
			return 0.34
		"hazard_warning", "enemy_attack_warning":
			return 0.42
		_:
			return 0.22

func _event_volume_offset(event_name: String) -> float:
	match event_name:
		"victory_sting", "death_sting":
			return 2.5
		"boss_death", "player_death":
			return 1.5
		"hub_ui_select":
			return -6.0
		"enemy_spawn":
			return -4.0
		"hazard_warning", "enemy_attack_warning":
			return -2.0
		_:
			return 0.0

func _context_volume_offset(context_name: String) -> float:
	match context_name:
		"boss":
			return 2.0
		"combat":
			return 0.5
		"hub":
			return -1.5
		_:
			return 0.0

func _event_pitch(event_name: String) -> float:
	# Tiny deterministic variation prevents repeated enemy hits from sounding like a single sample.
	var h: int = abs(event_name.hash() % 11)
	return 0.96 + float(h) * 0.008

func _context_pitch(_context_name: String) -> float:
	return 1.0

func _sine(freq: float, t: float) -> float:
	return sin(TAU * freq * t)

func _noise(seed_value: float) -> float:
	var raw: float = sin(seed_value * 12.9898) * 43758.5453
	return (raw - floor(raw)) * 2.0 - 1.0

func _env_fast(u: float) -> float:
	return pow(1.0 - clampf(u, 0.0, 1.0), 2.2)

func _env_percussive(u: float) -> float:
	var a: float = smoothstep(0.0, 0.04, u)
	var d: float = pow(1.0 - clampf(u, 0.0, 1.0), 2.8)
	return a * d

func _env_slow(u: float) -> float:
	var a: float = smoothstep(0.0, 0.12, u)
	var d: float = pow(1.0 - clampf(u, 0.0, 1.0), 1.25)
	return a * d
