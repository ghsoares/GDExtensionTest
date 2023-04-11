extends RefCounted
class_name QuadTree

## A single item class
class Item:
	var pos: Vector2
	var value: Variant

	## Creates a new item
	func _init(pos: Vector2, value: Variant) -> void:
		self.pos = pos
		self.value = value

## The rect of this tree
var rect: Rect2

## This tree capacity
var capacity: int

## This tree depth
var depth: int

## The child trees of this tree
var children: Array[QuadTree]

## The items of this tree
var items: Array[Item]

## Is this tree subdivided
var subdivided: bool

## This tree item count
var count: int

## Creates a new tree
func _init(rect: Rect2, capacity: int, depth: int = 2) -> void:
	assert(depth >= 0)
	self.rect = rect
	self.capacity = capacity
	self.depth = depth

## Subdivides this node
func subdivide() -> void:
	assert(!subdivided)
	assert(depth > 0)

	# Rect position and size
	var rp: Vector2 = rect.position
	var rs: Vector2 = rect.size

	# Subidivide in four children
	self.children = [
		QuadTree.new(Rect2(
			rp.x, rp.y,
			rs.x * 0.5, rs.y * 0.5
		), capacity, depth - 1),
		QuadTree.new(Rect2(
			rp.x + rs.x * 0.5, rp.y,
			rs.x * 0.5, rs.y * 0.5
		), capacity, depth - 1),
		QuadTree.new(Rect2(
			rp.x, rp.y + rs.y * 0.5,
			rs.x * 0.5, rs.y * 0.5
		), capacity, depth - 1),
		QuadTree.new(Rect2(
			rp.x + rs.x * 0.5, rp.y + rs.y * 0.5,
			rs.x * 0.5, rs.y * 0.5
		), capacity, depth - 1)
	]

	# For each item
	for item in items:
		# Get quadrant
		var qx: int = clamp((item.pos.x - rp.x) / (rs.x * 0.5), 0, 1)
		var qy: int = clamp((item.pos.y - rp.y) / (rs.y * 0.5), 0, 1)

		# Get children index
		var i: int = qy * 2 + qx

		# Insert in child
		self.children[i].__append(item)
	
	# Set this items to empty
	items = []

	# Set self subdivided to true
	subdivided = true

## Internally appends a new value
func __append(item: Item) -> void:
	# Is subdivided, add to children
	if subdivided:
		# Get quadrant
		var qx: int = clamp((item.pos.x - rect.position.x) / (rect.size.x * 0.5), 0, 1)
		var qy: int = clamp((item.pos.y - rect.position.y) / (rect.size.y * 0.5), 0, 1)

		# Get children index
		var i: int = qy * 2 + qx

		# Insert in child
		self.children[i].__append(item)
	else:
		# Adds in items
		items.append(item)

		# Will not exceed capacity
		if count < capacity or depth == 0:
			# Increment count
			count += 1
		# Subdivide
		else:
			subdivide()

## Append a new value to the tree
func append(pos: Vector2, value: Variant) -> bool:
	# Only add if inside rect
	if !self.rect.has_point(pos): return false
	
	__append(Item.new(pos, value))

	# Successfully added
	return true

## Fetch all the points inside rect
func get_inside(rect: Rect2, result: Array = []) -> Array:
	# Not inside self rect
	if !self.rect.intersects(rect): return result

	# Is subdivided, continue to children
	if subdivided:
		for c in children:
			c.get_inside(rect, result)
	else:
		# For each item
		for i in items:
			# Check if rect has item
			if rect.has_point(i.pos): result.append(i.value)

	# Return result
	return result

