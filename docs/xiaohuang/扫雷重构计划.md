# 扫雷拆分方案

## 背景

当前扫雷只有一个主文件：

```text
entry/src/main/ets/games/minesweeper/MinesweeperPage.ets
```

这个文件同时承担：

- 页面布局
- 棋盘格子渲染
- 难度配置
- 计时和暂停
- 布雷、翻格、连锁展开
- 胜负结算
- 分数计算
- 后续素材展示

目前文件约 500 行，基础可维护。但随着鸡窝主题、素材、动画和长按插旗接入，继续全部塞在一个页面里会变重。建议后续渐进拆分，不一次性大重构。

## 推荐目录

扫雷专属代码继续放在游戏目录下：

```text
entry/src/main/ets/games/minesweeper/
```

建议拆成：

```text
entry/src/main/ets/games/minesweeper/MinesweeperPage.ets
entry/src/main/ets/games/minesweeper/MinesweeperTypes.ets
entry/src/main/ets/games/minesweeper/MinesweeperRules.ets
entry/src/main/ets/games/minesweeper/MinesweeperTheme.ets
entry/src/main/ets/games/minesweeper/MinesweeperBoard.ets
entry/src/main/ets/games/minesweeper/MinesweeperHud.ets
entry/src/main/ets/games/minesweeper/MinesweeperResultOverlay.ets
```

资源目录保持游戏独立：

```text
entry/src/main/resources/rawfile/games/minesweeper/
```

## 职责拆分

### MinesweeperPage.ets

保留页面级编排：

- 接收 `bestScore`、`exitToHub`、`recordScore`。
- 持有当前游戏状态。
- 组合 HUD、难度栏、棋盘、暂停层、结算层。
- 处理页面生命周期和计时器。

目标：让它像页面容器，而不是所有逻辑的集合。

### MinesweeperTypes.ets

放类型和常量：

- `MineCell`
- `MineDifficulty`
- `MinesweeperStatus`
- `MinesweeperState`
- `DIFFICULTIES`

收益：组件、规则函数、页面都能复用类型，不互相复制。

### MinesweeperRules.ets

放纯游戏规则：

- 初始化空棋盘。
- 首点安全布雷。
- 计算邻居雷数。
- 获取某格邻居。
- 连锁展开空白格。
- 判断胜利。
- 计算剩余雷数。
- 计算当前分数。

要求：尽量写成纯函数，不依赖 ArkUI，不读写页面状态。

收益：规则清楚，后续想加测试也方便。

### MinesweeperTheme.ets

放主题和素材路径：

- 数字低饱和颜色。
- 未打开格子的木板/稻草/蛋壳样式参数。
- 打开格子的浅木板样式参数。
- `bg.png`、`mine_chicken_egg.png`、`flag_chicken_paw.png` 等资源路径常量。
- 文案：`踩到鸡雷了！`、`鸡窝安全！`。

收益：切图和视觉微调集中处理，不用在页面里到处找颜色和资源名。

### MinesweeperBoard.ets

负责棋盘 UI：

- 渲染 `Grid`。
- 渲染单格。
- 根据 cell 状态显示未开格、数字、旗子、鸡雷。
- 处理点击、后续长按插旗。
- 接收 `cellSize`、`cells`、事件回调。

收益：素材接入主要集中在这里。

### MinesweeperHud.ets

负责顶部和操作区：

- 大厅按钮。
- 雷数、计时、最高分。
- 难度切换。
- 排雷/插旗模式。
- 重新开始、暂停。

收益：页面顶部和按钮风格可以单独按参考图打磨。

### MinesweeperResultOverlay.ets

负责结算弹层：

- 胜利文案。
- 失败文案。
- 本局用时、得分、最高分。
- 再来一局、回大厅。
- 鸡毛、嫌弃鸡等素材。

收益：失败/胜利表现可以独立迭代。

## 渐进拆分顺序

不要一口气全拆。建议按开发收益排序：

1. 先抽 `MinesweeperTheme.ets`。
   - 立刻服务素材接入和颜色调整。
   - 风险低。

2. 再抽 `MinesweeperTypes.ets`。
   - 给后续组件和规则函数共用。
   - 基本不改变行为。

3. 抽 `MinesweeperBoard.ets`。
   - 这是后续切图最重要的地方。
   - 鸡雷、旗子、格子样式都集中到棋盘组件。

4. 抽 `MinesweeperResultOverlay.ets`。
   - 等鸡毛、嫌弃鸡素材到位后做。

5. 最后抽 `MinesweeperRules.ets`。
   - 规则已经能跑，先不急着动。
   - 等 UI 稳定后再把纯逻辑搬出去，减少同时变更多带来的风险。

## 不建议现在做的事

- 不建议直接把所有内容一次性拆完。
- 不建议先引入游戏引擎。
- 不建议把所有格子都做成图片背景。
- 不建议把不同游戏的素材混放。
- 不建议在拆分时同时大改规则和 UI。

## 素材接入原则

- 背景、鸡雷、旗子、鸡毛、结算鸡图使用图片资源。
- 棋盘格子优先用代码样式模拟木板/稻草质感，等小屏效果确认后再决定是否使用格子贴图。
- 图片文件统一小写英文、数字、下划线。
- 扫雷素材统一放：

```text
entry/src/main/resources/rawfile/games/minesweeper/
```

## 当前建议

下一步先不要急着大拆。更稳的路线是：

1. 接完背景图。
2. 抽 `MinesweeperTheme.ets` 管颜色、文案、资源路径。
3. 改 `CellView()` 让棋盘风格接近参考图。
4. 等鸡雷和旗子素材到位后，再抽 `MinesweeperBoard.ets` 并接图片。
