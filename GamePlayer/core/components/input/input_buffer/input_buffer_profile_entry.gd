## 单条动作的预输入/精确输入配置。
class_name InputBufferProfileEntry
extends Resource

## 缓冲策略：这个键走哪种输入逻辑。
enum BufferPolicy {
	BUFFERABLE,    # 可预输入，recovery 期间按下先存着
	INSTANT_ONLY,  # 只认当帧，不缓存
	WINDOW_GATED,  # 精确输入，要走判定窗口（弹反等）
}

## 精确输入窗口模式：允许多早按下。
enum GateMode {
	STRICT,   # 严格：只在窗口内按才算
	LENIENT,  # 宽松：窗口前提前按也能留着
}

## 对应哪个玩家动作。
@export var action_type: PlayerActionType.Type
## 用哪种缓冲策略。
@export var policy: BufferPolicy = BufferPolicy.BUFFERABLE
## 精确输入时用哪种窗口模式。
@export var gate_mode: GateMode = GateMode.LENIENT

@export_group("帧数配置（手感调参主入口）")
## 普通预输入能存多少物理帧。60fps下的值 
@export var buffer_frames: int = 24
## 宽松弹反：窗口打开前允许提前按多少帧。
@export var pre_buffer_frames: int = 4
## 精确输入判定窗口持续多少帧。
@export var active_window_frames: int = 5

@export_group("秒数备用（只读换算，或覆盖帧数）")
## 勾选后用秒数代替帧数来算缓冲时长。
@export var use_seconds_override: bool = false
## 用秒数指定缓冲时长。
@export var window_sec: float = 0.25
