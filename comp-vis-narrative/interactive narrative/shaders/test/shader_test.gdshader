shader_type canvas_item;

uniform float pieces :hint_range(1.0, 100.0, 1.)= 10;
uniform float pixel_amount :hint_range(0.0, 1.0)= 1.;

void vertex() {
	// Called for every vertex the material is visible on.
	UV -= vec2(0.5, 0.5);
	
	float t = TIME;
	mat2 rot = mat2(vec2(cos(t), sin(t)), vec2(-sin(t), cos(t)));
	UV = rot * UV;
	
	UV += vec2(0.5, 0.5);

}

void fragment() {
	// Called for every pixel the material is visible on.
	
	
	vec2 uv = UV;
	
	
	//float pieces = 10.;
	uv.x = round(UV.x * pieces) / pieces;
	uv.y = round(UV.y * pieces) / pieces;
	
	vec4 pixel = texture(TEXTURE, uv);
	COLOR = mix(texture(TEXTURE, UV), pixel, pixel_amount);
	
	//COLOR = vec4(UV, 0.5, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
