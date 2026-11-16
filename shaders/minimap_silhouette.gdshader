shader_type canvas_item;

void fragment() {
	float texture_alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(COLOR.rgb, COLOR.a * texture_alpha);
}
