shader_type canvas_item;

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	COLOR = vec4(vec3(1.0), COLOR.a * texel.a);
}
