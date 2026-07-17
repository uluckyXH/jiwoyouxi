# rpsBattle 机制开关与黑洞移动端适配测试报告

日期：2026-07-16
范围：`rpsBattle` 机制默认包开关、团队占点黑洞关闭、黑洞移动端动态上限

## 本次变更

- 新增本局机制选择数据结构，模式核心机制锁定，已实现增强机制默认开启但允许开局前关闭。
- `团队占点` 的 `黑洞` 从固定开启改为默认开启、可关闭。
- 引擎启动时按 `modeKey + mechanics` 解析运行规则，关闭黑洞后不初始化、不更新、不绘制黑洞。
- 黑洞成长上限改为绝对上限和战场短边比例上限共同约束，手机端不再接近全屏吸入。
- 黑洞首次激活时避开中心据点核心区域。

## 已执行测试

| 命令 | 结果 |
| --- | --- |
| `node scripts/test-rps-battle-lineup-rules.mjs` | 通过 11 项 |
| `node scripts/test-rps-battle-black-hole-system.mjs` | 通过 9 项 |
| `node scripts/test-rps-battle-zone-system.mjs` | 通过 6 项 |
| `git diff --check` | 通过 |

覆盖点：

- 黑洞默认开启。
- 黑洞开关关闭后，`zones.hasBlackHole = false`。
- `中心据点` 作为核心机制，尝试关闭后仍保持开启。
- 未实现的 `lastStand / powerUps` 即使被传入开启，也不会进入运行规则。
- 手机短边 `360` 时，黑洞最大核心半径为 `57.6`，最大吸引范围为 `151.2`。
- 大屏仍保留原版绝对上限 `116 / 310`。
- 黑洞出生点会避开传入的中心安全圈。

## 未完成验证

本机无法执行完整 Hvigor 构建：

```text
./scripts/build-app.sh: line 13: /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw: No such file or directory
```

需要在安装 DevEco Studio / hvigorw 的机器上补一次完整构建和真机试玩。

## 真机建议

1. 选择 `团队占点`，确认黑洞默认显示为“开”。
2. 关闭黑洞后开始，观察整局不出现黑洞，性能日志 `blackHoleMs` 接近 `0`。
3. 重新打开黑洞，确认手机端吸引圈不再覆盖大部分战场。
4. 观察中心据点仍能正常涨分、结算。
