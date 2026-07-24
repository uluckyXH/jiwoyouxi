# rpsBattle 骨架接入测试报告

日期：2026-07-08
测试人：Codex
变更范围：

- 新增 `entry/src/main/ets/games/rpsBattle/`
- 接入 `GameRegistry`
- 接入 `HubPage` 首页卡片顺序
- 接入 `Index` 游戏路由
- 调整新版卡片到首页最后一个位置
- 调整新版页面为 Tetris 参考风格，并将顶部栏改为参考鸡窝水果摊的全宽奶油色栏

## 构建检查

命令：

```bash
./scripts/build-app.sh --stacktrace
```

结果：

- 通过，`BUILD SUCCESSFUL`
- 仍有既有警告：`No signingConfig found for product default`

## 功能检查

已通过代码检查确认：

- `rpsBattle` 已加入 `GAME_MODULES`
- 首页 `HOME_GAME_ORDER` 已加入 `rpsBattle`，位置在最后
- `Index` 已增加 `activeGame === 'rpsBattle'` 路由分支
- 新页面包含返回大厅按钮
- 新页面顶栏参考鸡窝水果摊：全宽奶油色背景、左侧大厅按钮、居中标题、右侧等宽占位

## 未完成项

- 未做真机点击进入和返回验收。
- 未做 UI 截图验收。

原因：

- 当前环境未连接真机或模拟器操作链路。

后续真机验收建议：

1. 从首页点击“石头剪刀布大作战·新版”卡片进入。
2. 验证进入转场正常，无白屏或黑屏。
3. 点击“大厅”返回首页。
4. 验证系统返回键在游戏页能返回大厅。
5. 检查小屏下首页第 7 个游戏卡片可滚动可点击。
