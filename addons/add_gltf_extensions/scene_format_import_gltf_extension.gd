@tool
extends EditorSceneFormatImporter

var omi_ext : GDScript = preload("res://addons/add_gltf_extensions/omi_audio_emitter.gd")
var hubs_ext : GDScript = preload("res://addons/add_gltf_extensions/moz_hubs_extension.gd")

func _import_scene(path, flags, options, bake_fps):
	print("Import scene gltf extensions.")
	var gltf_document : GLTFDocument = GLTFDocument.new()
	var extensions : Array[GLTFDocumentExtension]
	extensions.push_back(omi_ext.new())
	extensions.push_back(hubs_ext.new())
	gltf_document.extensions = extensions
	var gltf_state : GLTFState = GLTFState.new()
	flags = IMPORT_USE_NAMED_SKIN_BINDS
	var err = gltf_document.append_from_file(path, gltf_state, flags, bake_fps, path.get_base_dir())
	if err != OK:
		push_error("EditorSceneFormatImporter _import_scene.")
		return null
	var root = gltf_document.generate_scene(gltf_state, bake_fps)
	return root

func _get_extensions() -> PackedStringArray:
	var exts : PackedStringArray = ["gltf", "glb"]
	return exts
