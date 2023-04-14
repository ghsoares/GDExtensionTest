@tool
extends EditorPlugin

var gizmo_plugin: CollisionShapeSpatial2DGizmoPlugin

func _enter_tree() -> void:
	gizmo_plugin = CollisionShapeSpatial2DGizmoPlugin.new(self)
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	gizmo_plugin = null
