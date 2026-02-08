shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float max_radius : hint_range(0.0, 2.0, 0.01) = 0.5;

uniform float thickness : hint_range(0.01, 1.0, 0.01) = 0.1;

uniform float displacement_amount : hint_range(0.0, 1.0, 0.001) = 0.1;
uniform float brightness_diff : hint_range(1.0, 2.0, 0.01) = 1.1;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;

	// center the UVs and get polar coords
	vec2 centered_uv = UV - vec2(.5);
	float dist = length(centered_uv);
	vec2 dir = normalize(centered_uv);

	// apply the sin function to get "texture color"
	float offset_amount = cos(PI * dist / thickness - TIME*4.);
	// scale effect power by radius
	offset_amount *= 1. - smoothstep(0., max_radius, dist);

	// apply that to the screen reading texture
	screen_color = textureLod(screen_texture, SCREEN_UV + centered_uv * offset_amount * displacement_amount, 0.0).rgb;
	// scale color brightness from wave position
	screen_color *= pow(brightness_diff, offset_amount);

	COLOR.rgb = screen_color;
	COLOR.a = 1.;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
