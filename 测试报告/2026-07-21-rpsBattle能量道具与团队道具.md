# 石头剪刀布大作战能量道具与团队道具测试报告

日期：2026-07-21
测试人：Codex
范围：新版 `entry/src/main/ets/games/rpsBattle/` 的 `团队占点` 模式增强机制 `powerUps` / `teamPowerUps`

## 变更摘要

- 新增 `RpsBattlePowerUpSystem.ets`，独立实现道具刷新、过期、拾取、拾取脉冲和机制快照。
- `团队占点` 默认启用 `能量道具` 和 `团队道具`，开局前可关闭。
- `团队道具` 依赖 `能量道具`：关闭能量道具会自动关闭团队道具；打开团队道具会自动打开能量道具。
- 道具类型对齐原版：加速、护盾、分裂。
- 实体新增 `shield` 和 `speedBoostUntilSec`；护盾抵挡一次转阵，加速提升限时速度上限。
- 团队分裂受全局人数上限保护，并限制单次团队拾取最多额外生成 8 个单位。
- Canvas 增加道具本体、拾取脉冲、护盾外圈和加速尾迹。
- 性能日志增加 `powerUpMs`、`powerUpsActive`、`powerUpsPicked/frame`、`teamPowerUps/frame`。
- 新增 HarmonyOS Hypium 测试文件：`entry/src/ohosTest/ets/test/RpsBattlePowerUpSystem.test.ets`。
- 本轮调参：首个道具约 `3s` 出现，后续约 `4s` 刷新，场上最多 `6` 个，道具按加速、护盾、分裂循环出现。

## 构建检查

已执行：

```bash
git diff --check
DEVECO_STUDIO_APP=/Volumes/MacSSD/Applications/DevEco-Studio.app ./scripts/build-app.sh --stacktrace
```

结果：

```text
git diff --check: PASS
BUILD SUCCESSFUL in 5 s 398 ms
```

构建过程中出现 `No signingConfig found for product default` 警告，属于当前本机默认签名配置警告；本次 ArkTS 编译、HAP 打包和 App 打包已完成。

## 资源目录阻断处理

首次构建在资源编译阶段被未跟踪目录阻断：

```text
Invalid resource directory name 'game_icons'
entry/src/main/resources/base/game_icons
```

处理方式：

- 未删除资源文件。
- 将未跟踪图标从非法 `entry/src/main/resources/base/game_icons/` 移到合法 rawfile 目录 `entry/src/main/resources/rawfile/app/game_logos/`。
- 将未跟踪 `entry/src/main/resources/base/首页展示游戏图标.png` 同步移到 `entry/src/main/resources/rawfile/app/game_logos/`。

处理后构建通过。

## Hypium 测试状态

已新增 HarmonyOS 官方 Hypium 测试文件，覆盖：

- 首个道具约 3 秒后刷新。
- 场上道具数量不超过 6 个上限。
- 道具按加速、护盾、分裂循环出现。
- 拾取后移除道具并记录团队拾取意图。
- 机制关闭时清空道具状态。

当前只确认测试文件写入工程；未执行到设备侧 Hypium 测试。

原因：

- 当前 hvigor 任务列表只暴露 `assembleApp` 等构建任务，没有可直接执行的 ohosTest 任务。
- 本轮未连接真机运行 Hypium / ArkXTest。

## 真机待验

- 选择 `团队占点` 时，`能量道具`、`团队道具` 默认开启且可关闭。
- 关闭能量道具后，团队道具自动关闭，开局不出现任何道具。
- 关闭团队道具但保留能量道具时，只有拾取单位获得加速、护盾或分裂。
- 开启团队道具时，同阵营存活单位共享加速/护盾/分裂效果。
- 连续刷新时能看到护盾和分裂，不应长时间只出现加速。
- 场上道具最多 6 个，超过上限不继续刷。
- 护盾单位被克制方碰撞时消耗护盾，不发生转阵。
- 分裂不会突破总人数上限，团队分裂不会造成明显卡顿。
- 大局模式关注 `RpsBattlePerf`：`powerUpMs` 常态应接近 0，`fps` 和 `maxInterval` 不应明显退化。
