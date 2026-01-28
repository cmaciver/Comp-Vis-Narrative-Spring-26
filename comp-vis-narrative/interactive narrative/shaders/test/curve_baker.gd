@tool
extends Node

@export var filename : String
@export var curve : CurveTexture

@export_tool_button("bake curve") var bake_curve = bake_curve_to_1d_texture
func bake_curve_to_1d_texture(width: int = 256):
	var curve = curve.curve
	
	var height = 1
	var image = Image.create(width, height, false, Image.FORMAT_RF)
	
	for i in range(width):
		var t = float(i) / (width - 1)
		var value = curve.sample_baked(t)
		
		var min_val = curve.min_value
		var max_val = curve.max_value
		var normalized = (value - min_val) / (max_val - min_val)
		normalized = clamp(normalized, 0.0, 1.0)
		
		for j in range(height):
			image.set_pixel(i, j, Color(normalized, 0, 0, 1))  # Store in R channel
	
	
	var path = "res://interactive narrative/shaders/textures/" + filename + ".png"
	
	image.save_png(path)
	#var texture = ImageTexture.create_from_image(image)
	#texture.take_over_path(path)
	#ResourceSaver.save(texture, path)
	
	print("bakin that shit to " + path)
