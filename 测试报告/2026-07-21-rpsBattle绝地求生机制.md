# 石头剪刀布大作战绝地求生机制测试报告

日期：2026-07-21
范围：新版 `entry/src/main/ets/games/rpsBattle/` 的 `团队占点` 模式增强机制 `lastStand`

## 变更摘要

- 新增 `RpsBattleLastStandSystem.ets`，独立实现弱势阵营分裂、复活印记、复活请求和机制快照。
- `团队占点` 默认启用 `绝地求生`，并允许玩家在开局前关闭。
- 引擎在黑洞、碰撞和据点之后调度绝地求生；团队占点不再按清场提前结算。
- Canvas 增加复活印记倒计时、复活文字、分裂脉冲、复活印记脉冲和复活脉冲。
- 性能日志增加 `lastStandMs`、`lastStandEvents/frame`、`lastStandRevives/frame`。
- 本轮调参：阵营降到 `3` 个以内即可留下复活印记，复活延迟缩短到约 `2.2s`，复活单位速度倍率提高到 `1.18`。
- 本轮规则变更：团队占点不再按清场提前结束；团灭阵营在绝地求生开启且冷却结束后可以再次排援军。
- 同阵营援军冷却为 `5s`，同一时间最多存在一个复活印记。
- 新增 HarmonyOS Hypium 测试文件：`entry/src/ohosTest/ets/test/RpsBattleLastStandSystem.test.ets`。

## Hypium 测试状态

已新增 HarmonyOS 官方 Hypium 测试文件，覆盖：

- 只剩 1 个单位时按时间节流概率触发分裂。
- 每个阵营最多成功分裂一次。
- 阵营降到 3 个以内且数量下降时留下复活印记。
- 复活印记约 2.2 秒到期后生成同阵营复活请求。
- 单阵营已有复活印记时不会重复创建。
- 团灭阵营在冷却结束后可以再次排援军。

当前只确认测试文件写入工程；未执行到设备侧 Hypium 测试。

原因：

- 当前 hvigor 任务列表只暴露 `assembleApp` 等构建任务，没有可直接执行的 ohosTest 任务。
- 本轮未连接真机运行 Hypium / ArkXTest。

## 构建状态

已通过：

```bash
git diff --check
DEVECO_STUDIO_APP=/Volumes/MacSSD/Applications/DevEco-Studio.app ./scripts/build-app.sh --stacktrace
```

结果：

```text
git diff --check: PASS
BUILD SUCCESSFUL in 5 s 453 ms
```

构建过程中出现 `No signingConfig found for product default` 警告，属于当前本地默认签名配置警告；本次 ArkTS 编译、HAP 打包和 App 打包已完成。

## 真机待验

- 团队占点默认能看到“绝地求生”为开启。
- 关闭绝地求生后开局，战斗中不出现分裂或复活印记。
- 开启绝地求生后，弱势阵营只剩 1 个时能看到分裂脉冲。
- 阵营降到 3 个以内后如果留下印记，能看到约 2.2 秒倒计时并复活。
- 阵营团灭后，只要绝地求生开启且冷却结束，仍能看到援军回场。
- 团队占点不再因清场提前结算，重点观察是否更多通过据点到 100 或时间到结束。
- 据点达到 100 时仍然直接结算。
- 大局模式下关注 `RpsBattlePerf`：`lastStandMs` 常态应接近 0，触发事件时不应造成明显掉帧。
