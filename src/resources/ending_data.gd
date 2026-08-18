class_name EndingData
extends Resource

@export var ending_id: StringName
@export var display_name := "Ending"
@export var gallery_label := "END"
@export var memory_images: Array[Texture2D] = []
@export_multiline var short_subtitle := ""
@export_range(0.5, 30.0, 0.1, "or_greater") var seconds_per_image := 4.0
@export_range(0.1, 5.0, 0.1, "or_greater") var transition_duration := 1.0
@export var memory_music: AudioStream
