extends Node

var total_seconds := 0.0
var running := false
var pause_reasons: Array[StringName] = []

func _ready() -> void:
	total_seconds = float(SaveManager.current_data.get("play_time", 0.0))

func _process(delta: float) -> void:
	if running and pause_reasons.is_empty() and not get_tree().paused: total_seconds += delta

func get_total_seconds() -> float: return total_seconds
func get_formatted_time() -> String:
	var seconds := int(total_seconds)
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds % 3600) / 60, seconds % 60]
func reset_timer() -> void: total_seconds = 0.0
func start_run() -> void: running = true
func stop_run() -> void: running = false
func pause_timer(reason: StringName = &"manual") -> void:
	if not pause_reasons.has(reason): pause_reasons.append(reason)
func resume_timer(reason: StringName = &"manual") -> void: pause_reasons.erase(reason)
func set_play_time(seconds: float) -> void:
	if OS.is_debug_build(): total_seconds = maxf(seconds, 0.0)
