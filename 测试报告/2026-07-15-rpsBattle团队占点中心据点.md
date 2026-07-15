# rpsBattle 团队占点中心据点与黑洞测试报告

日期：2026-07-15
测试人：Codex
范围：`rpsBattle` 团队占点中心据点核心闭环，以及黑洞 P2 机制接入

## 变更范围

- 新增 `RpsBattleZoneSystem.ets`，负责中心据点初始化、压力统计、涨分和胜利判断。
- 新增 `RpsBattleBlackHoleSystem.ets`，负责黑洞延迟激活、吸引、吞噬和成长。
- `RpsBattleModeConfig.ets` 增加模式运行规则，`zones` 启用中心据点和黑洞，绝地/道具仍为后续。
- `RpsBattleEngine.ets` 按模式规则调度据点系统，并接入 `zone` 结算原因。
- `RpsBattleEngine.ets` 按模式规则调度黑洞系统，吞噬单位后同步实体列表、阵营缓存和计数，不计入转阵。
- `RpsBattleRenderer.ets` 在单位下方绘制据点底圈、进度环、黑洞吸引圈和黑洞核心。
- `RpsBattleHud.ets` 在团队占点模式显示据点进度。
- `RpsBattleSetupPanel.ets` 在玩法方案下展示模式机制列表，未迁移机制显示为后续禁用态。
- 性能日志增加 `zoneMs`、`zoneInside/frame`、`blackHoleMs` 和 `blackHoleKills/frame`。

## 测试命令

```bash
node scripts/test-rps-battle-lineup-rules.mjs
node scripts/test-rps-battle-zone-system.mjs
node scripts/test-rps-battle-black-hole-system.mjs
git diff --check
./scripts/build-app.sh --stacktrace
```

## 测试结果

| 项目 | 结果 | 说明 |
| --- | --- | --- |
| 人数和模式配置规则 | 通过 | 10 项通过，覆盖模式配置和 `zones` 运行规则 |
| 中心据点规则 | 通过 | 6 项通过，覆盖 owner、僵持、不涨分、满分胜利、快照隔离 |
| 黑洞规则 | 通过 | 7 项通过，覆盖未激活、激活吸引、吞噬、同帧成长、成长上限、快照隔离 |
| diff 空白检查 | 通过 | 无尾随空白或格式错误 |
| Hvigor 构建 | 未通过 | 本机缺少 `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw`，未进入代码编译阶段 |

## 遗留验证

- 需要在装有 DevEco Studio / Hvigor 的环境执行完整构建。
- 需要真机测试 `经典乱斗`，确认没有据点/黑洞和性能退化。
- 需要真机测试 `团队占点` 标准局和大局，观察据点显示、涨分、胜利结算、黑洞吸引吞噬，以及 `zoneMs`/`blackHoleMs`。
