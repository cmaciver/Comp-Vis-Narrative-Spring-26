shader_type canvas_item;

uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float active = 0.0;
uniform float bar_width = 1000.0;
uniform float frequency = 20.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    
    float pos = (SCREEN_UV.x * frequency) + TIME * speed;
    
    // Posterize the position to make distinct color bands
    float steps = 6.0; // number of distinct colors, increase for more
    pos = floor(pos * steps) / steps;
    
    vec3 color = vec3(
        sin(pos * 6.28) * 0.5 + 0.5,
        sin(pos * 6.28 + 2.09) * 0.5 + 0.5,
        sin(pos * 6.28 + 4.18) * 0.5 + 0.5
    );
    vec4 rainbowColor = vec4(color, original.a);
    COLOR = mix(original, rainbowColor, active);
}