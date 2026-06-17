# Arkham Horror LCG — Rules Engine



Godot **4.6** 规则引擎骨架，设计文档见 [`docs/`](docs/README.md)。



## 结构



```

core/       Domain：状态、区域、日志、TimingBus

rules/      Rules：Framework、Action、SkillTest、Effect

api/        GameContext 会话上下文

bootstrap/  装配入口（无 Node 依赖）

scripts/    CardScript 基类（待扩展）

tests/      Headless 回归

data/       YAML 卡牌数据（待导入）

```



## Headless 测试



```powershell

.\run_tests.ps1

```



或指定 Godot 路径：



```powershell

$env:GODOT4 = "E:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"

.\run_tests.ps1

```



等价命令：



```powershell

& "E:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe" --headless --path . -s res://tests/run_headless.gd

```



## Git



```powershell
git clone https://github.com/BlastMasterCreeper/arkhamhorror.git
cd arkhamhorror
copy .vscode\settings.json.example .vscode\settings.json   # 按需改 Godot 路径
.\run_tests.ps1
```



本地 IDE：复制 [`.vscode/settings.json.example`](.vscode/settings.json.example) 为 `settings.json`（该文件已被 `.gitignore` 忽略，避免提交本机路径）。



## 实现阶段



- [x] Domain / Rules 骨架 + EventRecord

- [x] Setup 1→14 步进（简化副作用）

- [x] Resource 行动 smoke test

- [x] 完整 Framework 回合循环

- [x] Composition + Registration 薄竖切（C-01～C-04）

- [x] RESTRICTION / LISTENER / Initiation dry-run（C-05～C-08）

- [x] SkillTest ST.1–ST.8 薄竖切（ST-01～ST-08）

- [x] 基础 Investigate / Fight / Evade 行动（ACT-01～ACT-06）

- [x] 基础 Engage 行动（ACT-07～ACT-10）

- [x] AOO 借机攻击 + 基础 Move（AOO-01～03，ACT-11～12）

- [x] Draw 行动 + Duration tick（ACT-13～15，REG-01）

- [x] Nested Sequences + ApplicationContext + ResourceGain（NS-01～06）

- [ ] Core 2026 卡牌 YAML



旧 addon 原型位于 `../Godot Dice Roller/.../arkham_horror_lcg/`（Godot 4.3），**不迁移**，仅作参考。
