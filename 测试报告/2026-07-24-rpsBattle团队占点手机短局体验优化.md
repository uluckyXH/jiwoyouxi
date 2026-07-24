# 石头剪刀布大作战团队占点手机短局体验优化测试报告

日期：2026-07-24
测试人：Codex
范围：新版 `entry/src/main/ets/games/rpsBattle/` 的 `团队占点` 模式 P1/P2 轻量优化

## 变更摘要

- `RpsBattleEngine.ets` 中团队占点开局前 `4s` 提高部分单位的中心据点意图。
- 开局抢点强化仍保留天敌逃离优先级，不改变三阵营克制和碰撞转阵规则。
- `RpsBattleRenderer.ets` 中心据点增加开局目标脉冲。
- 据点 Canvas 增加三方压力点和压力数字，用来观察圈内争夺状态。
- 僵持时据点边界使用中性色，不误导为稳定涨分。
- 新增 HarmonyOS Hypium 测试文件 `entry/src/ohosTest/ets/test/RpsBattleZoneSystem.test.ets`。
- 设计文档更新：[团队占点手机短局体验优化设计.md](/Volumes/MacSSD/Repositories/jiwoyouxi/docs/xiaohuang/石头剪刀布大作战/团队占点手机短局体验优化设计.md)。

## 未改动范围

- 未改团队占点结算规则。
- 未改据点 `owner + score` 分数模型。
- 未做多据点。
- 未改黑洞首次出现时间。
- 未改道具生成策略。
- 未引入 WebView、HTML、Node 运行依赖或跨端动画方案。

## 构建检查

已执行：

```bash
git diff --check
DEVECO_STUDIO_APP=/Volumes/MacSSD/Applications/DevEco-Studio.app ./scripts/build-app.sh --stacktrace
```

结果：

```text
git diff --check: PASS
BUILD SUCCESSFUL in 5 s 930 ms
```

构建过程中出现 `No signingConfig found for product default` 警告，属于当前本机默认签名配置警告；本次 ArkTS 编译、HAP 打包和 App 打包已完成。

## Hypium 测试状态

已新增 HarmonyOS 官方 Hypium 测试文件：

- `entry/src/ohosTest/ets/test/RpsBattleZoneSystem.test.ets`

覆盖重点：

- 据点只统计圈内单位压力。
- 唯一压力领先方成为占领方并涨分。
- 僵持时不设置占领方、不涨分。

当前只确认测试文件写入工程；设备侧 Hypium 运行仍作为后续验收项。

## 真机待验

- 选择 `团队占点` 默认机制包进入战斗。
- 手机标准局开局 `5s` 内，中心据点争夺感应比之前更明显。
- 中心据点有轻量目标脉冲，但不遮挡单位。
- 圈内三方压力点和数字可读，不与据点分数严重重叠。
- 僵持时据点不涨分，视觉边界不误导。
- 关闭黑洞、绝地求生、能量道具、团队道具后，中心据点仍正常。
- 关注 `RpsBattlePerf` 中 `fps`、`maxInterval`、`targetMs`、`collisionMs`、`zoneMs`、`zoneInside/frame`。
