shader_type canvas_item;

// 遮挡框相对挂载点的位置、旋转（弧度）和缩放。矩形本身在遮挡框的局部坐标里。
uniform vec2 cover_origin = vec2(0.0);
uniform float cover_rotation = 0.0;
uniform vec2 cover_scale = vec2(1.0);
// 矩形左上角和宽高，像素，y 向下。落在矩形里的剑像素不画。
uniform vec2 cover_position = vec2(0.0);
uniform vec2 cover_size = vec2(0.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 from_origin = local_pos - cover_origin;
	float c = cos(cover_rotation);
	float s = sin(cover_rotation);
	vec2 unrotated = vec2(from_origin.x * c + from_origin.y * s, -from_origin.x * s + from_origin.y * c);
	vec2 local = unrotated / max(cover_scale, vec2(0.0001));
	vec2 cover_end = cover_position + cover_size;
	if (local.x >= cover_position.x && local.x <= cover_end.x && local.y >= cover_position.y && local.y <= cover_end.y) {
		discard;
	}
}
