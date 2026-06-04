extends StateMachine

# 第6.2节 转换仲裁硬规则（每帧按顺序检查，先命中先执行）
# 1. 死亡条件（HP <= 0）→ DieState
# 2. 全局强制中断（被投技）→ GrabbedState
# 3. 硬直/受击条件 → HurtState
# 4. 玩家输入 -> 各种主动状态
# 5. 环境物理/地面检测 -> Idle / Fall / Jump

func _can_transition(state_name: String, params: Dictionary) -> bool:
	var player: Player = _get_player()
	if not player:
		return true

	# 规则1: 死亡不可打断
	if current_state and current_state.name == "Die":
		return state_name == "Die"

	# 规则2: 投技锁定中只允许自身/Hurt/Idle(挣脱)/Die(死亡)
	if current_state and current_state.name == "Grabbed":
		return state_name in ["Grabbed", "Hurt", "Idle", "Die"]

	# 规则3: 受击硬直中不能主动行动（自然结束的 Idle/Fall 允许通过）
	if current_state and current_state.name == "Hurt":
		return state_name in ["Die", "Grabbed", "Hurt", "Idle", "Fall"]

	# 规则4: 攻击/忍术状态持续中不接受同类型覆盖
	if current_state and current_state.name in ["Attack", "NinjaArt"]:
		if state_name in ["Attack", "NinjaArt"]:
			return false

	# 规则5: 攻击冷却中不能攻击
	if state_name == "Attack" and player.attack_cooldown_timer > 0.0:
		return false

	return true

func _get_player() -> Player:
	var p = owner
	if p is Player:
		return p
	return null
