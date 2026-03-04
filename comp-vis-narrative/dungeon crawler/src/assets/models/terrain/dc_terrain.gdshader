// 2022 Kasper Arnklit Frandsen - Public Domain - No Rights Reserved

// https://godotshaders.com/shader/surface-contour-lines/

shader_type spatial;

uniform float offset : hint_range(-1.0, 1.0) = 0.5;
uniform float fade : hint_range(0.0, 1.0) = 0.1;

uniform vec3 uv_scale_fg = vec3(1.0);
uniform vec3 uv_scale_bg = vec3(1.0);

uniform sampler2D albedo_texture_fg : hint_default_white;
uniform sampler2D orm_texture_fg : hint_default_white;
uniform sampler2D normal_texture_fg : hint_normal;

uniform sampler2D albedo_texture_bg : hint_default_white;
uniform sampler2D orm_texture_bg : hint_default_white;
uniform sampler2D normal_texture_bg : hint_normal;

uniform float line_thickness : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float line_interval : hint_range(0.01, 100.0, 0.01) = 0.1;
uniform vec3 line_color : source_color = vec3(0.9, 0.9, 0.9);

const uint terrain_layer_mask = 1u; // Bitmask must include the primary target render layer.
const uint map_layer_mask = 2u; // Bitmask must match the cull mask used for MaskCamera.

vec3 fractal_contour_lines(float thickness, float interval, vec3 world_pos, vec3 camera_position, vec3 base_ddx, vec3 base_ddy) {
	float depth = max(log(length(world_pos - camera_position) / interval) * (1.0 / log2(2.0)) - 1.0, 1.0);

	float interval_a = interval * exp2(max(floor(depth) - 1.0, 1.0)) * 0.5;
	float interval_b = interval * exp2(max(floor(depth), 1.0)) * 0.5;
	float interval_c = interval * exp2(max(floor(depth + 0.5) - 1.0, 1.0)) * 0.5;

	vec3 y = world_pos;
	vec3 y_fwidth = abs(base_ddx) + abs(base_ddy);

	float mi = max(0.0, thickness - 1.0);
	float ma = max(1.0, thickness);
	float mx = max(0.0, 1.0 - thickness);

	// Line A
	float inv_interval_a = 1.0 / interval_a;
	vec3 f_a = abs(fract((y + interval_a * 0.5) * inv_interval_a) - 0.5);
	vec3 df_a = y_fwidth * inv_interval_a;
	vec3 line_a = clamp((f_a - df_a * mi) / (df_a * (ma - mi)), mx, 1.0);

	// Line B
	float inv_interval_b = 1.0 / interval_b;
	vec3 f_b = abs(fract((y + interval_b * 0.5) * inv_interval_b) - 0.5);
	vec3 df_b = y_fwidth * inv_interval_b;
	vec3 line_b = clamp((f_b - df_b * mi) / (df_b * (ma - mi)), mx, 1.0);

	// Line C
	float inv_interval_c = 1.0 / interval_c;
	vec3 f_c = abs(fract((y + interval_c * 0.5) * inv_interval_c) - 0.5);
	vec3 df_c = y_fwidth * inv_interval_c;
	vec3 line_c = clamp((f_c - df_c * mi) / (df_c * (ma - mi)), mx, 1.0);

	// Blend out
	float p = fract(depth - 0.5);
	vec3 line = mix(mix(line_a, line_b, fract(depth)), line_c, (4.0 * p * (1.0 - p)));
	return 1.0 - vec3(line);
}

void fragment() {
	uint visible_layers = CAMERA_VISIBLE_LAYERS;
	if (! ((visible_layers & map_layer_mask) == map_layer_mask) ) {
		// the minimap shader goes here
		vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
		vec3 ddx = dFdx(world_pos);
		vec3 ddy = dFdy(world_pos);
		vec3 world_normal = normalize(cross(ddy, ddx));
		vec3 line = fractal_contour_lines(line_thickness, line_interval, world_pos, CAMERA_POSITION_WORLD, ddx, ddy);
		
		// Y only
		ALBEDO = mix(vec3(0.1), line_color, clamp(line.y, 0., 1.));
		// XYZ
		//ALBEDO = mix(vec3(0.1), line_color, clamp(line.x + line.y + line.z, 0., 1.));
		
		//ALBEDO = vec3(0., 0., 1.);
		ALBEDO *= vec3(0.1, 0.7, 0.1);
		
		
	} 
	else {
		// WORLD NORMAL MIX SHADER
		// This shader can  be used to mix two PBR materials based on a world normal. This is useful for
		// effects such as snow on top of an object, or grass growing on top of an object.

		// COMMENTS:
		// LINE 43 - We unpack the background normal map.
		// LINE 44 - Recalculate z-component of the normal map with the Pythagorean theorem.
		// LINE 45 - Apply the tangent-space normal map to the view-space normals.
		// LINE 46 - Convert the world up vector into view-space with a matrix multiplication.
		// LINE 47 - Compare the up vector to the surface with the normal map applied using the dot product.
		// LINE 48 - Remap the dot-product to a clamped mask using the smoothstep function.
		// LINE 50 - Mix the various textures and apply them, using the mask.
		
		// normal terrain shader goes here
		vec2 fg_uv = UV * uv_scale_fg.xy;
		vec2 bg_uv = UV * uv_scale_bg.xy;
		vec3 albedo_tex_fg = texture(albedo_texture_fg, fg_uv).rgb;
		vec3 orm_tex_fg = texture(orm_texture_fg, fg_uv).rgb;
		vec3 normal_tex_fg = texture(normal_texture_fg, fg_uv).rgb;
		
		vec3 albedo_tex_bg = texture(albedo_texture_bg, bg_uv).rgb;
		vec3 orm_tex_bg = texture(orm_texture_bg, bg_uv).rgb;
		vec3 normal_tex_bg = texture(normal_texture_bg, bg_uv).rgb;
		
		vec3 bg_normal = normal_tex_bg * 2.0 - 1.0;
		bg_normal.z = sqrt(1.0 - bg_normal.x * bg_normal.x - bg_normal.y * bg_normal.y);
		vec3 normal_applied = bg_normal.x * TANGENT + bg_normal.y * BINORMAL + bg_normal.z * NORMAL;
		vec3 up_vector_viewspace = mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0);
		float dot_product = dot(up_vector_viewspace, normal_applied);
		float mask = smoothstep(offset - fade, offset + fade, dot_product);

		ALBEDO = mix(albedo_tex_bg, albedo_tex_fg, mask);
		vec3 mixed_orm = mix(orm_tex_bg, orm_tex_fg, mask);
		AO = mixed_orm.r;
		ROUGHNESS = mixed_orm.g;
		METALLIC = mixed_orm.b;
		NORMAL_MAP = mix(normal_tex_bg, normal_tex_fg, mask);
	}
}

