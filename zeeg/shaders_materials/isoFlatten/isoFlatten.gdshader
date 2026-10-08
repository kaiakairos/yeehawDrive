shader_type canvas_item;

uniform float flatten;

vec2 rotate_vector(vec2 v, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

void vertex() {
	VERTEX *= vec2(0.6484);
	VERTEX = rotate_vector(VERTEX,PI*0.25);
	VERTEX.y *= flatten;
}

void fragment() {
	// Called for every pixel the material is visible on.
}
