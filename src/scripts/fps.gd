extends Label

func _ready() -> void:
	visible = OS.has_feature("editor")
	set_process(visible)

func _process(_delta: float) -> void:
	text = "FPS: %d" % Engine.get_frames_per_second()
