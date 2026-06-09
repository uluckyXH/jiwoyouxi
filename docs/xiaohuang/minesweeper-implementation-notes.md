# 扫雷实现现状

## 当前阶段

扫雷目前是基础可玩版本，已经开始进入鸡窝主题改造阶段。

已经完成：

- 三档难度：简单、中等、困难。
- 首点安全：第一次点击后再布雷，首点和相邻格不放雷。
- 基础插旗：通过“插旗模式/排雷模式”按钮切换。
- 基础翻格：空白区域会连锁展开。
- 胜负结算：踩雷失败，翻开所有安全格胜利。
- 计时、暂停、重新开始、最高分记录。
- 棋盘根据屏幕尺寸和难度自适应格子大小。
- 鸡窝背景图 `bg.png` 已经接入。
- 胜利/失败文案已经接入“鸡窝安全！”和“踩到鸡雷了！”。
- 扫雷代码已经按页面、HUD、棋盘、规则、主题、类型、结算层拆分。

还没完成到设计要求：

- 棋盘格子仍需要继续鸡窝化，当前只做了初步暖色替换。
- 雷还是文字/符号，没有“鸡雷”素材。
- 旗子还是 `⚑` 字符，没有鸡爪旗或布片旗素材。
- 没有鸡毛、嫌弃鸡等失败反馈。
- 没有长按插旗，移动端操作成本还偏高。

## 代码位置

扫雷主目录：

```text
entry/src/main/ets/games/minesweeper/
```

当前拆分：

```text
MinesweeperPage.ets
MinesweeperTypes.ets
MinesweeperRules.ets
MinesweeperTheme.ets
MinesweeperBoard.ets
MinesweeperHud.ets
MinesweeperResultOverlay.ets
```

入口接入：

```text
entry/src/main/ets/pages/Index.ets
```

游戏注册：

```text
entry/src/main/ets/shell/GameRegistry.ets
```

## 拆分后的代码职责

- `MinesweeperPage.ets`：页面容器、生命周期、计时器、状态流转、组件组装。
- `MinesweeperTypes.ets`：`MineCell`、`MineDifficulty`、三档难度配置。
- `MinesweeperRules.ets`：初始化棋盘、首点布雷、连锁展开、揭雷、插旗、胜利判断、分数计算。
- `MinesweeperTheme.ets`：胜负文案、页面/HUD/棋盘颜色、数字低饱和颜色。
- `MinesweeperBoard.ets`：棋盘 `Grid` 和单格渲染，后续鸡雷/旗子素材主要接这里。
- `MinesweeperHud.ets`：顶部栏、难度按钮、翻开/插旗模式、重开、暂停。
- `MinesweeperResultOverlay.ets`：胜负结算弹层，后续鸡毛和嫌弃鸡素材主要接这里。

## 素材接入点

扫雷素材单独放在：

```text
entry/src/main/resources/rawfile/games/minesweeper/
```

不要和其他游戏素材混放到 `entry/src/main/resources/base/media/` 根目录。

建议第一批素材：

- `bg.png`：扫雷页全屏背景，当前已接入，尺寸为 941×1672。
- `panel_wood_long.png`：顶部木质长面板，当前已接入到 `MinesweeperHud.ets`。
- `button_blue_flower.png`：选中难度按钮，当前已接入到 `MinesweeperHud.ets`。
- `button_wood_small_left.png`：未选中难度按钮，当前已接入到 `MinesweeperHud.ets`。
- `button_wood_small_right.png`：未选中难度按钮和顶部暂停按钮，当前已接入到 `MinesweeperHud.ets`。
- `button_green.png`：翻开/插旗模式按钮，当前已接入到 `MinesweeperHud.ets`。
- `button_yellow.png`：重新开始按钮，当前已接入到 `MinesweeperHud.ets`。
- `board_border_corner_top_left.png` / `board_border_corner_top_right.png` / `board_border_corner_bottom_left.png` / `board_border_corner_bottom_right.png`：棋盘四角边框，当前已接入到 `MinesweeperBoard.ets`。
- `board_border_edge_top.png` / `board_border_edge_bottom.png` / `board_border_edge_left.png` / `board_border_edge_right.png`：棋盘四边边框，当前已接入到 `MinesweeperBoard.ets`。
- `board_border_preview_square.png`：棋盘边框参考图，暂不在运行时引用。
- `mine_chicken_egg.png`：黑色鸡蛋、引线、红色鸡冠。
- `flag_chicken_paw.png`：鸡爪小旗。
- `flag_cloth_pink.png`：粉色衬衫布片小旗，可作为备选。
- `feather_burst.png`：失败时鸡毛飞出。
- `chicken_disgusted.png`：结算弹窗里的嫌弃鸡。

代码替换位置：

- 页面背景：`build()` 中使用 `Image($rawfile('games/minesweeper/bg.png'))` 全屏铺底，当前用 `ImageFit.Fill` 保证底部鸡蛋和木牌完整露出。
- HUD 按钮：`MinesweeperHud.ets` 中用切图做图片底，文字继续由 ArkUI 渲染，便于动态更新难度、暂停和模式状态。
- 棋盘边框：`MinesweeperBoard.ets` 中使用九宫格拼接，四角固定缩放，四边拉伸，中间保留现有 Grid。
- 鸡雷显示：替换 `MinesweeperBoard.ets` 中打开雷格的文本显示。
- 旗子显示：替换 `MinesweeperBoard.ets` 中 `cell.flag ? '⚑' : ''`。
- 胜负文案：已经集中在 `MinesweeperTheme.ets`。
- 失败效果：在 `MinesweeperResultOverlay.ets` 或踩雷格附近叠加 `feather_burst.png` 和 `chicken_disgusted.png`。

## 下一步建议

第一步继续改棋盘视觉：

- 未打开格子改成木板/草垫/蛋壳砖风格。
- 打开格子改成浅木板。
- 预留鸡雷和旗子图片渲染分支。

第二步等素材到位后接入图片资源：

- 用 `Image($rawfile('games/minesweeper/mine_chicken_egg.png'))` 显示鸡雷。
- 用 `Image($rawfile('games/minesweeper/flag_chicken_paw.png'))` 或 `flag_cloth_pink.png` 显示插旗。
- 结算弹窗加入鸡毛和嫌弃鸡。

第三步再做移动端手感：

- 长按插旗。
- 插旗模式切换状态更明显。
- 点击反馈和误触保护。
