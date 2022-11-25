@tool
extends GLTFDocumentExtension

func _import_post(state, root):
	var nodes : Array[GLTFNode] = state.get_nodes()
	for node in nodes:
		if node.mesh != -1:
			var meshes : Array[GLTFMesh] = state.get_meshes()
			var mesh : GLTFMesh = meshes[node.mesh]
			var importer_mesh : ImporterMesh = mesh.mesh
			var array_mesh : ArrayMesh = importer_mesh.get_mesh()
			var faces : int = array_mesh.get_faces().size()
			print("%s %s" % [node.resource_name, faces])
