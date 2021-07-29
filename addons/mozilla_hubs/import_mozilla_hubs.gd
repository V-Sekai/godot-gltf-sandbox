@tool
extends EditorSceneImporter

# Set this to true to save a .res file with all GLTF DOM state
# This allows exploring all JSON structure and also Godot internal GLTFState
# Very useful for debugging.
const SAVE_DEBUG_GLTFSTATE_RES: bool = true


func _get_extensions():
	return ["mozhubs"]


func _get_import_flags():
	return EditorSceneImporter.IMPORT_SCENE


func _import_animation(path: String, flags: int, bake_fps: int) -> Animation:
	return Animation.new()


func _import_scene(path: String, flags: int, bake_fps: int):
	var f = File.new()
	var new_glb = path.get_basename() + ".glb"
	if f.open(new_glb, File.READ) != OK:
		return FAILED
		
	var gstate : GLTFState = GLTFState.new()
	var gltf : PackedSceneGLTF = PackedSceneGLTF.new()
	var root_node : Node = gltf.import_gltf_scene(new_glb, 0, 1000.0, gstate)
	
	if not gstate.json.has(StringName("nodes")):
		return ERR_PARSE_ERROR
	
	var nodes = gstate.json.get("nodes")
	var extended_nodes : Array = []
	for node in nodes:
		var curr : Dictionary = {}
		var index = extended_nodes.size()
		if not node.has("extensions"):
			extended_nodes.push_back([])
			continue
		curr = node.get("extensions")
		if not curr.has("MOZ_hubs_components"):
			extended_nodes.push_back([])
			continue
		
		var hubs = curr["MOZ_hubs_components"]		
		if not hubs is Dictionary:
			continue
			
		if hubs.is_empty():
			continue;
			
		var new_node = gstate.get_scene_node(index)
		
		var keys = hubs.keys()
		var new = Node.new()
		for key in keys:
			if key == "visible":
				if hubs[key]["visible"] == false:
					new_node.replace_by(new)
					new.set_owner(root_node)
			elif key == "nav-mesh":
				new_node.replace_by(new)
				new.set_owner(root_node)
			elif key == "trimesh":
				new_node.replace_by(new)
				new.set_owner(root_node)
			elif key == "spawn-point":
				new_node.replace_by(new)
				new.set_owner(root_node)
			else:
				print(hubs[key])
				
		extended_nodes.push_back(curr["MOZ_hubs_components"])
	
	## CC-BY authors
	## Link back to hubs.mozilla.org
	#Disable merging
	#Disable optimization
	# For each sound play
	# For each collision convert
	# For each animations playing

	if SAVE_DEBUG_GLTFSTATE_RES:		
		var extended = preload("res://addons/mozilla_hubs/node_resource.gd").new()
		extended.nodes = extended_nodes		
		ResourceSaver.save(path.get_basename() + ".debug.tres", extended)
		ResourceSaver.save(path.get_basename() + ".res", gstate)

	# Remove references
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(root_node)
	return packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)


func import_animation_from_other_importer(path: String, flags: int, bake_fps: int):
	return self._import_animation(path, flags, bake_fps)


func import_scene_from_other_importer(path: String, flags: int, bake_fps: int):
	return self._import_scene(path, flags, bake_fps)
