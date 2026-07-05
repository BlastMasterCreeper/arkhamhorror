# Windows 本地工具（Python 等）

> **给 Agent**：本机杀毒软件会拦截 `winget install`、下载 `.exe` 安装包、`-ExecutionPolicy Bypass` 等命令。  
> **请勿**代用户执行安装器；只运行已存在的 `python` / `godot`，或提示用户按本文手动安装。

---

## Python（卡牌分析脚本）

### 手动安装（推荐，不易被 AV 误报）

1. 打开 [python.org/downloads](https://www.python.org/downloads/)（或 [Python 3.12 直链](https://www.python.org/downloads/release/python-31210/)）。
2. 下载 **Windows installer (64-bit)**。
3. 运行安装程序，**勾选**：
   - **Add python.exe to PATH**
   - （可选）Install for all users
4. 安装完成后 **新开** PowerShell / Cursor 终端。
5. 验证：

```powershell
python --version
python tools/analyze_arkhamdb_cards.py
```

### Cursor / VS Code 解释器

安装后：`Ctrl+Shift+P` → **Python: Select Interpreter** → 选 `Python 3.x.x ('python.exe')`。

`.vscode/settings.json` 中的 `python.defaultInterpreterPath` 可按本机路径填写；勿提交含绝对用户路径的配置（见 `.vscode/settings.json.example`）。

### 无 Python 时的备选

仅分析 ArkhamDB 卡表、不跑 `.py` 时，可用只读复制 + 内置统计（不修改 ExecutionPolicy）：

```powershell
# 复制 pack（示例）
Copy-Item "C:\path\to\arkhamdb-json-data\pack\core\core_2026.json" "data\arkhamdb\pack\core\" -Force
```

卡牌 JSON 为纯数据；分析报告可让用户本地跑 `python tools/analyze_arkhamdb_cards.py` 后提交 `data/arkhamdb/reports/`。

---

## Godot（规则引擎测试）

见根目录 [`README.md`](../README.md) / [`AGENTS.md`](../AGENTS.md)。Windows 使用本机 Godot 4.6.3：

```powershell
.\run_tests.ps1
```

---

## ArkhamDB 数据同步

upstream 仓库已在本地时，**手动 `Copy-Item`** 即可；避免 Agent 从网络拉取大型 zip。

```powershell
$src = "C:\Users\12162\Documents\arkhamdb-json-data-master\arkhamdb-json-data-master"
Copy-Item "$src\pack\core\core_2026.json" "data\arkhamdb\pack\core\" -Force
```

`tools/sync_arkhamdb_data.ps1` 仅做文件复制，可在用户终端自行运行；Agent 优先用 `Copy-Item` 单条命令。

---

## Agent 允许 / 禁止命令（Windows）

| 允许 | 禁止（易触发 AV / 需人工） |
|---|---|
| `python tools/*.py`（PATH 已有 python） | `winget install` / `choco install` |
| `godot --headless ...` | 下载并执行 `.exe` 安装包 |
| `Copy-Item` 复制 JSON / 文档 | `Set-ExecutionPolicy`、`-ExecutionPolicy Bypass` |
| `git status` / `git diff` | 修改系统 PATH / 注册表 |

若 `python` 不可用，**说明手动安装步骤**（本文 §Python），不要自动安装。
