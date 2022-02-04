@tool
extends EditorSceneFormatImporter


func _get_importer_name() -> String:
	return "glTF2 Extensions"


func _get_extensions() -> Array:
	return ["glb", "gltf"]


func _get_import_flags() -> int:
	return IMPORT_SCENE


func _import_animation(path: String, flags: int, options: Dictionary, bake_fps: int) -> Animation:
	return Animation.new()


func _import_scene(path: String, flags: int, options: Dictionary, bake_fps: int) -> Node:
	var gltf : GLTFDocument = GLTFDocument.new()
	var moz_extension : GLTFDocumentExtension = load("res://addons/omi_gltf_extension/omi_audio_emitter.gd").new()
	moz_extension.set_import_setting("path", path)
	gltf.extensions.push_front(moz_extension)	
	var state : GLTFState = GLTFState.new()
	var root_node = gltf.append_from_file(path, state, flags, bake_fps)
	
	return gltf.generate_scene(state, bake_fps)
