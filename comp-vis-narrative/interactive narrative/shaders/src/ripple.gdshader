shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform sampler2D ripple_texture;

uniform float displacement_amount : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float ripple_size : hint_range(0.0, 3.0, 0.01) = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	
	vec2 ripple_uv = (UV - vec2(.5)) / ripple_size + vec2(.5);
	//vec2 ripple_uv = (UV - vec2(.5)) / (mod(TIME * 2., TAU)) + vec2(.5);
	float offset_amount = textureLod(ripple_texture, ripple_uv, 0.0).r;
	
	vec2 offset_uv = UV - vec2(0.5);
	
	screen_color = textureLod(screen_texture, SCREEN_UV + offset_uv * offset_amount * displacement_amount, 0.0).rgb;
	
	COLOR.rgb = screen_color;
	COLOR.a = 1.0;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
