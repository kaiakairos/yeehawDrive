shader_type canvas_item;

uniform int gridSizex;
uniform int gridSizey;
varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	int gridX = int(world_pos.x) / gridSizex;
	int gridY = int(world_pos.y) / gridSizey;
	
	if(abs(gridX) % 2 == abs(gridY) % 2){
		COLOR.rgb = vec3(0.0);
		
	}
	COLOR.a = 0.1;
}
