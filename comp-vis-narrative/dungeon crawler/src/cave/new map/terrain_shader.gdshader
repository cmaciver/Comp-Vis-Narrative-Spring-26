shader_type spatial;
render_mode ambient_light_disabled;

uniform sampler2D grass_texture;
uniform sampler2D rock_texture;
uniform sampler2D sand_texture;
uniform sampler2D grass_normalmap;
uniform sampler2D rock_normalmap;
uniform sampler2D sand_normalmap;

uniform float min_rock_slope:hint_range(0.f,1.f) = 0.5;
uniform float max_grass_slope:hint_range(0.f,1.f) = 0.9;
uniform float min_rockgrass_height = -8.f;
uniform float max_sand_height = -6.f;

varying float normal_y;
varying float vertex_y;

void vertex(){
	normal_y = NORMAL.y;
	vertex_y = VERTEX.y;
}

void fragment() {
	// Albedo Values
	vec3 grass_albedo = texture(grass_texture,UV*4.f).xyz;
	vec3 rock_albedo = texture(rock_texture,UV*4.f).xyz;
	vec3 sand_albedo = texture(sand_texture,UV*4.f).xyz;

	// Normal Values
	vec3 grass_normal = texture(grass_normalmap,UV*4.f).xyz;
	vec3 rock_normal = texture(rock_normalmap,UV*4.f).xyz;
	vec3 sand_normal = texture(sand_normalmap,UV*4.f).xyz;

	// Calculating Rock/Grass Weight
	float rock_grass_weight = min(max_grass_slope, max(min_rock_slope, normal_y)) - min_rock_slope;
	rock_grass_weight /= max_grass_slope - min_rock_slope;

	//Calculating Sand/RockGrass Weight
	float sand_rockgrass_weight = min(max_sand_height, max(min_rockgrass_height, vertex_y)) - min_rockgrass_height;
	sand_rockgrass_weight /= max_sand_height - min_rockgrass_height;

	//Mixing and Assigning Albedo
	vec3 rockgrass_albedo = mix(rock_albedo, grass_albedo, rock_grass_weight);
	vec3 rockgrass_normal = mix(rock_normal, grass_normal, rock_grass_weight);
	ALBEDO = mix(sand_albedo, rockgrass_albedo, sand_rockgrass_weight);
	NORMAL_MAP = mix(sand_normal, rockgrass_normal, sand_rockgrass_weight);
	
	ALBEDO = rockgrass_albedo;
	NORMAL_MAP = rockgrass_normal;
}