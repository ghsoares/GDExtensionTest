@tool
extends EditorNode3DGizmoPlugin
class_name CollisionShapeSpatial2DGizmoPlugin

var plugin: EditorPlugin

# -- Protected functions --
func _init(plugin: EditorPlugin) -> void:
	self.plugin = plugin
	var interface: EditorInterface = plugin.get_editor_interface()
	var settings: EditorSettings = interface.get_editor_settings()
	var gizmo_color: Color = settings.get_setting("editors/3d_gizmos/gizmo_colors/shape")
	create_material("shape_material", gizmo_color)
	var gizmo_value: float = gizmo_color.v
	var gizmo_color_disabled: Color = Color(gizmo_value, gizmo_value, gizmo_value, 0.65)
	create_material("shape_material_disabled", gizmo_color_disabled)
	create_handle_material("handles")

func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is CollisionShapeSpatial2D

func _get_gizmo_name() -> String:
	return "CollisionShapeSpatial2D"

func _get_priority() -> int:
	return -1

func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	var cs: CollisionShapeSpatial2D = gizmo.get_node_3d() as CollisionShapeSpatial2D

	var s: Shape2D = cs.shape
	if not s:
		return ""
	
	if s is CircleShape2D:
		return "radius"
	
	if s is RectangleShape2D:
		return "size"
	
	if s is CapsuleShape2D:
		return "radius" if handle_id == 0 else "height"
	
	if s is SeparationRayShape2D:
		return "length"

	return ""

func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool):
	var cs: CollisionShapeSpatial2D = gizmo.get_node_3d() as CollisionShapeSpatial2D

	var s: Shape2D = cs.shape
	if not s:
		return null
	
	if s is CircleShape2D:
		return s.radius
	
	if s is RectangleShape2D:
		return s.size
	
	if s is CapsuleShape2D:
		return Vector2(s.radius, s.height)

	if s is SeparationRayShape2D:
		return s.length
	
	return null

func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var cs: CollisionShapeSpatial2D = gizmo.get_node_3d() as CollisionShapeSpatial2D

	var s: Shape2D = cs.shape
	if not s:
		return

	var gt: Transform3D = cs.global_transform
	var gi: Transform3D = gt.affine_inverse()

	var ro: Vector3 = camera.project_ray_origin(screen_pos)
	var rd: Vector3 = camera.project_ray_normal(screen_pos)

	var la: Vector3 = gi * ro
	var lb: Vector3 = gi * (ro + rd * 4096)

	if s is CircleShape2D:
		var rab: PackedVector3Array = Geometry3D.get_closest_points_between_segments(
			Vector3(), Vector3(4096, 0.0, 0.0), la, lb
		)

		var ra: Vector3 = rab[0]
		var rb: Vector3 = rab[1]

		var d: float = ra.x

		if d < 0.001:
			d = 0.001
		
		s.radius = d
	
	if s is RectangleShape2D:
		var axis: Vector3
		axis[handle_id] = 1.0
		
		var rab: PackedVector3Array = Geometry3D.get_closest_points_between_segments(
			Vector3(), axis * 4096, la, lb
		)

		var ra: Vector3 = rab[0]
		var rb: Vector3 = rab[1]

		var d: float = ra[handle_id] * 2

		if d < 0.001:
			d = 0.001
		
		s.size[handle_id] = d
	
	if s is CapsuleShape2D:
		var axis: Vector3
		axis[handle_id] = 1.0
		var rab: PackedVector3Array = Geometry3D.get_closest_points_between_segments(
			Vector3(), axis * 4096, la, lb
		)

		var ra: Vector3 = rab[0]
		var rb: Vector3 = rab[1]

		var d: float = axis.dot(ra)

		if d < 0.001:
			d = 0.001
		
		if handle_id == 0:
			s.radius = d
		elif handle_id == 1:
			s.height = d * 2.0

	if s is SeparationRayShape2D:
		var rab: PackedVector3Array = Geometry3D.get_closest_points_between_segments(
			Vector3(), Vector3(0.0, -4096.0, 0.0), la, lb
		)

		var ra: Vector3 = rab[0]
		var rb: Vector3 = rab[1]

		var d: float = -ra.y

		if d < 0.001:
			d = 0.001
		
		s.length = d
	
