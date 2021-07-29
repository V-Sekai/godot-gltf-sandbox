@tool
extends EditorSceneImporter

# Set this to true to save a .res file with all GLTF DOM state
# This allows exploring all JSON structure and also Godot internal GLTFState
# Very useful for debugging.
const SAVE_DEBUG_GLTFSTATE_RES: bool = false


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
		var new_node = gstate.get_scene_node(index)
		if not new_node:
			continue
		if curr.has("KHR_materials_unlit"):
			if new_node.get_mesh():				
				for surface_i in new_node.get_mesh().get_surface_count():
					var mat : BaseMaterial3D = new_node.get_mesh().surface_get_material(surface_i)
					if mat:
						mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		if not curr.has("MOZ_hubs_components"):
			extended_nodes.push_back([])
			continue
		
		var hubs = curr["MOZ_hubs_components"]		
		if not hubs is Dictionary:
			continue
			
		if hubs.is_empty():
			continue
		
		var keys = hubs.keys()
		var new = Node3D.new()
		new.name = new_node.name
		for key in keys:
			if key == "visible":
				if hubs[key]["visible"] == false:
					new_node.visible = false
			elif key == "directional-light":				
				var new_light_3d : DirectionalLight3D = DirectionalLight3D.new()
				new_light_3d.name = new_node.name
				new_light_3d.transform = new_node.transform
				new_node.replace_by(new_light_3d)			
				new_node.free()
				new_node = new_light_3d
				# TODO 2021-07-28 fire: unfinished
			elif key == "shadow":
				new_node.queue_free()
			elif key == "nav-mesh":
				new_node.queue_free()
			elif key == "trimesh":
				new_node.replace_by(new)
				new_node.free()
				new_node = new
			elif key == "spawn-point":
				new_node.queue_free()
			elif key == "audio-params":
				pass
			elif key == "audio":
				var new_audio_3d = AudioStreamPlayer3D.new()
				new_audio_3d.name = new_node.name
				new_node.replace_by(new_audio_3d)
				new_node.free()
				new_node = new_audio_3d
			else:
				"%s: %s".format([key, hubs[key]])
				
		extended_nodes.push_back(curr["MOZ_hubs_components"])
	
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
