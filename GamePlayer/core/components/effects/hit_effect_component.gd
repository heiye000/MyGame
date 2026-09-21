class_name HitEffectComponent
extends Node

## 听谁的扣血；空着会在父节点上找 HealthComponent。
@export var health: HealthComponent
## 要挂到哪颗实体的世界父节点下；空则用场景 owner。
@export var actor: Node
## 火花生成位置；空则用父节点。
@export var host: Node2D
## 受击动画库，里面可以有多条。
@export var sprite_frames: SpriteFrames
## 这次播哪一条，必须和 sprite_frames 里的动画名一致。
@export var animation: StringName = &"test_hit"
## 用来量大小的精灵；空着会在 host 下找第一个非影子 Sprite2D。
@export var visual: Node2D
## 相对实体显示尺寸；火花默认半个身子大。
@export var size_multiplier: float = 0.5
## 打中时的音效，可空。
@export var hit_sound: AudioStream


@export_group("播放调试")
## 相对宿主的像素偏移，正 Y 向下。
@export var spawn_offset: Vector2 = Vector2.ZERO
## 绘制层级。实体 Y 排序大约 10～99，大于 99 会盖在身上。
@export var fx_z_index: int = 100


func _ready() -> void:
	if health == null:
		health = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	if host == null:
		host = get_parent() as Node2D
	if actor == null:
		actor = owner
	if visual == null:
		visual = EffectComm.find_visual(host)
	if health == null:
		push_warning("HitEffectComponent 找不到 HealthComponent：%s" % get_path())
		return
	health.damaged.connect(_on_damaged)


## 每次扣血播一次火花；致死那下也会先走这里，再走 DeathEffectComponent。
func _on_damaged(_remaining: int, _info: DamageInfo) -> void:
	EffectComm.spawn_world_fx(
		actor,
		host,
		visual,
		sprite_frames,
		animation,
		size_multiplier,
		hit_sound,
		get_path(),
		spawn_offset,
		fx_z_index
	)
