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
	var root_node : Node = gltf.generate_scene(gstate)
	if SAVE_DEBUG_GLTFSTATE_RES:		
		var extended = preload("res://addons/gltf_extensions/node_resource.gd").new()
		ResourceSaver.save(path.get_basename() + ".debug.tres", extended)
		ResourceSaver.save(path.get_basename() + ".res", gstate)
	if err != OK:
		return null
	if not gstate.json.has(StringName("nodes")):
		return ERR_PARSE_ERROR
	var json : Dictionary = gstate.json
	var json_nodes = gstate.json.get("nodes")
	var index = 0
	for json_node in json_nodes:
		index = index + 1
		if not json_node.has("extensions"):
			continue
		var node_extensions = json_node.get("extensions")
		var gltf_root = gstate.root_nodes[0]
		var new_node_path : String = gstate.get_scene_node(gltf_root).get_path_to(gstate.get_scene_node(index))
		new_node_path = new_node_path.simplify_path()
		print(new_node_path)
		var node_3d : Node3D = root_node.get_node(new_node_path)
		if node_extensions.has("OMI_audio_emitter"):
			import_omi_audio_emitter(gstate, json, node_3d, path, index, json_nodes, node_extensions)
		if node_extensions.has("MOZ_hubs_components"):
			import_moz_hubs(gstate, json, node_3d, path, index, json_nodes, node_extensions)
		if node_extensions.has("KHR_materials_unlit"):
			import_material_unlit(gstate, json, node_3d, path, index, json_nodes, node_extensions)

	return root_node


func import_omi_audio_emitter(gstate : GLTFState, json, node_3d, path, index, json_nodes, extensions : Dictionary) -> void:	
	var omi_emitter = extensions["OMI_audio_emitter"]
	var keys : Array = omi_emitter.keys()
	if keys.has("audioEmitter"):
		var src : int = omi_emitter["audioEmitter"]
		var new_audio_3d = AudioStreamPlayer3D.new()
		new_audio_3d.name = node_3d.name
		new_audio_3d.transform = node_3d.transform

		var global_extensions : Dictionary = json["extensions"]
		if not global_extensions.size():
			return
		if not global_extensions.has("OMI_audio_emitter"):
			return
		var sources = global_extensions["OMI_audio_emitter"]["audioSources"]
		var uri = sources[src]["uri"]
		var path_stream = path.get_base_dir() + "/" + uri.get_file()
		new_audio_3d.stream = load(path_stream)
		node_3d.replace_by(new_audio_3d)
		

func import_material_unlit(gstate : GLTFState, json, node_3d, path, index, json_nodes, extensions : Dictionary) -> void:	
	var mesh_node : MeshInstance3D = node_3d
	for surface_i in mesh_node.get_mesh().get_surface_count():
		var mat : BaseMaterial3D = node_3d.get_mesh().surface_get_material(surface_i)
		if mat:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED		

func import_moz_hubs(gstate : GLTFState, json, node_3d, path, index, json_nodes, extensions : Dictionary) -> void:	
	var hubs = extensions["MOZ_hubs_components"]
	var keys : Array = hubs.keys()	
	if keys.has("visible"):
		if hubs["visible"]["visible"] == false:
			node_3d.visible = false
			print("[visible] %s" % [false])
	if keys.has("nav-mesh"):	
		print("[nav-mesh]")
		node_3d.queue_free()
	if keys.has("trimesh"):
		print("[trimesh]")
		var new_node_3d : Node3D = Node3D.new()
		new_node_3d.name = node_3d.name
		new_node_3d.transform = node_3d.transform
		node_3d.replace_by(new_node_3d)
	if keys.has("directional-light"):
		print("[directional-light]")	
		var new_light_3d : DirectionalLight3D = DirectionalLight3D.new()
		new_light_3d.name = node_3d.name
		new_light_3d.transform = node_3d.transform
		new_light_3d.rotate_object_local(Vector3(1.0, 0.0, 0.0), 180)
		node_3d.replace_by(new_light_3d)
		# TODO 2021-07-28 fire: unfinished
	if keys.has("spawn-point"):
		print("[spawn-point]")
		var new_node_3d : Node3D = Node3D.new()
		new_node_3d.name = node_3d.name
		new_node_3d.transform = node_3d.transform
		node_3d.replace_by(new_node_3d)
	if keys.has("audio"):
		print("[audio]")
		var src : String = hubs["audio"]["src"]					
		var new_audio_3d = AudioStreamPlayer3D.new()
		new_audio_3d.name = node_3d.name
		new_audio_3d.transform = node_3d.transform			
		if not src.is_empty():
			var path_stream = path.get_base_dir() + "/" + src.get_file()
			print(path_stream)
			new_audio_3d.stream = load(path_stream)
		var auto_play : bool = hubs["audio"]["autoPlay"]
		new_audio_3d.autoplay = auto_play
		if hubs["audio"].has("volume"):
			var volume : float = hubs["audio"]["volume"]
			new_audio_3d.unit_db = linear2db(volume)
		node_3d.replace_by(new_audio_3d)
	if keys.has("shadow"):
		print("[shadow]")
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
		pass
