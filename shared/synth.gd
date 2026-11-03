extends Node
## Synth (autoload): procedural audio, so no game needs audio files.
##
##   Synth.sfx("coin")                       # a preset (see PRESETS)
##   Synth.sfx("hit", randf_range(0.9, 1.1)) # with pitch variation
##   Synth.tone(440.0, 0.2, "square")        # a one-off tone (cached)
##   Synth.loop([60, 0, 64, 67], 120.0)      # a simple music loop: MIDI notes, 0 = rest
##   Synth.stop_loop()
##
## Sounds are rendered once into AudioStreamWAV buffers and cached. That works on
## the web without threads (AudioStreamGenerator does not, so it isn't used).
## Browsers start audio only after the first click or key; Godot resumes the
## audio context on that first input, so nothing extra is needed here.

const MIX_RATE := 22050
const VOICES := 12
const WAVES := ["sine", "square", "saw", "triangle", "noise"]

## name -> {wave, f0 (Hz at start), f1 (Hz at end), dur (s), vol (0..1)}
const PRESETS := {
	"blip": {"wave": "square", "f0": 880.0, "f1": 880.0, "dur": 0.05, "vol": 0.25},
	"select": {"wave": "square", "f0": 660.0, "f1": 990.0, "dur": 0.08, "vol": 0.25},
	"back": {"wave": "square", "f0": 660.0, "f1": 440.0, "dur": 0.08, "vol": 0.25},
	"coin": {"wave": "square", "f0": 988.0, "f1": 1319.0, "dur": 0.12, "vol": 0.3},
	"jump": {"wave": "square", "f0": 300.0, "f1": 720.0, "dur": 0.14, "vol": 0.25},
	"shift": {"wave": "saw", "f0": 220.0, "f1": 660.0, "dur": 0.10, "vol": 0.25},
	"hit": {"wave": "noise", "f0": 1800.0, "f1": 200.0, "dur": 0.18, "vol": 0.45},
	"boom": {"wave": "noise", "f0": 600.0, "f1": 60.0, "dur": 0.45, "vol": 0.55},
	"miss": {"wave": "triangle", "f0": 330.0, "f1": 220.0, "dur": 0.16, "vol": 0.35},
	"win": {"wave": "square", "f0": 523.0, "f1": 1047.0, "dur": 0.40, "vol": 0.3},
	"lose": {"wave": "triangle", "f0": 440.0, "f1": 110.0, "dur": 0.55, "vol": 0.4},
}

var muted: bool = false

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0

var _loop_notes: Array = []
var _loop_step: int = 0
var _loop_timer: float = 0.0
var _loop_step_time: float = 0.25
var _loop_wave: String = "triangle"
var _loop_vol: float = 0.15


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	muted = bool(Save.setting("muted", false))
	AudioServer.set_bus_mute(0, muted)


func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(0, muted)
	Save.set_setting("muted", muted)


func sfx(preset: String, pitch: float = 1.0) -> void:
	if not PRESETS.has(preset):
		push_warning("Synth: unknown preset '%s'" % preset)
		return
	var p: Dictionary = PRESETS[preset]
	_play(_stream(p), pitch)


func tone(freq: float, dur: float, wave: String = "square", vol: float = 0.25, freq_end: float = -1.0) -> void:
	var p := {"wave": wave, "f0": freq, "f1": freq if freq_end < 0.0 else freq_end, "dur": dur, "vol": vol}
	_play(_stream(p), 1.0)


## Loop a note pattern (MIDI numbers, 0 = rest) at `bpm`, one note per eighth.
func loop(notes: Array, bpm: float, wave: String = "triangle", vol: float = 0.15) -> void:
	_loop_notes = notes.duplicate()
	_loop_step = 0
	_loop_timer = 0.0
	_loop_step_time = 30.0 / maxf(bpm, 1.0)
	_loop_wave = wave
	_loop_vol = vol


func stop_loop() -> void:
	_loop_notes.clear()


func _process(delta: float) -> void:
	if _loop_notes.is_empty():
		return
	_loop_timer -= delta
	while _loop_timer <= 0.0:
		_loop_timer += _loop_step_time
		var n: float = float(_loop_notes[_loop_step % _loop_notes.size()])
		_loop_step += 1
		if n > 0.0:
			tone(midi_to_hz(n), _loop_step_time * 0.9, _loop_wave, _loop_vol)


static func midi_to_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


## Render one sound to float samples in [-1, 1]. Pure: used by selftests too.
static func render(p: Dictionary) -> PackedFloat32Array:
	var wave: String = p.get("wave", "square")
	var f0: float = float(p.get("f0", 440.0))
	var f1: float = float(p.get("f1", f0))
	var dur: float = clampf(float(p.get("dur", 0.1)), 0.01, 4.0)
	var vol: float = clampf(float(p.get("vol", 0.3)), 0.0, 1.0)
	var count := int(dur * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	var held := 0.0
	var attack := 0.005 * MIX_RATE
	for i in count:
		var t := float(i) / float(count)
		var freq := lerpf(f0, f1, t)
		var prev_phase := phase
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var s := 0.0
		match wave:
			"sine":
				s = sin(phase * TAU)
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"saw":
				s = phase * 2.0 - 1.0
			"triangle":
				s = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				if phase < prev_phase or i == 0: # sample-and-hold at `freq`
					held = randf_range(-1.0, 1.0)
				s = held
		var env := pow(1.0 - t, 2.0)
		if i < attack:
			env *= float(i) / attack
		out[i] = s * env * vol
	return out


func _stream(p: Dictionary) -> AudioStreamWAV:
	var key := "%s|%.1f|%.1f|%.3f|%.2f" % [p.get("wave"), p.get("f0"), p.get("f1"), p.get("dur"), p.get("vol")]
	if _cache.has(key):
		return _cache[key]
	var samples := render(p)
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	_cache[key] = wav
	return wav


func _play(stream: AudioStream, pitch: float) -> void:
	var p := _players[_next_voice]
	_next_voice = (_next_voice + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = clampf(pitch, 0.25, 4.0)
	p.play()
