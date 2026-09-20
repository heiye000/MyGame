class_name EffectComm
extends Object

## 渲染层 WorldFX。
const WORLD_FX_LAYER := 512
## 未指定时叠在实体 Y 排序之上（实体 z 大约 10～99）。
const DEFAULT_FX_Z_INDEX := 100


## 在宿主下面找身体精灵，跳过名字带 Shadow 的影子。
static func find_visual(host: Node2D) -> Node2D:
	if host == null:
		return null
	for child in host.get_children():
		if child is Sprite2D and not String(child.name).contains("Shadow"):
			return child as Node2D
		if child is AnimatedSprite2D:
			return child as Node2D
	return host


## 在实体所在世界里播一条一次性动画；播完自己删。sound 可空。
static func spawn_world_fx(
	actor: Node,
	host: Node2D,
	visual: Node2D,
	sprite_frames: SpriteFrames,
	animation: StringName,
	size_multiplier: float,
	sound: AudioStream = null,
	warn_from: String = "",
	spawn_offset: Vector2 = Vector2.ZERO,
	fx_z_index: int = DEFAULT_FX_Z_INDEX
) -> AnimatedSprite2D:
	if sprite_frames == null or actor == null:
		push_warning("EffectComm 缺少 sprite_frames 或 actor：%s" % warn_from)
		return null
	if not sprite_frames.has_animation(animation):
		push_warning("EffectComm 没有动画「%s」：%s" % [animation, warn_from])
		return null
	var world := actor.get_parent()
	if world == null:
		return null
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = sprite_frames
	fx.visibility_layer = WORLD_FX_LAYER
	# 不跟脚底 Y 排序抢 z；具体数值由组件面板传入。
	fx.z_as_relative = false
	fx.z_index = fx_z_index
	world.add_child(fx)
	if host != null:
		fx.global_position = host.global_position + spawn_offset
	else:
		fx.global_position = spawn_offset
	fx.scale = scale_to_match_visual(fx, visual, animation, size_multiplier)
	# AnimatedSprite2D 的 animation_finished 没有参数。
	fx.animation_finished.connect(fx.queue_free)
	fx.play(animation)
	if sound != null:
		var audio := AudioStreamPlayer.new()
		audio.stream = sound
		fx.add_child(audio)
		audio.play()
	return fx


## 让特效屏幕大小对齐实体精灵，再用 size_multiplier 缩放。
static func scale_to_match_visual(
	fx: AnimatedSprite2D,
	visual: Node2D,
	animation: StringName,
	size_multiplier: float
) -> Vector2:
	if visual == null:
		return Vector2.ONE * size_multiplier
	var entity_size := visual_display_size(visual)
	var fx_size := fx_frame_size(fx, animation)
	if entity_size.x <= 0.001 or entity_size.y <= 0.001:
		return visual.global_scale.abs() * size_multiplier
	if fx_size.x <= 0.001 or fx_size.y <= 0.001:
		return visual.global_scale.abs() * size_multiplier
	return Vector2(entity_size.x / fx_size.x, entity_size.y / fx_size.y) * size_multiplier


## 精灵当前帧在世界里占多少像素。
static func visual_display_size(node: Node2D) -> Vector2:
	var sprite := node as Sprite2D
	if sprite != null:
		return sprite.get_rect().size * sprite.global_scale.abs()
	var animated := node as AnimatedSprite2D
	if animated != null and animated.sprite_frames != null:
		var tex := animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
		if tex != null:
			return tex.get_size() * animated.global_scale.abs()
	return Vector2.ZERO


## 特效指定动画第 0 帧的原始像素大小。
static func fx_frame_size(fx: AnimatedSprite2D, animation: StringName) -> Vector2:
	if fx.sprite_frames == null:
		return Vector2.ZERO
	var tex := fx.sprite_frames.get_frame_texture(animation, 0)
	if tex == null:
		return Vector2.ZERO
	return tex.get_size()
