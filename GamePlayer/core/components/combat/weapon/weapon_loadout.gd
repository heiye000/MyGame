## 挂在挂载点下面，把当前姿态要显示的武器部件挂到父节点上。
class_name WeaponLoadout
extends Node

## 当前装备的武器外观。
@export var weapon: WeaponVisualData
## 当前姿态。没有写进部件表的姿态，对应部件不挂。
@export var pose: StringName = &"normal"

var _mount: WeaponMount
var _sprites: Array[Sprite2D] = []


func _ready() -> void:
	_mount = get_parent() as WeaponMount
	# 父节点正在添加子节点，此刻不能再往它身上挂精灵。
	apply_pose.call_deferred(pose)


## 换成这个姿态：先卸下旧精灵，再挂上该姿态要显示的部件。
func apply_pose(next_pose: StringName) -> void:
	pose = next_pose
	_clear_sprites()
	if weapon == null or _mount == null:
		push_warning("WeaponLoadout 缺少武器，或父节点不是挂载点：%s" % get_path())
		return
	for part in weapon.parts:
		if part == null or not part.shows_in_pose(pose):
			continue
		var sprite := Sprite2D.new()
		sprite.name = String(part.part_id)
		sprite.texture = weapon.texture
		sprite.hframes = weapon.hframes
		sprite.vframes = weapon.vframes
		sprite.frame = part.frame
		sprite.centered = true
		sprite.offset = part.offset
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprites.append(sprite)
		_mount.add_child(sprite)
	_mount._apply_depth()


func _clear_sprites() -> void:
	for sprite: Sprite2D in _sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_sprites.clear()
