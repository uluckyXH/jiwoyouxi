# 石头剪刀布大作战团队占点持久对抗测试报告

日期：2026-07-21
测试人：Codex
范围：新版 `entry/src/main/ets/games/rpsBattle/` 的 `团队占点` 结算和援军规则

## 变更摘要

- `团队占点` 不再按清场提前结束，优先由据点到 `100` 或时间到结算。
- `经典乱斗` 继续保留清场结算。
- 绝地求生复活从一次性机会调整为冷却援军。
- 阵营剩余 `3` 个以内且数量下降时会留下复活印记。
- 阵营团灭后，只要绝地求生开启、冷却结束、对局未结束，仍可再次排援军。
- 同阵营援军冷却为 `5s`，同一时间最多一个复活印记。
- 复活延迟为 `2.2s`，复活单位速度倍率为 `1.18`。
- 复活可使用最多 `3` 个援军预备槽，避免满员大局下团灭阵营完全无法回场。
- 复活生成点避开激活中的黑洞影响圈：印记位置危险时回退到阵营出生点，再不安全则选择远离黑洞的角落。
- 团队占点模式增加轻量占点意图：部分单位主动争夺/驻守据点，天敌靠近时仍优先躲避。

## 构建检查

已执行：

```bash
git diff --check
DEVECO_STUDIO_APP=/Volumes/MacSSD/Applications/DevEco-Studio.app ./scripts/build-app.sh --stacktrace
```

结果：

```text
git diff --check: PASS
BUILD SUCCESSFUL in 6 s 171 ms
```

构建过程中出现 `No signingConfig found for product default` 警告，属于当前本机默认签名配置警告；本次 ArkTS 编译、HAP 打包和 App 打包已完成。

## Hypium 测试状态

已更新 HarmonyOS 官方 Hypium 测试文件：

- `entry/src/ohosTest/ets/test/RpsBattleLastStandSystem.test.ets`

覆盖重点：

- 剩余 `3` 个以内时创建复活印记。
- `2.2s` 后生成复活请求。
- 已有复活印记时不重复创建。
- 团灭阵营在冷却结束后可以再次进入援军倒计时。

当前只确认测试文件写入工程；未执行到设备侧 Hypium 测试。

## 真机待验

- 团队占点中某阵营被吞到 `0` 后，对局不要立刻结束。
- 绝地求生开启时，团灭阵营冷却结束后应能看到复活印记和援军回场。
- 黑洞开启时，援军不应在黑洞核心或吸引范围附近复活。
- 单位整体移动应更明显围绕中心据点拉扯，而不是只在边缘追逐清场。
- 关闭绝地求生后，不应出现援军。
- 据点达到 `100` 仍然直接结算。
- 时间到仍然结算。
- 关注 `RpsBattlePerf` 中 `fps`、`maxInterval`、`lastStandMs`、`lastStandRevives/frame`。
