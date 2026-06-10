# xiaohuang 协作开发文档

本目录用于沉淀 xiaohuang 小组在《鸡窝游戏》中的开发方案、玩法设计、验收记录和 PR 说明草稿。

## 负责范围

- `minesweeper`：扫雷，重点是插旗/翻格手感、难度档位、美术统一和小屏布局。
- `eggSling`：弹射鸡蛋，重点是拖拽弹弓手感、关卡目标、命中反馈和结算节奏。

代码位置：

- `entry/src/main/ets/games/minesweeper/MinesweeperPage.ets`
- `entry/src/main/ets/games/eggSling/EggSlingPage.ets`

## 推荐协作方式

采用「按游戏拆分 feature 分支，小步 PR 合并」。

- `main` 保持可构建、可安装。
- 扫雷使用 `feature/xiaohuang-minesweeper`。
- 弹射鸡蛋使用 `feature/xiaohuang-egg-sling`。
- 如果有两个游戏共用的 UI、工具函数或存档改动，单独开 `feature/xiaohuang-shared-game-polish`，先合并共享改动，再分别 rebase 两个游戏分支。
- 每个 PR 只覆盖一个明确目标，避免扫雷和弹射鸡蛋互相阻塞。

不建议直接在 `main` 上持续开发后一次性提交 PR。这样冲突、回滚和验收都会变重，也不方便其他协作者提前 review。

## PR 节奏

建议每个游戏拆成 2 到 3 个小 PR：

1. 玩法和状态修复：规则、计分、失败/胜利、暂停/重开。
2. 操作手感：点击、拖拽、长按、误触反馈。
3. 视觉和验收：布局、美术统一、小屏检查、真机记录。

每个 PR 合并前至少确认：

- `./scripts/build-app.sh --stacktrace` 构建通过。
- 从大厅进入和返回正常。
- 暂停、重开、结算正常。
- 最高分能更新。
- 小屏无明显重叠或遮挡系统手势条。

## 文档计划

- `minesweeper-plan.md`：扫雷玩法和优化计划。
- `minesweeper-result-popup-design.md`：扫雷胜负弹窗和羽毛动效设计。
- `minesweeper-scoring-design.md`：扫雷固定难度后的计分和最高分规则。
- `egg-sling-plan.md`：弹射鸡蛋玩法和优化计划。
- `qa-notes.md`：真机验证记录、截图说明和遗留问题。
