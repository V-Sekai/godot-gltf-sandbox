@tool
extends EditorPlugin

var scene_import = null

func _enter_tree():
	scene_import = EditorSceneFormatImporterGLTF.new()	
	var omi_ext : GLTFDocumentExtension = load("res://addons/add_gltf_extensions/omi_audio_emitter.gd").new()
	scene_import.gltf_extensions.push_back(omi_ext)
	var hubs_ext : GLTFDocumentExtension = load("res://addons/add_gltf_extensions/moz_hubs_extension.gd").new()
	scene_import.gltf_extensions.push_back(hubs_ext)
	add_scene_format_importer_plugin(scene_import, true)

func _exit_tree():
	remove_scene_format_importer_plugin(scene_import)
	scene_import = null
