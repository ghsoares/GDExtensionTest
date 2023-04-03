extends RefCounted
class_name Utils

## Converts a Transform3D into Transform2D with pixel size
static func transform_3d_to_2d(tr: Transform3D, pixel_size: float = 1.0) -> Transform2D:
	var tr_x: Vector3 = tr.basis.x
	var tr_y: Vector3 = tr.basis.y
	var o: Vector3 = tr.origin
	return Transform2D(
		Vector2(tr_x.x, tr_x.y),
		Vector2(tr_y.x, tr_y.y),
		Vector2(o.x, o.y) / pixel_size
	)

## Converts a Transform2D into Transform3D with pixel size
static func transform_2d_to_3d(tr: Transform2D, pixel_size: float = 1.0) -> Transform3D:
	var tr_x: Vector2 = tr.x
	var tr_y: Vector2 = tr.y
	var o: Vector2 = tr.origin
	return Transform3D(
		Vector3(tr_x.x, tr_x.y, 0.0),
		Vector3(tr_y.x, tr_y.y, 0.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(o.x, o.y, 0.0) * pixel_size
	)

