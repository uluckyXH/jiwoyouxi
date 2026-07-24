# RPS Battle 团队占点三方据点进度测试报告

日期：2026-07-24
测试范围：`团队占点` P3 三方独立据点进度、限时结算、HUD/Canvas 表达与结算胜因说明
分支：`main`
变更基线：`67f6abf feat: optimize rps battle mobile modes` 之后的工作区变更

## 变更摘要

- 中心据点由单一 `score` 改为三方独立 `scores`。
- 圈内唯一压力最高的一方只累积自己的分数；反抢不继承此前进度。
- 任一阵营分数达到 `100` 即获胜；时间结束按唯一最高据点分获胜，平分为平局。
- 战斗 HUD 显示三方紧凑分数；Canvas 据点外圈显示三段独立进度弧。
- 结算弹窗展示“据点满分 / 据点领先 / 据点平分”，避免将据点判胜误解为按存活人数判胜。

## 自动检查

| 检查项 | 命令或位置 | 结果 |
| --- | --- | --- |
| 差异格式 | `git diff --check` | 通过 |
| ArkTS 构建 | `DEVECO_STUDIO_APP=/Volumes/MacSSD/Applications/DevEco-Studio.app ./scripts/build-app.sh --stacktrace` | 通过，`BUILD SUCCESSFUL in 4 s 329 ms` |
| Hypium 规则用例 | `entry/src/ohosTest/ets/test/RpsBattleZoneSystem.test.ets` | 已补充，待测试模块接入后执行 |

构建仅保留本地默认签名配置缺失警告：`No signingConfig found for product default`，未阻塞 ArkTS 编译或打包。

## Hypium 覆盖

- 圈内压力统计。
- 唯一领先阵营的独立得分。
- 反抢后旧阵营分数保留、新阵营继续累积。
- 僵持不涨分。
- 达到 `100` 分立即得出据点胜者。
- 限时团队占点按据点分而非存活人数判胜。
- 限时据点分相同返回平局。

当前项目的 Hvigor `tasks` 列表未提供 `test` 或 `ohosTest` 任务，故本机无法从命令行执行该 Hypium 文件。未使用 Node 脚本替代 ArkTS/Hypium 测试。

## 待真机验收

1. 进入“团队占点”，确认 HUD 显示三个阵营的独立据点分，且各分数不会在反抢时被重置或转移。
2. 观察据点外圈三段进度弧：每段只代表对应阵营向 `100` 分的进度；当前占点阵营更亮。
3. 一方达到 `100` 分，确认立即结算且胜因显示“据点满分”。
4. 限时结束时，故意让存活人数最多的阵营不是据点分最高阵营，确认据点分最高阵营获胜且胜因显示“据点领先”。
5. 让据点分并列，确认结果为平局且胜因显示“据点平分”。
6. 在标准和大局规模下观察 `RpsBattlePerf`：重点记录 `fps`、`maxInterval`、`zoneMs`、`zoneInside/frame`、`targetMs`、`collisionMs`。

## 风险与下一步

- 本轮没有增加实体、碰撞遍历或 ArkUI 每帧状态量；新增计算仅在现有据点系统内读写三个数值，预期 `zoneMs` 无明显增加。
- 三方进度和三段进度弧需要在小屏真机上确认可读性。
- 在完成真机验收前，不推进 P4 多点领地，避免同时引入 AI 分兵和额外 HUD 复杂度。
