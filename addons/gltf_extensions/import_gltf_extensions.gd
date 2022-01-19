@tool
extends EditorSceneFormatImporter

# Set this to true to save a .res file with all GLTF DOM state
# This allows exploring all JSON structure and also Godot internal GLTFState
# Very useful for debugging.
const SAVE_DEBUG_GLTFSTATE_RES: bool = false


func _get_extensions():
	return ["gltf", "glb"]


func _get_import_flags():
	return EditorSceneFormatImporter.IMPORT_SCENE


func _import_animation(path: String, flags: int, bake_fps: int) -> Animation:
	return Animation.new()


func _import_scene(path: String, flags: int, options: Dictionary, bake_fps: int):
	var gstate : GLTFState = GLTFState.new()
	var gltf : GLTFDocument = GLTFDocument.new()
	var err = gltf.append_from_file(path, gstate)
	if err != OK:
		return null
	var root_node : Node = gltf.generate_scene(gstate)
	
	if not gstate.json.has(StringName("nodes")):
		return ERR_PARSE_ERROR
	
	var nodes = gstate.json.get("nodes")
	var extended_nodes : Array = []
	for node in nodes:
		var curr : Dictionary = {}
		var index = extended_nodes.size()
#		import_moz_hubs(gstate, path, index, root_node, nodes, node, extended_nodes, curr)
		import_omi_audio_emitter(gstate, path, index, root_node, nodes, node, extended_nodes, curr)
		
	if SAVE_DEBUG_GLTFSTATE_RES:		
		var extended = preload("res://addons/gltf_extensions/node_resource.gd").new()
		extended.nodes = extended_nodes		
		ResourceSaver.save(path.get_basename() + ".debug.tres", extended)
		ResourceSaver.save(path.get_basename() + ".res", gstate)

	# Remove references
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(root_node)
	return packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)


func import_omi_audio_emitter(gstate : GLTFState, path, index, root_node, nodes, node, extended_nodes, curr : Dictionary):	
	if not node.has("extensions"):
		extended_nodes.push_back([])
		return
	curr = node.get("extensions")
	if not curr.has("OMI_audio_emitter"):
		extended_nodes.push_back([])
		return
	extended_nodes.push_back(curr["OMI_audio_emitter"])
	var new_node_path : NodePath = root_node.get_path_to(gstate.get_scene_node(index))
	var node_3d : Node3D = root_node.get_node(new_node_path)
	
	var emitter = curr["OMI_audio_emitter"]		
	if not emitter is Dictionary:
		return
		
	if emitter.is_empty():
		return

	var keys : Array = emitter.keys()	
	print(keys)
	if keys.has("audioEmitter"):
		var src : int = emitter["audioEmitter"]				
		var new_audio_3d = AudioStreamPlayer3D.new()
		new_audio_3d.name = node_3d.name
		new_audio_3d.transform = node_3d.transform
		var json : Dictionary = gstate.json
		if not json.has("extensions"):
			return
		var ext : Dictionary = json["extensions"]
		if not ext.size():
			return
		if not ext.has("OMI_audio_emitter"):
			return
		var emitter_keys = ext["OMI_audio_emitter"].keys()
		if not emitter_keys.has("audioSources"):
			return
		var sources = ext["OMI_audio_emitter"]["audioSources"]
		var uri = sources[src]["uri"]
		var path_stream = path.get_base_dir() + "/" + uri.get_file()
		new_audio_3d.stream = load(path_stream)
		node_3d.replace_by(new_audio_3d)
		return


func import_moz_hubs(gstate, path, index, root_node, nodes, node, extended_nodes, curr):	
	if not node.has("extensions"):
		extended_nodes.push_back([])
		return
	curr = node.get("extensions")		
	extended_nodes.push_back(curr["MOZ_hubs_components"])
	var new_node_path : NodePath = root_node.get_path_to(gstate.get_scene_node(index))
	var node_3d : Node3D = root_node.get_node(new_node_path)
			
	if curr.has("KHR_materials_unlit"):
		for surface_i in node_3d.get_mesh().get_surface_count():
			var mat : BaseMaterial3D = node_3d.get_mesh().surface_get_material(surface_i)
			if mat:
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED		
	
	var mesh_node = root_node.get_node(new_node_path)
		
	if not curr.has("MOZ_hubs_components"):
		extended_nodes.push_back([])
		return
	
	var hubs = curr["MOZ_hubs_components"]		
	if not hubs is Dictionary:
		return
		
	if hubs.is_empty():
		return
	var keys : Array = hubs.keys()	
				
	if keys.has("visible"):
		if hubs["visible"]["visible"] == false:
			node_3d.visible = false		
	
	if keys.has("nav-mesh"):	
		var new_node_3d : Node3D = Node3D.new()
		new_node_3d.name = node_3d.name
		new_node_3d.transform = node_3d.transform
		node_3d.replace_by(new_node_3d)
		return
	
	if keys.has("trimesh"):
		var new_node_3d : Node3D = Node3D.new()
		new_node_3d.name = node_3d.name
		new_node_3d.transform = node_3d.transform
		node_3d.replace_by(new_node_3d)
		return
	
	if keys.has("directional-light"):				
		var new_light_3d : DirectionalLight3D = DirectionalLight3D.new()
		new_light_3d.name = node_3d.name
		new_light_3d.transform = node_3d.transform
		new_light_3d.rotate_object_local(Vector3(1.0, 0.0, 0.0), 180)
		node_3d.replace_by(new_light_3d)
		# TODO 2021-07-28 fire: unfinished
		return
	
	if keys.has("spawn-point"):		
		var new_node_3d : Node3D = Node3D.new()
		new_node_3d.name = node_3d.name
		new_node_3d.transform = node_3d.transform
		node_3d.replace_by(new_node_3d)
		return
			
	if keys.has("audio"):
		var src : String = hubs["audio"]["src"]					
		var new_audio_3d = AudioStreamPlayer3D.new()
		new_audio_3d.name = node_3d.name
		new_audio_3d.transform = node_3d.transform			
		if not src.is_empty():
			var path_stream = path.get_base_dir() + "/" + src.get_file()
			print(path_stream)
			new_audio_3d.stream = load(path_stream)
		var auto_play : bool = hubs["audio"]["autoPlay"]
		new_audio_3d.playing = auto_play
		new_audio_3d.autoplay = auto_play
		if hubs["audio"].has("volume"):
			var volume : float = hubs["audio"]["volume"]
			new_audio_3d.unit_db = linear2db(volume)
		node_3d.replace_by(new_audio_3d)
		return
			
	if keys.has("shadow"):
#			if node_3d is MeshInstance3D:
#				var cast : bool = hubs["shadow"]["cast"]				
#				var receive : bool = hubs["shadow"]["receive"]
#				if cast == false and receive == false:
#					node_3d.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_OFF
#				elif cast == true and receive == false:					
#					node_3d.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_OFF
#				elif cast == false and receive == true:					
#					node_3d.cast_shadow =  MeshInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
#				elif cast == true and receive == true:					
#					node_3d.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_ON
		return
	print(keys)
