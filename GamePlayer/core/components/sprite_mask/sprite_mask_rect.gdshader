shader_type canvas_item;

// 关闭时整张图照常画。
uniform bool mask_enabled = false;
// 把精灵局部像素变到遮罩父节点的局部坐标。
uniform vec2 to_parent_x = vec2(1.0, 0.0);
uniform vec2 to_parent_y = vec2(0.0, 1.0);
uniform vec2 to_parent_origin = vec2(0.0);
// 矩形在父节点局部坐标里的左上角和尺寸。右下角是开区间。
uniform vec2 mask_pos = vec2(0.0);
uniform vec2 mask_size = vec2(0.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 parent_pos = to_parent_x * local_pos.x + to_parent_y * local_pos.y + to_parent_origin;
	vec2 delta = parent_pos - mask_pos;
	if (mask_enabled
			&& delta.x >= 0.0 && delta.y >= 0.0
			&& delta.x < mask_size.x && delta.y < mask_size.y) {
		discard;
	}
	COLOR = texture(TEXTURE, UV) * COLOR;
}