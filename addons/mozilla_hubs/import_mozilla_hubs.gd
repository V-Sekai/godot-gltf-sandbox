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
			continue
		
		var hubs = curr["MOZ_hubs_components"]		
		if not hubs is Dictionary:
			continue
			
		if hubs.is_empty():
			continue
		
		var keys : Array = hubs.keys()	
					
		if keys.has("visible"):
			if hubs["visible"]["visible"] == false:
				node_3d.visible = false		
		
		if keys.has("nav-mesh"):	
			var new_node_3d : Node3D = Node3D.new()
			new_node_3d.name = node_3d.name
			new_node_3d.transform = node_3d.transform
			node_3d.replace_by(new_node_3d)
			continue
		
		if keys.has("trimesh"):
			var new_node_3d : Node3D = Node3D.new()
			new_node_3d.name = node_3d.name
			new_node_3d.transform = node_3d.transform
			node_3d.replace_by(new_node_3d)
			continue
		
		if keys.has("directional-light"):				
			var new_light_3d : DirectionalLight3D = DirectionalLight3D.new()
			new_light_3d.name = node_3d.name
			new_light_3d.transform = node_3d.transform
			new_light_3d.rotate_object_local(Vector3(1.0, 0.0, 0.0), 180)
			node_3d.replace_by(new_light_3d)
			# TODO 2021-07-28 fire: unfinished
			continue
		
		if keys.has("spawn-point"):		
			var new_node_3d : Node3D = Node3D.new()
			new_node_3d.name = node_3d.name
			new_node_3d.transform = node_3d.transform
			node_3d.replace_by(new_node_3d)
			continue
				
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
			continue
				
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
			continue
		print(keys)
			
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
