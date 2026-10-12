## 挂在挂载点下面，把当前姿态要显示的武器部件挂到父节点上。
class_name WeaponLoadout
extends Node

## 当前装备的武器外观。
@export var weapon: WeaponVisualData
## 当前姿态。没有写进部件表的姿态，对应部件不挂。
@export var pose: StringName = &"normal"

var _mount: WeaponMount
var _sprites: Array[Sprite2D] = []


## 角色根上找到的遮罩。矩形和挂载点平级，不跟剑转。
var _mask: SpriteMaskRect
## 缺遮罩时只警告一次，避免换姿态时反复刷。
var _warned_missing_cover := false


func _ready() -> void:
	_mount = get_parent() as WeaponMount
	# 矩形在角色根上，要等整棵树进场后再找。
	_resolve_cover()
	if _mount != null and not _mount.occlusion_changed.is_connected(_on_occlusion_changed):
		_mount.occlusion_changed.connect(_on_occlusion_changed)
	# 父节点正在添加子节点，此刻不能再往它身上挂精灵。
	apply_pose.call_deferred(pose)


## 在挂载点的父节点下找第一个遮罩。不看节点名，找不到就保持空。
func _resolve_cover() -> void:
	if is_instance_valid(_mask) or _mount == null:
		return
	var host := _mount.get_parent()
	if host == null:
		return
	for child in host.get_children():
		var mask := child as SpriteMaskRect
		if mask == null:
			continue
		_mask = mask
		return


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
	_sync_cover()


func _clear_sprites() -> void:
	for sprite: Sprite2D in _sprites:
		if is_instance_valid(_mask):
			_mask.unbind(sprite)
		if is_instance_valid(sprite):
			sprite.queue_free()
	_sprites.clear()


## 只有「身体挡住一块」才挖。其它档关掉洞，精灵留在挂载点上。
func _sync_cover() -> void:
	if _mount == null:
		return
	_resolve_cover()
	var use_cover := _mount.occlusion == WeaponMount.Occlusion.BODY_COVERS_RECT
	if use_cover and not is_instance_valid(_mask):
		if not _warned_missing_cover:
			_warned_missing_cover = true
			push_warning("WeaponLoadout 遮挡档是身体挡住一块，但角色上没有遮罩：%s" % name)
		return
	if not is_instance_valid(_mask):
		return
	_warned_missing_cover = false
	for sprite in _sprites:
		if use_cover:
			_mask.bind(sprite)
		else:
			_mask.unbind(sprite)


## 挂载点换遮挡档时，按新档重绑已经挂着的精灵。
func _on_occlusion_changed(_next: WeaponMount.Occlusion) -> void:
	_sync_cover()
