tool
extends Sprite

export (bool) var generate setget set_generate
export (int) var normal_range = 2
export (float) var power = 1.0
export (Texture) var maskTexture

var i = 0

func set_generate(new_generate: bool) -> void:
	generate()

func get_normal(img: Image, mask : Image, pixelX: int, pixelY: int) -> Vector3:
	var n: Vector2 = Vector2.ZERO;
	
	var imgSizeX = img.get_width()
	var imgSizeY = img.get_height()
	
	if normal_range == 0: return Vector3(0, 0, 1.0);
	
	var div : float = pow(normal_range, 2)
	
	for x in range(-normal_range, normal_range+1):
		for y in range(-normal_range, normal_range+1):
			if (x == 0 and y == 0): continue
			
			var off : Vector2 = Vector2(x, y)
			
			var dir : Vector2 = off.normalized()
			var pix : Vector2 = Vector2(pixelX, pixelY) + off
			
			while pix.x < 0:
				pix.x += imgSizeX
			while pix.x > imgSizeX - 1:
				pix.x -= imgSizeX
			
			while pix.y < 0:
				pix.y += imgSizeY
			while pix.y > imgSizeY - 1:
				pix.y -= imgSizeY
			
			var alpha : float = img.get_pixelv(pix).a
			var d = max(off.length() / float(normal_range), 1);
			d = pow(d, power)
			alpha /= d
			
			n += dir * (1 - alpha)
	
	i += 1
	
	n /= div;
	var m = mask.get_pixel(pixelX, pixelY).r
	n *= m
	
	return Vector3(n.x, n.y, 1.0).normalized()

func generate() -> void:
	if (!texture):
		printerr("Insert a texture first!")
		return
	var img : Image = texture.get_data()
	var mask : Image
	if maskTexture:
		mask = maskTexture.get_data()
		mask.resize(img.get_width(), img.get_height())
	else:
		mask = Image.new()
		mask.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
		mask.fill(Color.white)
	var normalImg : Image = Image.new()
	normalImg.create(img.get_width(), img.get_height(), false, img.get_format())
	
	var sizeX = img.get_width()
	var sizeY = img.get_height()
	
	i = 0
	
	img.lock()
	mask.lock()
	normalImg.lock()
	
	for x in range(sizeX):
		for y in range(sizeY):
			var normal : Vector3 = get_normal(img, mask, x, y)
			normal.z = 1.0;
			normal = normal.normalized()
			
			normal.x = normal.x / 2.0 + .5
			normal.y = normal.y / 2.0 + .5
			normal.z = normal.z / 2.0 + .5
			
			normalImg.set_pixel(x, y, Color(normal.x, normal.y, normal.z))
	
	img.unlock()
	mask.unlock()
	normalImg.unlock()
	
	var normalTex : ImageTexture = ImageTexture.new()
	normalTex.create_from_image(normalImg, 0)
	
	normal_map = normalTex
