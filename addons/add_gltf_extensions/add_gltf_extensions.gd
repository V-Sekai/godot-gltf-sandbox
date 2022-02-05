@tool
extends EditorScenePostImportPlugin

var omi_ext : GLTFDocumentExtension = load("res://addons/add_gltf_extensions/omi_audio_emitter.gd").new()
var hubs_ext : GLTFDocumentExtension = load("res://addons/add_gltf_extensions/omi_audio_emitter.gd").new()
var path : String
func _get_import_options(p_path):
	path = p_path


func _internal_process(category, base_node, node, resource):
	if category != EditorScenePostImportPlugin.INTERNAL_IMPORT_CATEGORY_PREFLIGHT:
		return
	if resource == null:
		return
	if not resource is EditorSceneFormatImporterGLTF:
		return
	var gltf = resource
	if gltf.gltf_extensions == null:
		gltf.gltf_extensions = Array()
	var omi_ext_i = gltf.gltf_extensions.find(omi_ext)
	var path = get_option_value("path")
	omi_ext.add_import_setting("path", path)
	if omi_ext_i != -1:
		gltf.gltf_extensions.push_front(omi_ext)
		
#	if gltf.gltf_extensions.find(hubs_ext) == -1:
#		hubs_ext.add_import_setting("path", "./")
#		gltf.gltf_extensions.push_front(hubs_ext)

