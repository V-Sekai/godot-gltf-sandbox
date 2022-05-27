@tool
extends EditorPlugin

var scene_import = load("res://addons/add_gltf_extensions/scene_format_import_gltf_extension.gd").new()
var item_string = "glTF Extension 2.0 Scene..."
var menu : PopupMenu = get_export_as_menu()

func _enter_tree():
	add_tool_menu_item(item_string, Callable(self, "_export_menu"))
	add_scene_format_importer_plugin(scene_import, true)

func _exit_tree():
	remove_scene_format_importer_plugin(scene_import)
	remove_tool_menu_item(item_string)
	scene_import = null

func _export_menu():
	var root : Node = get_editor_interface().get_edited_scene_root()
	if not root:
		push_error("This operation can't be done without a scene.")
		return
	var filename : String = String(root.get_scene_file_path().get_file().get_basename());

	var file_export_lib : EditorFileDialog = EditorFileDialog.new()
	get_editor_interface().get_base_control().add_child(file_export_lib)
	file_export_lib.connect("file_selected", Callable(self, "_gltf2_dialog_action"))
	file_export_lib.set_title("Export Library")
	file_export_lib.set_file_mode(EditorFileDialog.FILE_MODE_SAVE_FILE)
	file_export_lib.set_access(EditorFileDialog.ACCESS_FILESYSTEM)
	file_export_lib.clear_filters()
	file_export_lib.add_filter("*.glb")
	file_export_lib.add_filter("*.gltf")
	file_export_lib.set_title("Export Scene to extended glTF 2.0 File")
	if filename.is_empty():
		filename = root.get_name()
	file_export_lib.set_current_file(filename + String(".gltf"));
	file_export_lib.popup_centered_ratio();


var omi_ext : GDScript = preload("res://addons/add_gltf_extensions/omi_audio_emitter.gd")
var hubs_ext : GDScript = preload("res://addons/add_gltf_extensions/moz_hubs_extension.gd")

func _gltf2_dialog_action(p_file : String):
	var root = get_editor_interface().get_edited_scene_root()
	if not root:
		print("This operation can't be done without a scene.")
		return
	var deps : Array 
	var doc : GLTFDocument = GLTFDocument.new()
	var extensions : Array[GLTFDocumentExtension]
	extensions.push_back(omi_ext.new())
	extensions.push_back(hubs_ext.new())
	doc.extensions = extensions
	var state : GLTFState = GLTFState.new()
	var flags : int = 0;
	flags |= EditorSceneFormatImporter.IMPORT_USE_NAMED_SKIN_BINDS;
	var err : int = doc.append_from_scene(root, state, flags, 30.0)
	if err != OK:
		print("glTF save error.")
	err = doc.write_to_filesystem(state, p_file);
	if err != OK:
		print("glTF save error.")
