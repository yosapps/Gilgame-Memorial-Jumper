class_name CreditsData
extends Resource

@export var title := "GILGAME'S MEMORY JUMPER"
@export var sections: Array[CreditSection] = []
@export var closing_lines: PackedStringArray = ["Made with Godot Engine", "Thank You For Playing", "ギルガメのメモリージャンパー"]
@export_range(10.0, 300.0, 1.0) var scroll_speed := 48.0
@export var starting_offset := 100.0
@export var ending_offset := -120.0
@export_range(0.2, 10.0, 0.1) var background_image_seconds := 4.5
@export_range(0.1, 5.0, 0.1) var background_crossfade_duration := 1.5
@export_range(12, 96, 1) var font_size := 25
@export_range(16, 128, 1) var title_font_size := 42
@export var credits_music: AudioStream

