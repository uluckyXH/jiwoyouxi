# 石头剪刀布大作战小心叛徒机制测试报告

日期：2026-07-23
测试人：Codex
范围：新版 `entry/src/main/ets/games/rpsBattle/` 的 `小心叛徒` 模式第一版和手机短局调优版

## 变更摘要

- `小心叛徒` 模式从占位机制改为可运行机制组合。
- `叛徒` 设为核心机制，默认开启且不可关闭。
- `缩圈`、`黑洞` 设为默认开启的可关闭机制。
- 新增 `RpsBattleTraitorSystem.ets`，处理叛徒标记、早期叛徒、常规触发、倒计时叛变请求和脉冲快照。
- 新增 `RpsBattleShrinkSystem.ets`，处理缩圈延迟、边界推进、最大压缩和安全区。
- `RpsBattleEngine.ets` 接入叛徒转阵、短暂暴走、缩圈边界、黑洞安全区生成和死斗清场。
- `RpsBattleRenderer.ets` 接入缩圈暗角、叛徒倒计时环、目标阵营提示和叛变脉冲。
- 性能日志增加 `shrinkMs`、`traitorMs`、`traitorMarks/frame`、`traitorConversions/frame`。
- 设计文档更新为第一版已实现：[小心叛徒机制迁移设计.md](/Volumes/MacSSD/Repositories/jiwoyouxi/docs/xiaohuang/石头剪刀布大作战/小心叛徒机制迁移设计.md)。

## 2026-07-23 手机短局调优追加

真机反馈：手机端场地小，单位密度高，第一版容易在叛徒、缩圈、黑洞发生前就被基础吞噬清场。

本轮追加：

- 首次叛徒标记提前到开局 `0.8s..1.5s`。
- 叛徒倒戈延迟保持 `2s`，首次转阵目标约 `2.8s..3.5s`。
- 常规叛徒间隔从 `10s` 缩短到 `6.8s`。
- 新增前 `12s` 清场保护：只剩一个阵营时优先安排救场叛徒，不立即结算。
- 救场叛徒每局最多 `2` 次，且唯一存活阵营至少需要 `2` 个单位，避免无限拖局。
- 缩圈改为开局轻提示，`4s` 后慢速推进，速度从 `9px/s` 降到 `4.5px/s`。
- `小心叛徒` 黑洞首次出现调整为 `6s..10s`；团队占点仍保持 `9s..16s`。
- Canvas 渲染层增加缩圈预警边框，没有引入 WebView、HTML、Node 运行依赖或跨端动画方案。

## 构建检查

已执行：

```bash
git diff --check
DEVECO_STUDIO_APP=/Volumes/MacSSD/Applications/DevEco-Studio.app ./scripts/build-app.sh --stacktrace
DEVECO_SDK_HOME=/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/sdk JAVA_HOME=/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home /Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw tasks --node-home /Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/tools/node --no-daemon
```

结果：

```text
git diff --check: PASS
BUILD SUCCESSFUL in 6 s 710 ms
hvigorw tasks: BUILD SUCCESSFUL in 1 s 200 ms
```

构建过程中出现 `No signingConfig found for product default` 警告，属于当前本机默认签名配置警告；本次 ArkTS 编译、HAP 打包和 App 打包已完成。

## Hypium 测试状态

已新增 HarmonyOS 官方 Hypium 测试文件：

- `entry/src/ohosTest/ets/test/RpsBattleTraitorSystem.test.ets`
- `entry/src/ohosTest/ets/test/RpsBattleShrinkSystem.test.ets`

覆盖重点：

- 开局 `0.8s` 前不触发叛徒。
- `0.8s..1.5s` 生成首次叛徒标记。
- 标记 `2s` 后生成叛变请求。
- 开局叛徒只触发一次。
- 常规叛徒触发间隔受 `6.8s` 冷却限制。
- 早期清场保护窗口内可以安排救场叛徒。
- 清场保护窗口结束后不再救场。
- 缩圈开局有预警但不推进 padding。
- 缩圈 `4s` 后按慢速推进。
- 缩圈 padding 不超过短边 `28%`。
- 缩圈保持可玩安全区并能响应 resize。

当前只确认测试文件写入工程，并通过 ArkTS 构建；未执行到设备侧 Hypium 用例运行。

补充说明：仓库当前没有发现额外封装的设备侧 Hypium 执行脚本；`hvigorw tasks` 也未列出测试包或 ohosTest 执行任务。本轮已按项目规范保留 `entry/src/ohosTest/ets/test/` 测试文件，并完成 DevEco / hvigor 构建检查。设备侧 Hypium 运行和真机体验仍作为后续验收项。

## 真机待验

- 选择 `小心叛徒` 后，配置页应显示 `叛徒` 为核心，`缩圈/黑洞` 为可开关机制。
- 默认开启进入战斗后，`0.8s..1.5s` 应出现叛徒紫色倒计时环。
- 倒计时 `2s` 后，被标记单位应切换为目标阵营颜色，并出现叛变脉冲。
- 前 `12s` 内如果只剩一个阵营，应看到救场叛徒标记，而不是立刻清场结算。
- 缩圈开启时，开局应先显示轻边界提示，约 `4s` 后战场暗角和安全边界逐步向内推进，单位不会跑出安全区。
- 关闭缩圈后，不应出现缩圈暗角和边界推进。
- 黑洞开启时，`小心叛徒` 应在 `6s..10s` 首次出现，仍保持移动端范围控制，不应全屏吸入。
- 关闭黑洞后，不应出现黑洞。
- 叛徒模式不应时间到结算，应按死斗清场结束。
- 关注 `RpsBattlePerf` 中 `fps`、`maxInterval`、`shrinkMs`、`traitorMs`、`traitorMarks/frame`、`traitorConversions/frame`。
