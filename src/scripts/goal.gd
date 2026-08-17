extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		GameTimeManager.stop_run()
		Global.pending_ending = EndingManager.trigger_ending()
		get_tree().change_scene_to_file("res://src/scenes/ending_scene.tscn")
