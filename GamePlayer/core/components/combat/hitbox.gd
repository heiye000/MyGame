class_name Hitbox
extends Area2D
## 攻击多边形；动画会改点，空数组表示这一帧没有刀。
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D

## 这一刀已经打过的 Hurtbox 实例 ID，防止同一段 active 重复扣血。
var _hit_ids_this_swing: Dictionary = {}
## 上一帧是不是已经开着刀，用来检测「刚挥出」这一下。
var _was_active: bool = false

## 缓存发出方属性，避免每次命中都往上爬树。
var _stats: StatsComponent

## 刀刚挥出时播；砍空也响。
@export var swing_sound: AudioStream

## 这刀可以被格挡。关掉就是打不破的攻击。
@export var can_be_blocked: bool = true
## 这刀可以被精确弹反。关掉则对方就算弹反成功也接不住。
@export var can_be_perfect_parried: bool = true



func _ready() -> void:
	# 我们主动去扫 Hurtbox，自己不必被别人扫到。
	monitorable = false
	monitoring = false
	# 不再永久关掉形状，改由有没有多边形决定这一帧能不能打中。
	collision_polygon.disabled = false
	_stats = _find_stats()
	if _stats == null:
		push_warning("Hitbox 往上找不到 StatsComponent：%s" % get_path())
	area_entered.connect(_on_area_entered)


## 从自己往父节点爬，谁有 StatsComponent 谁就是发出方。
func _find_stats() -> StatsComponent:
	var node: Node = self
	while node != null:
		var stats := node.get_node_or_null("StatsComponent") as StatsComponent
		if stats != null:
			return stats
		node = node.get_parent()
	return null


## 每物理帧跟动画对齐：有面就开检测，空了就关。
func _physics_process(_delta: float) -> void:
	var has_hit_shape := collision_polygon.polygon.size() >= 3
	# 刀刚挥出来：新的一刀开始，旧名单清掉，播挥砍声。
	if has_hit_shape and not _was_active:
		_hit_ids_this_swing.clear()
		_play_swing_sound()
	_was_active = has_hit_shape
	collision_polygon.disabled = not has_hit_shape
	monitoring = has_hit_shape

	
## 碰到 Area 时：只处理 Hurtbox；伤害数字向发出方取，不自己改血。
func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null:
		return
	if _stats == null:
		return
	var hurt_id := hurtbox.get_instance_id()
	# 这一刀已经打过它，忽略后续变形带来的重复进入。
	if _hit_ids_this_swing.has(hurt_id):
		return
	_hit_ids_this_swing[hurt_id] = true
	var source := _stats.get_parent() as Node2D
	var info := DamageInfo.make(_stats, source, self)
	hurtbox.receive_hit(info)


## 挥砍声挂在世界根上，避免跟 Hitbox 开关搅在一起。
func _play_swing_sound() -> void:
	if swing_sound == null:
		return
	var audio := AudioStreamPlayer.new()
	audio.stream = swing_sound
	# 播完自己删，不必占玩家节点。
	audio.finished.connect(audio.queue_free)
	get_tree().root.add_child(audio)
	audio.play()
