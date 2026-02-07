shader_type canvas_item;

#include "oklab.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float red_shift : hint_range(0.0, 0.1, 0.01) = 0.07;
uniform float yellow_shift : hint_range(0.0, 0.1, 0.01) = 0.02;
uniform float gamma_adjust : hint_range(1.0, 10.0, 0.01) = 2.4;
//uniform vec3 color : source_color = vec3(0.905, 0.209, 0.024) ;



void fragment() {
	vec3 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 oklab_c = oklab_from_linear(screen_color);
	
	float brightness = smoothstep(0.5, 1.0, oklab_c.x);
	oklab_c.x = brightness;
	oklab_c.x *= 0.75;
	oklab_c.y += red_shift;
	oklab_c.z += yellow_shift;
	screen_color = linear_from_oklab(oklab_c);

	COLOR.rgb = screen_color * gamma_adjust;
}
