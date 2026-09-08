@tool
extends EditorPlugin

const GENERATOR := preload("res://src/editor/generate_test_stage_01.gd")


func _enter_tree() -> void:
	add_tool_menu_item("Generate TestStage01", _generate)
	if OS.has_environment("GENERATE_TEST_STAGE_01"):
		call_deferred("_generate_and_quit")


func _exit_tree() -> void:
	remove_tool_menu_item("Generate TestStage01")


func _generate() -> void:
	GENERATOR.new()._run()
	get_editor_interface().get_resource_filesystem().scan()


func _generate_and_quit() -> void:
	_generate()
	await get_tree().process_frame
	get_tree().quit()
