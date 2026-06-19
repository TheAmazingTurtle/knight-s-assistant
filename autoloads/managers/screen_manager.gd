extends Node

const SCREENS := {
	Type.ScreenName.START: preload("res://screens/start_screen/start_screen.tscn"),
	Type.ScreenName.GAME: preload("res://screens/game_screen/game_screen.tscn")
}

var cur_screen := Type.ScreenName.START
var screen_container: Node = null


func _ready() -> void:
	call_deferred("_resolve_screen_container")


func transfer_to(screen_name: Type.ScreenName) -> void:
	if screen_container == null or not is_instance_valid(screen_container):
		_resolve_screen_container()
	if screen_container == null:
		push_warning("ScreenManager could not find the main screen container.")
		return
	if cur_screen == screen_name and screen_container.get_child_count() > 0:
		return
	cur_screen = screen_name
	
	var screen_node: Node = SCREENS[screen_name].instantiate()
	
	for child in screen_container.get_children():
		screen_container.remove_child(child)
		child.queue_free()
	screen_container.add_child(screen_node)
	if screen_node is Control:
		screen_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _resolve_screen_container() -> void:
	var main_node := get_tree().current_scene
	if main_node == null:
		return
	if main_node.has_node("ScreenContainer"):
		screen_container = main_node.get_node("ScreenContainer")
	else:
		screen_container = main_node
