extends Node
## Sound effects synthesised at startup (no audio assets needed).
## Swap in recorded samples later by putting AudioStreams into _streams.

const RATE := 22050
const POOL := 8

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_streams["deal"] = _swish(0.11, 0.35)
	_streams["place"] = _thump()
	_streams["flip"] = _swish(0.06, 0.22)
	_streams["click"] = _tone([880.0], 0.05, 0.25, 30.0)
	_streams["nope"] = _tone([180.0, 150.0], 0.16, 0.35, 12.0)
	_streams["trump"] = _bell()
	_streams["trick"] = _tone([660.0, 990.0], 0.18, 0.18, 14.0)
	_streams["collect"] = _arpeggio([523.25, 659.25, 783.99], 0.07, 0.3)
	_streams["win"] = _arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.11, 0.35)
	_streams["lose"] = _arpeggio([392.0, 329.63, 261.63, 196.0], 0.16, 0.3)
	_streams["shuffle"] = _riffle()


## Play a named effect with slight random pitch for a natural feel.
func play(name: String, pitch_jitter := 0.06, volume_db := 0.0) -> void:
	if not Settings.sound_on or not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = _streams[name]
	p.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db
	p.play()


func set_enabled(on: bool) -> void:
	Settings.sound_on = on
	Settings.save_settings()


# --- synthesis helpers -------------------------------------------------------

func _make(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


## Filtered noise burst: card sliding across felt.
func _swish(length: float, amp: float) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var prev := 0.0
	for i in n:
		var t := float(i) / n
		var env := sin(PI * pow(t, 0.6)) * (1.0 - t)
		var white := _rng.randf_range(-1.0, 1.0)
		lp += (white - lp) * (0.25 + 0.5 * t)
		var hp := lp - prev
		prev = lp
		out[i] = (hp * 1.6 + lp * 0.4) * env * amp * 2.0
	return _make(out)


## Low thump with a papery click: card landing on the table.
func _thump() -> AudioStreamWAV:
	var n := int(0.09 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 55.0)
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.35
		out[i] = (sin(TAU * 140.0 * t) * 0.55 + lp * 0.6) * env * 0.6
	return _make(out)


func _tone(freqs: Array, length: float, amp: float, decay: float) -> AudioStreamWAV:
	var n := int(length * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var seg := n / freqs.size()
	for i in n:
		var t := float(i) / RATE
		var f: float = freqs[mini(i / maxi(seg, 1), freqs.size() - 1)]
		var env := exp(-t * decay) * minf(1.0, float(i) / 60.0)
		out[i] = (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * env * amp
	return _make(out)


func _bell() -> AudioStreamWAV:
	var n := int(0.9 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 4.5) * minf(1.0, float(i) / 80.0)
		var v := sin(TAU * 880.0 * t) * 0.5 + sin(TAU * 1320.0 * t) * 0.25 + sin(TAU * 2211.0 * t) * 0.12 * exp(-t * 9.0)
		out[i] = v * env * 0.45
	return _make(out)


func _arpeggio(freqs: Array, step: float, amp: float) -> AudioStreamWAV:
	var total := step * freqs.size() + 0.5
	var n := int(total * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in freqs.size():
		var start := int(k * step * RATE)
		var f: float = freqs[k]
		for i in range(start, n):
			var t := float(i - start) / RATE
			var env := exp(-t * 5.0) * minf(1.0, float(i - start) / 60.0)
			out[i] += (sin(TAU * f * t) * 0.6 + sin(TAU * f * 2.0 * t) * 0.2 + sin(TAU * f * 3.0 * t) * 0.08) * env * amp
	return _make(out)


func _riffle() -> AudioStreamWAV:
	var n := int(0.55 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var next_tick := 0
	var tick_env := 0.0
	for i in n:
		if i >= next_tick:
			tick_env = 1.0
			next_tick = i + int(_rng.randf_range(0.008, 0.02) * RATE)
		tick_env *= 0.93
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.5
		var t := float(i) / n
		out[i] = lp * tick_env * 0.5 * sin(PI * t)
	return _make(out)
