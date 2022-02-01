@tool
extends GLTFDocumentExtension

func _import_node(gstate : GLTFState, gltf_node : GLTFNode, json : Dictionary, node : Node3D) -> int:
	var path : String = get_export_setting("path")
	if not json.has("extensions"):
		return OK
	var node_extensions = json.get("extensions")
	if node_extensions.has("OMI_audio_emitter"):
		import_omi_audio_emitter(gstate, json, node, path, node_extensions)
	return OK


func import_omi_audio_emitter(gstate : GLTFState, json : Dictionary, node_3d : Node3D, path : String, extensions : Dictionary) -> void:	
	var omi_emitter = extensions["OMI_audio_emitter"]
	var keys : Array = omi_emitter.keys()
	if keys.has("audioEmitter"):
		var src : int = omi_emitter["audioEmitter"]
		var new_audio_3d = AudioStreamPlayer3D.new()
		new_audio_3d.name = node_3d.name
		new_audio_3d.transform = node_3d.transform

		var global_extensions : Dictionary = gstate.json["extensions"]
		if not global_extensions.size():
			return
		if not global_extensions.has("OMI_audio_emitter"):
			return
		var sources = global_extensions["OMI_audio_emitter"]["audioSources"]
		var uri = sources[src]["uri"]
		var path_stream = path.get_base_dir() + "/" + uri.get_file()
		new_audio_3d.stream = load(path_stream)
		node_3d.replace_by(new_audio_3d)
		
