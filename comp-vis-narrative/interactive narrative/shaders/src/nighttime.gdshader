shader_type canvas_item;

#include "oklab.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float switch_point : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float spec_pow : hint_range(2.0, 10.0, 0.1) = 7.4;
uniform float gamma_adjust : hint_range(1.0, 3.0, 0.01) = 2.4;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 oklab_c = oklab_from_linear(screen_color);


	//float brightness = smoothstep(0.8, 0.9, oklab_c.x);
	float spec = pow(oklab_c.x, spec_pow);
	float top_spec = smoothstep(switch_point, 1.0, spec);

	screen_color.xyz = oklab_mix(vec3(0., 0., 0.01), screen_color.rgb, spec );
	screen_color.rgb = oklab_mix(vec3(0., 0., 0.01), screen_color.rgb, 1. - top_spec );




	//screen_color = linear_from_oklab(screen_color);
	COLOR.rgb = screen_color * gamma_adjust;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