func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore, cancel: bool) -> void:
	var cs: CollisionShapeSpatial2D = gizmo.get_node_3d() as CollisionShapeSpatial2D

	var s: Shape2D = cs.shape
	if not s:
		return
	
	if s is CircleShape2D:
		if cancel:
			s.radius = restore
			return
		
		var ur: EditorUndoRedoManager = plugin.get_undo_redo()
		ur.create_action("Change circle shape radius")
		ur.add_do_method(s, "set_radius", s.radius)
		ur.add_undo_method(s, "set_radius", restore)
		ur.commit_action()

	if s is RectangleShape2D:
		if cancel:
			s.size = restore
			return
		
		var ur: EditorUndoRedoManager = plugin.get_undo_redo()
		ur.create_action("Change rectangle shape radius")
		ur.add_do_method(s, "set_size", s.size)
		ur.add_undo_method(s, "set_size", restore)
		ur.commit_action()

	if s is CapsuleShape2D:
		if cancel:
			s.radius = restore.x
			s.height = restore.y
			return
		
		var ur: EditorUndoRedoManager = plugin.get_undo_redo()
		if handle_id == 0:
			ur.create_action("Change capsule shape radius")
			ur.add_do_method(s, "set_radius", s.radius)
		elif handle_id == 1:
			ur.create_action("Change capsule shape height")
			ur.add_do_method(s, "set_height", s.height)
		ur.add_undo_method(s, "set_radius", restore.x)
		ur.add_undo_method(s, "set_height", restore.y)
		ur.commit_action()
	
	if s is SeparationRayShape2D:
		if cancel:
			s.length = restore
			return
		
		var ur: EditorUndoRedoManager = plugin.get_undo_redo()
		ur.create_action("Change separation ray shape length")
		ur.add_do_method(s, "set_length", s.length)
		ur.add_undo_method(s, "set_length", restore)
		ur.commit_action()

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	var cs: CollisionShapeSpatial2D = gizmo.get_node_3d() as CollisionShapeSpatial2D

	gizmo.clear()

	var s: Shape2D = cs.shape
	if not s:
		return
	
	var material: Material = get_material("shape_material" if cs.disabled else "shape_material_disabled", gizmo)
	var handles_material: Material = get_material("handles")

	if s is CircleShape2D:
		var r: float = s.radius

		var points: PackedVector3Array
		var col_points: PackedVector3Array

		for i in 360:
			var ra: float = deg_to_rad(i)
			var rb: float = deg_to_rad(i + 1)
			var a: Vector2 = Vector2(sin(ra) * r, cos(ra) * r)
			var b: Vector2 = Vector2(sin(rb) * r, cos(rb) * r)

			points.push_back(Vector3(a.x, a.y, 0.0))
			points.push_back(Vector3(b.x, b.y, 0.0))
		
		for i in 64:
			var ra: float = i * (TAU / 64)
			var rb: float = (i + 1) * (TAU / 64)
			var a: Vector2 = Vector2(sin(ra) * r, cos(ra) * r)
			var b: Vector2 = Vector2(sin(rb) * r, cos(rb) * r)

			points.push_back(Vector3(a.x, a.y, 0.0))
			points.push_back(Vector3(b.x, b.y, 0.0))
		
		gizmo.add_lines(points, material)
		gizmo.add_collision_segments(col_points)

		var handles: PackedVector3Array
		handles.push_back(Vector3(r, 0.0, 0.0))
		gizmo.add_handles(handles, handles_material, PackedInt32Array())
	
	if s is RectangleShape2D:
		var size: Vector2 = s.size
		var hs: Vector2 = size * 0.5

		var lines: PackedVector3Array
		lines.push_back(Vector3(-hs.x, -hs.y, 0.0))
		lines.push_back(Vector3(-hs.x,  hs.y, 0.0))

		lines.push_back(Vector3(-hs.x,  hs.y, 0.0))
		lines.push_back(Vector3( hs.x,  hs.y, 0.0))

		lines.push_back(Vector3( hs.x,  hs.y, 0.0))
		lines.push_back(Vector3( hs.x, -hs.y, 0.0))

		lines.push_back(Vector3( hs.x, -hs.y, 0.0))
		lines.push_back(Vector3(-hs.x, -hs.y, 0.0))

		var handles: PackedVector3Array
		handles.push_back(Vector3( hs.x, 0.0, 0.0))
		handles.push_back(Vector3( 0.0, hs.y, 0.0))

		gizmo.add_lines(lines, material)
		gizmo.add_collision_segments(lines)
		gizmo.add_handles(handles, handles_material, PackedInt32Array())
	
	if s is CapsuleShape2D:
		var r: float = s.radius
		var h: float = s.height

		var points: PackedVector3Array
		var col_points: PackedVector3Array

		var d: Vector3 = Vector3(0, h * 0.5 - r, 0.0)
		for i in 360:
			var ra: float = deg_to_rad(i)
			var rb: float = deg_to_rad(i + 1)
			var a: Vector2 = Vector2(sin(ra), cos(ra)) * r
			var b: Vector2 = Vector2(sin(rb), cos(rb)) * r
			var dud: Vector3 = d if i < 180 else -d

			if i % 90 == 0:
				points.push_back(Vector3(a.y, a.x, 0.0) + d)
				points.push_back(Vector3(a.y, a.x, 0.0) - d)

			points.push_back(Vector3(a.y, a.x, 0.0) + dud)
			points.push_back(Vector3(b.y, b.x, 0.0) + dud)
		
		for i in 64:
			var ra: float = i * (TAU / 64)
			var rb: float = (i + 1) * (TAU / 64)
			var a: Vector2 = Vector2(sin(ra), cos(ra)) * r
			var b: Vector2 = Vector2(sin(rb), cos(rb)) * r
			var dud: Vector3 = d if i < 32 else -d

			if i % 16 == 0:
				col_points.push_back(Vector3(a.y, a.x, 0.0) + d)
				col_points.push_back(Vector3(a.y, a.x, 0.0) - d)

			col_points.push_back(Vector3(a.y, a.x, 0.0) + dud)
			col_points.push_back(Vector3(b.y, b.x, 0.0) + dud)
		
		gizmo.add_lines(points, material)
		gizmo.add_collision_segments(col_points)

		var handles: PackedVector3Array
		handles.push_back(Vector3(r, 0.0, 0.0))
		handles.push_back(Vector3(0.0, h * 0.5, 0.0))
		gizmo.add_handles(handles, handles_material, PackedInt32Array())
	
	if s is SeparationRayShape2D:
		var len: float = s.len

		var lines: PackedVector3Array
		lines.push_back(Vector3(0.0, 0.0, 0.0))
		lines.push_back(Vector3(0.0, -len, 0.0))

		var handles: PackedVector3Array
		handles.push_back(Vector3(0.0, -len, 0.0))

		gizmo.add_lines(lines, material)
		gizmo.add_collision_segments(lines)
		gizmo.add_handles(handles, handles_material, PackedInt32Array())










