@tool
class_name AttackLeft1
extends SlashSwing

# 刀光动画的镜像映射
const _MIRROR_FROM := {
	&"right": &"left",
	&"down_right": &"down_left",
	&"up_right": &"up_left",
}


## 按八向名播放。朝右的三个方向翻 Body，不另做动画。
func play_direction(direction_name: StringName) -> void:
	var body := get_node_or_null("Body") as Node2D
	var player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if body == null or player == null:
		return
	var mirrored := _MIRROR_FROM.has(direction_name)
	var anim: StringName = _MIRROR_FROM.get(direction_name, direction_name)
	# 镜像翻转
	body.scale.x = -1.0 if mirrored else 1.0
	# 播放动画
	player.play(anim)
