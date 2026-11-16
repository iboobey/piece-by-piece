shader_type canvas_item;

uniform vec4 silhouette_color : source_color = vec4(1.0);

void fragment() {
	float texture_alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(silhouette_color.rgb, silhouette_color.a * texture_alpha);
}
