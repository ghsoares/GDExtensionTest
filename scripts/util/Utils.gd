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

## Converts an integer into binary string
static func int_to_bin_string(num: int, padding: int = 0, big_endian: bool = true) -> String:
	var b: String = ""
	var size: int = 0

	while num > 0:
		if big_endian:
			b = str(num & 1) + b
		else:
			b = b + str(num & 1)
		num = num >> 1
		size += 1
	
	if padding > 0:
		var rem: int = padding - size
		if rem > 0:
			if big_endian:
				b = "0".repeat(rem) + b
			else:
				b = b + "0".repeat(rem)
		elif rem < 0:
			if rem:
				b = b.substr(-rem)
			else:
				b = b.substr(0, b.length() + rem)

	return b

static func smoothmin(a: float, b: float, k: float) -> float:
	var h: float = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return (b + (a - b) * h) - k * h * (1.0 - h)

static func smoothmax(a: float, b: float, k: float) -> float:
	return smoothmin(a, b, -k)

static func remap(val: float, a0: float, a1: float, b0: float, b1: float) -> float:
	return b0 + (b1 - b0) * ((val - a0) / (a1 - a0))

