@tool
extends EditorPlugin

var scene_import = load("res://addons/add_gltf_extensions/scene_format_import_gltf_extension.gd").new()

func _enter_tree():
	add_scene_format_importer_plugin(scene_import, true)

func _exit_tree():
	remove_scene_format_importer_plugin(scene_import)
	scene_import = null
