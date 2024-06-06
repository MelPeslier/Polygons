shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	float pct = 1.0 - pow(uv.y, 2.0);
	COLOR.rgb = vec3(pct);
	COLOR.a = 1.0;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
