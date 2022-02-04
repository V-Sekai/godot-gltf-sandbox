@tool
extends GLTFDocumentExtension

func _import_preflight(gstate):
	var path : String = get_export_setting("path")
	if !gstate.json.has("extensionsUsed"):
		return FAILED
	var extensions_used : Array = gstate.json["extensionsUsed"]
	if extensions_used.find("MOZ_hubs_components") == -1:
		return FAILED
	return OK

func _import_node(gstate : GLTFState, gltf_node : GLTFNode, json : Dictionary, node : Node3D) -> int:
	var node_extensions = json.get("extensions")
	if not json.has("extensions"):
		return FAILED
	var path : String = get_import_setting("path")
	if node_extensions.has("MOZ_hubs_components"):
		import_moz_hubs(gstate, json, node, path, node_extensions)
	if node_extensions.has("KHR_materials_unlit"):
		import_material_unlit(gstate, json, node, path, node_extensions)
	return OK


func import_material_unlit(gstate : GLTFState, json : Dictionary, node_3d : Node3D, path : String, extensions : Dictionary) -> void:	
	var mesh_node : MeshInstance3D = node_3d
	for surface_i in mesh_node.get_mesh().get_surface_count():
		var mat : BaseMaterial3D = node_3d.get_mesh().surface_get_material(surface_i)
		if mat:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED		


func import_moz_hubs(gstate : GLTFState, json : Dictionary, node_3d : Node3D, path : String, extensions : Dictionary) -> void:	
	var hubs = extensions["MOZ_hubs_components"]
	var keys : Array = hubs.keys()	
	var AUDIO = "audio"
	var new_node : Node = null
	var old_node : Node = node_3d
	for key_i in keys:
		print("[%s]" % key_i)
		if key_i == "visible":
			var visible_state = hubs["visible"]["visible"]
			node_3d.set_visible(visible_state)
			print(visible_state)
		elif key_i == "nav-mesh":
			node_3d.set_visible(false)
		elif key_i == "trimesh":
			node_3d.set_visible(false)
			# TODO: fire 2022-02-01 add collision mesh
		elif key_i == "directional-light":
			new_node = DirectionalLight3D.new()
			new_node.name = node_3d.name
			new_node.transform = node_3d.transform
			new_node.rotate_object_local(Vector3(1.0, 0.0, 0.0), 180)
			# TODO 2021-07-28 fire: unfinished
		elif key_i == "spawn-point":
			pass
		elif key_i == AUDIO:
			var src : String = hubs[AUDIO]["src"]					
			new_node = AudioStreamPlayer3D.new()
			new_node.name = node_3d.name
			new_node.transform = node_3d.transform			
			if not src.is_empty():
				var path_stream = path.get_base_dir() + "/" + src.get_file()
				print(path_stream)
				new_node.stream = load(path_stream)
			var auto_play : bool = hubs[AUDIO]["autoPlay"]
			new_node.autoplay = auto_play
			if hubs[AUDIO].has("volume"):
				var volume : float = hubs[AUDIO]["volume"]
				new_node.unit_db = linear2db(volume)
		elif key_i == "shadow":
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
		else:
			print("Not implemented.")
	if new_node:
		node_3d.replace_by(new_node)
		old_node.queue_free()
