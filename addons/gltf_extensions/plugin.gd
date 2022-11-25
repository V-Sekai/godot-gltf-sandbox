@tool
extends EditorPlugin

const gltf_extension_const = preload("res://addons/gltf_extensions/gltf_extensions.gd")

var import_plugin

func _enter_tree():
	import_plugin = gltf_extension_const.new()
	add_scene_format_importer_plugin(import_plugin, true)


func _exit_tree():
	remove_scene_format_importer_plugin(import_plugin)
	import_plugin = null
