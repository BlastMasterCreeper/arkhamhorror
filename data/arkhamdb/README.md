# ArkhamDB JSON 卡牌数据（本地镜像）

本目录存放 [arkhamdb-json-data](https://github.com/Kamalisk/arkhamdb-json-data) 的**子集**，供规则引擎设计对照与离线分析。完整 upstream 路径见 [`SOURCE.txt`](SOURCE.txt)。

## 目录结构

| 路径 | 内容 |
|---|---|
| `schema/` | JSON Schema（`card_schema.json` 等） |
| `index/` | `types.json`、`packs.json`、`factions.json`、`cycles.json`、`subtypes.json`、`encounters.json` |
| `pack/<cycle>/` | 各扩展英文卡表（当前仅 **Core 2026**） |
| `translations/zh-cn/pack/` | 中文卡名/文本（可选，与英文 `code` 对齐） |
| `reports/` | `tools/analyze_arkhamdb_cards.py` 生成的分析报告 |

## 同步更多扩展

```powershell
# 从本机 upstream 复制单个 pack（示例：Dunwich 第一章）
$src = "C:\Users\12162\Documents\arkhamdb-json-data-master\arkhamdb-json-data-master"
Copy-Item "$src\pack\dwl\tmm.json" "data\arkhamdb\pack\dwl\" -Force
```

或使用 `tools/sync_arkhamdb_data.ps1`（请在**本机终端**自行运行；Agent 勿代跑脚本安装类命令，见 [`docs/setup-local-tools.md`](../../docs/setup-local-tools.md)）。

## 分析

需先**手动安装 Python**（[python.org](https://www.python.org/downloads/)，勾选 **Add to PATH**）。详见 [`docs/setup-local-tools.md`](../../docs/setup-local-tools.md)。

```powershell
python --version
python tools/analyze_arkhamdb_cards.py
```

输出写入 `reports/`。设计文档：[`docs/design/18-arkhamdb-card-data.md`](../../docs/design/18-arkhamdb-card-data.md)。

## 与引擎的对应关系

ArkhamDB 字段 → 引擎 `CardDefinition` / `CardRegistry` 映射见设计文档 **§3**。  
**裁定与行为**仍以 Grimoire / 本仓库 `docs/design/` 为准；JSON 仅提供卡面文本与结构化数值。
