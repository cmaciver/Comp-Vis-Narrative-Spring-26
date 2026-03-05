extends Control
class_name CrackOverlay

# For swapping to PNG later - set these in inspector
@export var damaged_texture: Texture2D = null
@export var healed_texture: Texture2D = null

var damaged_image: Image  # top layer we erase into
var damaged_texture_rect: TextureRect
var damaged_tex: ImageTexture
var healed_texture_rect: TextureRect

var total_crack_pixels: int = 0
var erased_pixels: int = 0
var crack_size: Vector2
var is_ready: bool = false

func _ready():
	if damaged_texture and healed_texture:
		setup_from_textures()
	else:
		setup_from_placeholder()
	is_ready = true

func setup_from_textures():
	# PNG mode - use provided textures
	crack_size = damaged_texture.get_size()

	# Bottom: healed version
	healed_texture_rect = TextureRect.new()
	healed_texture_rect.texture = healed_texture
	healed_texture_rect.position = -crack_size / 2
	add_child(healed_texture_rect)

	# Top: damaged version (we erase this)
	damaged_image = damaged_texture.get_image()
	damaged_tex = ImageTexture.create_from_image(damaged_image)
	damaged_texture_rect = TextureRect.new()
	damaged_texture_rect.texture = damaged_tex
	damaged_texture_rect.position = -crack_size / 2
	add_child(damaged_texture_rect)

	count_crack_pixels()

func setup_from_placeholder():
	# Placeholder mode - create simple images with a jagged crack drawn in
	crack_size = Vector2(120, 30)
	var width = int(crack_size.x)
	var height = int(crack_size.y)

	# Generate jagged path points
	var path_points = generate_jagged_path(width, height)

	# Create healed image (white line)
	var healed_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	healed_image.fill(Color(0, 0, 0, 0))  # transparent
	draw_thick_line_on_image(healed_image, path_points, Color.WHITE, 6)

	var healed_tex = ImageTexture.create_from_image(healed_image)
	healed_texture_rect = TextureRect.new()
	healed_texture_rect.texture = healed_tex
	healed_texture_rect.position = -crack_size / 2
	add_child(healed_texture_rect)

	# Create damaged image (dark line on top)
	damaged_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	damaged_image.fill(Color(0, 0, 0, 0))  # transparent
	draw_thick_line_on_image(damaged_image, path_points, Color(0.12, 0.08, 0.05), 6)

	damaged_tex = ImageTexture.create_from_image(damaged_image)
	damaged_texture_rect = TextureRect.new()
	damaged_texture_rect.texture = damaged_tex
	damaged_texture_rect.position = -crack_size / 2
	add_child(damaged_texture_rect)

	count_crack_pixels()

func generate_jagged_path(width: int, height: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	var segments = 10
	var mid_y = height / 2.0
	for i in range(segments + 1):
		var x = (float(i) / segments) * (width - 4) + 2
		var y = mid_y + randf_range(-height / 3.0, height / 3.0)
		points.append(Vector2(x, y))
	return points

func draw_thick_line_on_image(img: Image, points: PackedVector2Array, color: Color, thickness: int):
	# Draw thick line by drawing circles along the path
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i + 1]
		var dist = p1.distance_to(p2)
		var steps = int(dist) + 1
		for s in range(steps + 1):
			var t = float(s) / float(steps)
			var pos = p1.lerp(p2, t)
			draw_circle_on_image(img, pos, thickness / 2, color)

func draw_circle_on_image(img: Image, center: Vector2, radius: int, color: Color):
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var px = int(center.x) + dx
				var py = int(center.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, color)

func count_crack_pixels():
	total_crack_pixels = 0
	for x in damaged_image.get_width():
		for y in damaged_image.get_height():
			if damaged_image.get_pixel(x, y).a > 0.1:
				total_crack_pixels += 1
	total_crack_pixels = max(total_crack_pixels, 1)  # avoid div by zero

func erase_at_global(global_pos: Vector2, radius: int):
	if not is_ready or damaged_image == null or damaged_texture_rect == null:
		return

	# Convert global position to local position relative to the texture rect
	var local_pos = global_pos - damaged_texture_rect.global_position

	# Erase circle from damaged image (set alpha to 0)
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var px = int(local_pos.x) + dx
				var py = int(local_pos.y) + dy
				if px >= 0 and px < damaged_image.get_width() and py >= 0 and py < damaged_image.get_height():
					var current = damaged_image.get_pixel(px, py)
					if current.a > 0.1:
						erased_pixels += 1
						damaged_image.set_pixel(px, py, Color(0, 0, 0, 0))

	damaged_tex.update(damaged_image)

func get_coverage() -> float:
	return float(erased_pixels) / float(total_crack_pixels)
