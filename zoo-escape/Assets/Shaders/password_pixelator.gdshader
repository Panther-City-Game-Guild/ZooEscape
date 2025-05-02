shader_type canvas_item;
uniform float amount: hint_range(1.0, 640.0, 1.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment()
{
	vec2 amt = 1.0 / amount / SCREEN_PIXEL_SIZE;
	vec2 uv = round(SCREEN_UV * amt) / amt;
	vec4 c = textureLod(SCREEN_TEXTURE, uv, 0);

	COLOR = c;
}