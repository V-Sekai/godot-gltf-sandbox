@tool
extends EditorSceneImporter

# Set this to true to save a .res file with all GLTF DOM state
# This allows exploring all JSON structure and also Godot internal GLTFState
# Very useful for debugging.
const SAVE_DEBUG_GLTFSTATE_RES: bool = true


func _get_extensions():
	return ["glb"]


func _get_import_flags():
	return EditorSceneImporter.IMPORT_SCENE


func _import_animation(path: String, flags: int, bake_fps: int) -> Animation:
	return Animation.new()


func _import_scene(path: String, flags: int, bake_fps: int):
	print("Importing Mozilla Hubs")
	var f = File.new()
	if f.open(path, File.READ) != OK:
		return FAILED

	var magic = f.get_32()
	if magic != 0x46546C67:
		return ERR_FILE_UNRECOGNIZED
	var version = f.get_32() # version
	var full_length = f.get_32() # length

	var chunk_length = f.get_32();
	var chunk_type = f.get_32();

	if chunk_type != 0x4E4F534A:
		return ERR_PARSE_ERROR
	var orig_json_utf8 : PackedByteArray = f.get_buffer(chunk_length)
	var rest_data : PackedByteArray = f.get_buffer(full_length - chunk_length - 20)
	if (f.get_length() != full_length):
		push_error("Incorrect full_length in " + str(path))

	f.close()
	var gltf_json_parsed_result = JSON.new()
	
	if gltf_json_parsed_result.parse(orig_json_utf8.get_string_from_utf8()) != OK:
		push_error("Failed to parse JSON part of glTF file in " + str(path) + ":" + str(gltf_json_parsed_result.error_line) + ": " + gltf_json_parsed_result.error_string)
		return ERR_FILE_UNRECOGNIZED
	var gltf_json_parsed: Dictionary = gltf_json_parsed_result.get_data()

	var json_utf8: PackedByteArray = gltf_json_parsed_result.stringify(gltf_json_parsed, "", true, true).to_utf8_buffer()

	f = File.new()
	var tmp_path = path + ".tmp"
	if f.open(tmp_path, File.WRITE) != OK:
		return FAILED
	f.store_32(magic)
	f.store_32(version)
	f.store_32(full_length + len(json_utf8) - len(orig_json_utf8))
	f.store_32(len(json_utf8))
	f.store_32(chunk_type)
	f.store_buffer(json_utf8)
	f.store_buffer(rest_data)
	f.flush()
	f.close()

	var gstate : GLTFState = GLTFState.new()
	
#   TODO test if has mozilla hubs extension
#	var gltf_json : Dictionary = gstate.json
#	if not moz hub extension found:
#		push_error("Failed to find required VRM keys in " + str(path))
#		return ERR_FILE_UNRECOGNIZED

	var gltf : PackedSceneGLTF = PackedSceneGLTF.new()
	print(path);
	var root_node : Node = gltf.import_gltf_scene(tmp_path, 0, 1000.0, gstate)
	root_node.name = path.get_basename().get_file()
	var d: Directory = Directory.new()
	d.open("res://")
	d.remove(tmp_path)

	if SAVE_DEBUG_GLTFSTATE_RES:
		if (!ResourceLoader.exists(path + ".res")):
			ResourceSaver.save(path + ".res", gstate)


	# Remove references
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(root_node)
	return packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)


func import_animation_from_other_importer(path: String, flags: int, bake_fps: int):
	return self._import_animation(path, flags, bake_fps)


func import_scene_from_other_importer(path: String, flags: int, bake_fps: int):
	return self._import_scene(path, flags, bake_fps)

