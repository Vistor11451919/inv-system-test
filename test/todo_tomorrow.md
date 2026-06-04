# 明天测试计划

## 1. Boss 系统测试

### 阶段转换
- [ ] Boss 生成时是否正确进入 Phase 0？
- [ ] 血量降到阈值以下是否触发阶段转换？
- [ ] 阶段转换时 `speed_multiplier` 和 `attack_rate_multiplier` 是否生效？
- [ ] 阶段转换时 `new_attack_patterns` 是否更新？
- [ ] 弱点元素伤害 1.5x 是否生效？
- [ ] 非弱点元素无加成？

### 竞技场锁定
- [ ] 玩家进入检测范围 → `trigger_arena_lock()`
- [ ] 锁定后碰撞体启用？
- [ ] Boss 死亡后竞技场解锁？

### Boss 状态机
- [ ] Boss 模板使用 Idle/Attack/Hurt/Die 四个状态
- [ ] Boss 没有 Patrol/Chase → `_sm.init("Patrol")` 不会崩溃？
- [ ] Boss 受击 → Hurt → 恢复后 Idle？
- [ ] Boss 死亡 → Die → cleanup？

### 现存 Bug
- [ ] **C1: Boss 伤害反馈循环** — "boss_base.gd:37-38" 伤害翻 3 倍
- [ ] 测试：BossBase.take_damage() 是否调用了两次 super？

---

## 2. 投技系统测试

### GrabbedState
- [ ] 玩家被抓后是否能正常进入 Grabbed 状态？
- [ ] 挣脱后是否能正确回到 Idle？
- [ ] **CR-3: GrabbedState 挣脱后 Idle 转换被仲裁阻断** — `grabbed_state.gd:63` + `player_state_machine.gd:21`

### 玩家被投技命中
- [ ] 敌人使用投技时玩家 Hurtbox 是否响应？
- [ ] 投技伤害是否正常结算？
- [ ] 投技动画是否正常播放？

---

## 3. 整体回归测试

### 敌人基础行为
- [ ] 5 种敌人都能正常生成
- [ ] 各自的行为模式符合配置（Patrol/Chase/Attack/Hurt/Die）

### 伤害系统
- [ ] J 攻击 → Hitbox → 伤害 → HPLabel 更新 ✅（已修复）
- [ ] K 手里剑 → Projectile → 伤害 → HPLabel 更新 ✅（已修复）
- [ ] 暴击是否触发？
- [ ] 元素抗性是否生效？

### 测试命令
```bash
# 运行单元测试
cd "E:/gme/tests/enemy-ai-test"
godot --path "." --headless -s addons/gut/gut_cmdln.gd -gconfig=res://test/gut_config.json

# 运行测试关卡
godot --path "." --editor
# 运行 scenes/test/test_level.tscn
```
