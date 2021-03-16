tool
extends Node2D

class_name PeakValleys

var peaks = []
var valleys = []

var peakCols = []
var valleyCols = []

var world

func GetPeakAndValleys() -> void:
	var terrain = world.terrain
	var spacing = 1.0 / world.settings.terrainResolution
	
	var blocks = []
	
	var firstIsValley = false
	
	var mode := 0 # Peak: 0, Valley: 1
	var prevH = terrain.SampleTerrainHeight(0.0)
	
	if terrain.SampleTerrainHeight(spacing) < prevH:
		firstIsValley = true
		mode = 1
	
	var currRegionStart = Vector2(0.0, world.terrain.size.y - prevH)
	var currRegionEnd = currRegionStart
	
	for x in range(0.0, world.terrain.size.x + 256.0, spacing):
		var h = terrain.SampleTerrainHeight(x)
		var y = world.terrain.size.y - h
		
		currRegionEnd.x = x
		currRegionStart.y = min(currRegionStart.y, y)
		currRegionEnd.y = max(currRegionEnd.y, y)
		
		if mode == 0:
			if h < prevH:
				mode = 1
				var region = Rect2(currRegionStart, currRegionEnd - currRegionStart)
				blocks.append(region)
				currRegionStart = Vector2(x, y)
				currRegionEnd = currRegionStart
		else:
			if h >= prevH:
				mode = 0
				var region = Rect2(currRegionStart, currRegionEnd - currRegionStart)
				blocks.append(region)
				currRegionStart = Vector2(x, y)
				currRegionEnd = currRegionStart
		
		prevH = h
	
	var region = Rect2(currRegionStart, currRegionEnd - currRegionStart)
	blocks.append(region)
	
	peaks = []
	valleys = []
	
	mode = 0
	if firstIsValley:
		mode = 1
	
	for i in range(blocks.size() - 1):
		var region1 = blocks[i]
		var region2 = blocks[i+1]
		
		if region1.position.x > world.terrain.size.x: break
		
		if mode == 0:
			region = Rect2()
			
			region.position.x = region1.position.x
			region.end.x = region2.end.x
			
			region.position.y = max(region1.position.y, region2.position.y)
			region.end.y = max(region1.end.y, region2.end.y)
			
			region.position.y -= 2
			
			if region.size.x > 4 and region.size.y > 4:
				peaks.append(region)
			mode = 1
		else:
			region = Rect2()
			region.position.x = region1.position.x
			region.end.x = region2.end.x
			
			region.position.y = max(region1.position.y, region2.position.y)
			region.end.y = max(region1.end.y, region2.end.y)
			
			region.end.y += 4
			
			if region.size.x > 4 and region.size.y > 4:
				valleys.append(region)
			mode = 0
	
	peakCols = []
	valleyCols = []
	
	for peak in peaks:
		var col = ColorRect.new()
		#var intersects = world.platformPlacer.GetPlatformsIntersectingRect(peak).size() != 0
		col.rect_position = peak.position
		col.rect_size = peak.size
		col.color = Color.green
		#if intersects:
		#	col.color *= Color.black
		col.color.a = .5
		add_child(col)
		peakCols.append(col)
		col.hide()
	
	for valley in valleys:
		var col = ColorRect.new()
		#var intersects = world.platformPlacer.GetPlatformsIntersectingRect(valley).size() != 0
		col.rect_position = valley.position
		col.rect_size = valley.size
		col.color = Color.red
		#if intersects:
		#	col.color *= Color.black
		col.color.a = .5
		add_child(col)
		valleyCols.append(col)
		col.hide()

var delay : float
var show : int = 0

func _process(delta: float) -> void:
#	delay += delta
#	if delay >= 1.0:
#		if show == 0:
#			for valley in valleyCols:
#				valley.hide()
#			for peak in peakCols:
#				peak.show()
#			show = 1
#		else:
#			for valley in valleyCols:
#				valley.show()
#			for peak in peakCols:
#				peak.hide()
#			show = 0
#		delay = 0.0
	pass




