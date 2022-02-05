@tool
extends EditorScenePostImportPlugin

var omi_ext : GLTFDocumentExtension = load("res://addons/add_gltf_extensions/omi_audio_emitter.gd").new()
var hubs_ext : GLTFDocumentExtension = load("res://addons/add_gltf_extensions/moz_hubs_extension.gd").new()

func _internal_process(category, base_node, node, resource):
	if category != EditorScenePostImportPlugin.INTERNAL_IMPORT_CATEGORY_PREFLIGHT:
		return
	if resource == null:
		return
	if not resource is EditorSceneFormatImporterGLTF:
		return
	var gltf = resource
	var omi_ext_i = gltf.gltf_extensions.find(omi_ext) 
	if omi_ext_i != -1:
		gltf.gltf_extensions.remove(omi_ext_i)
	gltf.gltf_extensions.push_front(omi_ext)
		
#	if gltf.gltf_extensions.find(hubs_ext) == -1:
#		hubs_ext.set_import_setting("path", "./")
#		gltf.gltf_extensions.push_front(hubs_ext)

