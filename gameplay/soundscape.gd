extends Node

var wind := AudioStreamPlayer.new()
var accent := AudioStreamPlayer.new()
var sunny := AudioStreamPlayer.new()
var ready_tone: AudioStreamWAV
var finished_tone: AudioStreamWAV
var wet := false

func _ready() -> void:
	add_child(wind)
	add_child(sunny)
	add_child(accent)
	wind.stream = _atmosphere(false)
	sunny.stream = _atmosphere(true)
	wind.volume_db = -17
	sunny.volume_db = -20
	wind.play()
	sunny.play()
	ready_tone = _melody([293.66,369.99,440.0],0.16)
	finished_tone = _melody([293.66,369.99,440.0,554.37,493.88,440.0],0.24)
	accent.volume_db = -12

func _wave(samples: PackedByteArray, rate: int, looping: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = samples
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size() / 2
	return stream

func _atmosphere(birds: bool) -> AudioStreamWAV:
	var rate := 11025
	var count := rate * 6
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7419
	var low := 0.0
	for i in range(count):
		var t := float(i) / rate
		var env := minf(1.0, minf(t, 6.0-t)*5.0)
		var sample := 0.0
		if birds:
			for at in [1.2,1.49,4.3]:
				var d := t - float(at)
				if d >= 0.0 and d < 0.15:
					sample += sin(d*(13200+21000*d))*sin(PI*d/0.15)*0.14
		else:
			low = lerpf(low,rng.randf_range(-1,1),0.09)
			sample = low * (0.72 + 0.2 * sin(t*TAU/6.0))
		data.encode_s16(i*2,roundi(23000.0*sample*env))
	return _wave(data,rate,true)

func _melody(notes: Array, beat: float) -> AudioStreamWAV:
	var rate := 16000
	var data := PackedByteArray()
	var count := ceili((notes.size()*beat+0.85)*rate)
	data.resize(count*2)
	for i in range(count):
		var t := float(i)/rate
		var mix := 0.0
		for n in notes.size():
			var d := t-n*beat
			if d >= 0 and d < 1.2:
				var phase := TAU*float(notes[n])*d
				mix += (sin(phase)+0.24*sin(2.0*phase))*minf(d*60.0,1.0)*exp(-5.5*d)*0.38
		data.encode_s16(i*2,roundi(clampf(mix,-1,1)*26500))
	return _wave(data,rate,false)

func environment(hour: float, weather: String) -> void:
	wet = weather in ["Chuva","Garoa"]
	sunny.volume_db = -50 if wet or hour < 6 or hour > 19 else -20
	wind.volume_db = -12 if wet else -17

func chime(finale := false) -> void:
	accent.stream = finished_tone if finale else ready_tone
	accent.play()
