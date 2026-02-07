/*
by Cam
*/

shader_type canvas_item;

uniform float height : hint_range(0.0, 100.0) = 50.;
uniform float speed : hint_range(0.0, 5.0) = 1.0;

void vertex() {
	VERTEX += vec2(0, height * sin(TIME * speed));
}