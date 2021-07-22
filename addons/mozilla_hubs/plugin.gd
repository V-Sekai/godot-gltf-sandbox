@tool
extends EditorPlugin

var import_plugin

func _enter_tree():
	import_plugin = preload("res://addons/mozilla_hubs/import_mozilla_hubs.gd").new()
	add_scene_import_plugin(import_plugin)


func _exit_tree():
	remove_scene_import_plugin(import_plugin)
	import_plugin = null
