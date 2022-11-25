@tool
extends EditorSceneFormatImporter

var moz_hubs : GLTFDocumentExtension = preload("res://addons/gltf_extensions/moz_hubs_extension.gd").new()
var omi_audio : GLTFDocumentExtension = preload("res://addons/gltf_extensions/omi_audio_emitter.gd").new()
var count_faces : GLTFDocumentExtension = preload("res://addons/gltf_extensions/count_mesh_faces.gd").new()

func _get_importer_name() -> String:
	return "GLTF Extensions"


func _get_extensions() -> PackedStringArray:
	var exts : PackedStringArray = ["gltf", "glb"]
	return exts


func _get_import_flags() -> int:
	return IMPORT_SCENE


func _import_scene(path: String, flags: int, options: Dictionary, bake_fps: int) -> Object:
	var gltf : GLTFDocument = GLTFDocument.new()
	gltf.register_gltf_document_extension(moz_hubs)
	gltf.register_gltf_document_extension(omi_audio)
	gltf.register_gltf_document_extension(count_faces)
	var state : GLTFState = GLTFState.new()
	var err = gltf.append_from_file(path, state, flags, bake_fps)
	if err != OK:
		return null

	var generated_scene = gltf.generate_scene(state, bake_fps)
	return generated_scene
