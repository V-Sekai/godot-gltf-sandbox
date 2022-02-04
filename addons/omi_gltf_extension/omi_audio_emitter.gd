@tool
extends GLTFDocumentExtension

func _import_preflight(state):
	if not state.json.has("extensionsUsed"):
		return FAILED
	var extensions_used : Array = state.json["extensionsUsed"]
	if not extensions_used.has("OMI_audio_emitter"):
		return FAILED
	print("Using %s GLTF2 extension." % ["OMI_audio_emitter"])
	return OK


func _import_post_parse(state : GLTFState):
	var extensions : Dictionary = state.json["extensions"]
	var emitter_json : Dictionary = extensions["OMI_audio_emitter"]
	if not emitter_json.has("audioSources"):
		return OK
	if not emitter_json.has("audioEmitters"):
		return OK
	if not state.root_nodes.size():
		return OK
	var root_i : int = state.root_nodes[0]
	var node : Node = state.get_scene_node(root_i)
	var emitters : Array = emitter_json["audioEmitters"]
	for emitter in emitters:
		if not emitter.has("type"):
			continue
		if not emitter["type"] == "global":
			continue
		var src = emitter["source"]
		var audio_sources : Array = emitter_json["audioSources"]
		var audio_source : Dictionary = audio_sources[src]
		var path : String = get_import_setting("path")
		create_global_emitter(node, audio_source, emitter, path)
	return OK

func create_global_emitter(root_node : Node, audio_source : Dictionary, emitter : Dictionary, path : String) -> void:
	var new_node : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	if emitter.has("name"):
		new_node.name = emitter["name"]
	if emitter.has("autoPlay"):
		new_node.autoplay = emitter["autoPlay"]
	var uri = audio_source["uri"]
	var path_stream = path.get_base_dir() + "/" + uri.get_file()
	var stream : AudioStreamMP3 = load(path_stream)
	if emitter.has("loop"):
		stream.loop = emitter["loop"]
	new_node.stream = stream
	if emitter.has("maxDistance"):
		new_node.max_distance = emitter["maxDistance"]
	root_node.add_child(new_node, true)
	new_node.owner = root_node.owner
	print("[audioEmitter global]")

func _import_node(gstate : GLTFState, gltf_node : GLTFNode, json : Dictionary, node : Node3D) -> int:
	var path : String = get_import_setting("path")
	if not json.has("extensions"):
		return OK
	var node_extensions : Dictionary = json["extensions"]
	if not node_extensions.has("OMI_audio_emitter"):
		return OK
	var extensions : Dictionary = gstate.json["extensions"]
	var emitter_json : Dictionary = extensions["OMI_audio_emitter"]
	import_omi_audio_emitter(gstate, json, node, path, emitter_json)
	return OK


func import_omi_audio_emitter(gstate : GLTFState, json : Dictionary, node_3d : Node3D, path : String, extension_document : Dictionary) -> void:
	if not json.has("extensions"):
		return
	var extensions = json["extensions"]
	if not extensions.has("OMI_audio_emitter"):
		return
	var omi_emitter = extensions["OMI_audio_emitter"]
	var keys : Array = omi_emitter.keys()
	for key_i in keys:
		print("[%s]" % [key_i])
		if key_i == "audioEmitter":
			var src : int = omi_emitter["audioEmitter"]
			var new_node : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
			var sources = extension_document["audioSources"]
			var audio_emitter : Dictionary = sources[src]
			var uri = audio_emitter["uri"]
			if audio_emitter.has("name"):
				new_node.name = audio_emitter["name"]
			if audio_emitter.has("autoPlay"):
				new_node.autoplay = audio_emitter["autoPlay"]
			var path_stream = path.get_base_dir() + "/" + uri.get_file()
			var stream : AudioStreamMP3 = load(path_stream)
			if audio_emitter.has("loop"):
				stream.loop = audio_emitter["loop"]
			new_node.stream = stream
			if audio_emitter.has("maxDistance"):
				new_node.max_distance = audio_emitter["maxDistance"]
			#audio_emitter["coneInnerAngle"]
			#audio_emitter["coneOuterAngle"]
			#audio_emitter["coneOuterGain"]
			#audio_emitter["distanceModel"]
			#audio_emitter["rolloffFactor"]
			node_3d.add_child(new_node, true)
			new_node.owner = node_3d.owner
