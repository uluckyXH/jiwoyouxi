# 2026-07-08 rpsBattle 性能止血优化测试报告

## 测试范围

- 新版 `rpsBattle` 运行帧性能止血优化。
- 高频实体坐标不再每帧写入 ArkUI `@State`。
- 页面 Canvas 改为直接由 `RpsBattleRenderer` 绘制。
- HUD 降频同步，每 `250ms` 刷新人数、倒计时和转化数。
- 运行帧不再通过 `snapshot()` clone 全量实体数组。
- 删除未使用的 `RpsBattleBoard.ets`，避免后续误回到 `@Prop @Watch` 高频绘制路径。

## 变更文件

- `entry/src/main/ets/games/rpsBattle/RpsBattlePage.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleEngine.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleRenderer.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleBoard.ets`

## 构建检查

命令：

```bash
./scripts/build-app.sh --stacktrace
```

结果：

```text
BUILD SUCCESSFUL
```

备注：构建输出仍有 `No signingConfig found for product default` 警告，属于当前本地默认签名配置状态，不影响本次 ArkTS 编译和打包通过。

## 静态检查

命令：

```bash
git diff --check
```

结果：PASS，无空白错误。

## 待真机验收项

- 标准局单位移动是否比优化前更连续。
- 大局模式是否明显减少持续顿挫。
- HUD 人数、倒计时、转化数是否仍能正常更新。
- 转化音效是否仍正常触发，且节流有效。
- 暂停/继续后 Canvas 是否继续正常绘制。
- 结算后是否只记录一次成绩并只展示一次结果层。
- 返回大厅后是否没有残留循环或背景音乐。

## 遗留问题

- 本次只做运行帧状态同步止血，没有改最近目标搜索和碰撞检测算法。
- 引擎仍是全量扫描，后续大人数或素材接入前建议继续做阵营分组和空间分桶。
- 战场静态背景仍每帧绘制，后续接素材前建议拆静态背景层和动态单位层。
