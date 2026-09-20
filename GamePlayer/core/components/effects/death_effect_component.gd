class_name DeathEffectComponent
extends Node

## 听谁的死亡；空着会在父节点上找 HealthComponent。
@export var health: HealthComponent
## 死时关掉，避免同一帧再挨打；空着会在父节点上找 Hurtbox。
@export var hurtbox: Hurtbox
## 要拆掉的实体根；空则用场景 owner。
@export var actor: Node
## 特效生成位置；空则用父节点（应挂在会动的身体下）。
@export var host: Node2D
## 死亡动画库，里面可以有多条。
@export var sprite_frames: SpriteFrames
## 这次播哪一条，必须和 sprite_frames 里的动画名一致。
@export var animation: StringName = &"test_death"
## 死亡音效，可空。
@export var death_sound: AudioStream
## 用来量大小的精灵；空着会在 host 下找第一个非影子 Sprite2D。
@export var visual: Node2D
## 相对实体显示尺寸再放大/缩小，1 表示特效框住精灵那么大。
@export var size_multiplier: float = 1.0

@export_group("播放调试")
## 相对宿主的像素偏移，正 Y 向下。
@export var spawn_offset: Vector2 = Vector2.ZERO
## 绘制层级。实体 Y 排序大约 10～99，大于 99 会盖在身上。
@export var fx_z_index: int = 100


func _ready() -> void:
	if health == null:
		health = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	if hurtbox == null:
		hurtbox = get_parent().get_node_or_null("Hurtbox") as Hurtbox
	if host == null:
		host = get_parent() as Node2D
	if actor == null:
		actor = owner
	if visual == null:
		visual = EffectComm.find_visual(host)
	if health == null:
		push_warning("DeathEffectComponent 找不到 HealthComponent：%s" % get_path())
		return
	health.died.connect(_on_died)


## 血空了：关受击、在世界里播选中的死亡动画，再删实体。
func _on_died() -> void:
	if hurtbox != null:
		# 正处在 area_entered 回调里，不能当场改 Area2D，推迟到物理查询结束。
		hurtbox.set_deferred("monitorable", false)
		hurtbox.set_deferred("collision_layer", 0)
	EffectComm.spawn_world_fx(
		actor,
		host,
		visual,
		sprite_frames,
		animation,
		size_multiplier,
		death_sound,
		get_path(),
		spawn_offset,
		fx_z_index
	)
	if actor != null:
		actor.call_deferred("queue_free")
