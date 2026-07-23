## 八方向工具：向量与方向名互转，供移动/动画/攻击共用。
## 命名冻结为 up / up_right / right / down_right / down / down_left / left / up_left。
class_name Direction8
extends RefCounted

## 八向枚举（与项目约定一一对应）。
enum Dir {
	UP,
	UP_RIGHT,
	RIGHT,
	DOWN_RIGHT,
	DOWN,
	DOWN_LEFT,
	LEFT,
	UP_LEFT,
}

## 枚举 → 方向名（用于拼动画：idle_up、walk_up_right）。
const NAMES: Dictionary = {
	Dir.UP: &"up",
	Dir.UP_RIGHT: &"up_right",
	Dir.RIGHT: &"right",
	Dir.DOWN_RIGHT: &"down_right",
	Dir.DOWN: &"down",
	Dir.DOWN_LEFT: &"down_left",
	Dir.LEFT: &"left",
	Dir.UP_LEFT: &"up_left",
}

## 方向名 → 枚举（反向查找）。
const NAME_TO_DIR: Dictionary = {
	&"up": Dir.UP,
	&"up_right": Dir.UP_RIGHT,
	&"right": Dir.RIGHT,
	&"down_right": Dir.DOWN_RIGHT,
	&"down": Dir.DOWN,
	&"down_left": Dir.DOWN_LEFT,
	&"left": Dir.LEFT,
	&"up_left": Dir.UP_LEFT,
}

## 1/sqrt(2)，斜向单位向量分量（const 里不能调用 normalized()）。
const _S2: float = 0.7071067811865476

## 枚举 → 单位向量（y 向下为正）。
const VECTORS: Dictionary = {
	Dir.UP: Vector2(0, -1),
	Dir.UP_RIGHT: Vector2(_S2, -_S2),
	Dir.RIGHT: Vector2(1, 0),
	Dir.DOWN_RIGHT: Vector2(_S2, _S2),
	Dir.DOWN: Vector2(0, 1),
	Dir.DOWN_LEFT: Vector2(-_S2, _S2),
	Dir.LEFT: Vector2(-1, 0),
	Dir.UP_LEFT: Vector2(-_S2, -_S2),
}

## 扇区中心角度（atan2：x 右、y 下），每 45° 一格，从 UP 起逆时针按枚举序。
## 实际判定用角度 / 45 量化，见 from_vector。


## 向量转八向。零向量回退为 fallback（默认 down）。
static func from_vector(v: Vector2, fallback: Dir = Dir.DOWN) -> Dir:
	if v.length_squared() < 0.0001:
		return fallback
	# atan2(y, x)：右=0，顺时针为正（因 y 向下）。
	var angle := atan2(v.y, v.x)
	# 把「右」对齐到扇区中心：加 22.5° 再按 45° 量化。
	var sector := int(floor((angle + PI / 8.0) / (PI / 4.0))) % 8
	if sector < 0:
		sector += 8
	# sector: 0=右, 1=右下, 2=下, 3=左下, 4=左, 5=左上, 6=上, 7=右上
	match sector:
		0:
			return Dir.RIGHT
		1:
			return Dir.DOWN_RIGHT
		2:
			return Dir.DOWN
		3:
			return Dir.DOWN_LEFT
		4:
			return Dir.LEFT
		5:
			return Dir.UP_LEFT
		6:
			return Dir.UP
		7:
			return Dir.UP_RIGHT
		_:
			return fallback


## 八向转单位向量。
static func to_vector(dir: Dir) -> Vector2:
	return VECTORS.get(dir, Vector2.DOWN)


## 八向转 StringName（拼动画名用）。
static func to_string_name(dir: Dir) -> StringName:
	return NAMES.get(dir, &"down")


## StringName / String 转八向；无法识别时回退 fallback。
static func from_string_name(name: StringName, fallback: Dir = Dir.DOWN) -> Dir:
	return NAME_TO_DIR.get(name, fallback)


## 拼动画名：如 anim_name("idle", Dir.UP_RIGHT) -> &"idle_up_right"。
static func anim_name(state: StringName, dir: Dir) -> StringName:
	return StringName("%s_%s" % [state, to_string_name(dir)])
