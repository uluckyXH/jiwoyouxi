# RPS Battle 众生平等机制测试报告

日期：2026-07-24
测试范围：`众生平等`模式的死斗清场、均衡清算、战场障碍、机制开关、Canvas/HUD 表达和性能观测
分支：`main`
变更基线：当前工作区未提交变更

## 变更摘要

- 新增 `RpsBattleSnapSystem.ets`，在开局 3 至 4 秒进入预警，1.8 秒后对每个阵营随机移除 `floor(存活数 / 2)` 个单位，每局只执行一次。
- 新增 `RpsBattleObstacleSystem.ets`，小屏生成 2 个、常规手机生成 3 个更大的圆形石块；生成过程避开出生区、中心交战区和其他障碍。
- `equality` 现为死斗模式；响指减员、战场障碍默认开启且可分别关闭，死斗清场保持模式核心。
- 引擎复用实体缓存和删除路径处理清算，并在移动之后、阵营碰撞之前进行障碍分离和反弹。
- HUD 和 Canvas 使用 ArkUI/Canvas 原生实现；响指预警和完成复用已预加载的通用音效，不依赖角色图片、网络资源、WebView 或 HTML。
- `RpsBattlePerf` 新增 `snapMs`、`obstacleMs`、`snapRemoved/frame`、`obstacleHits/frame`。

## 自动检查

| 检查项 | 命令或位置 | 结果 |
| --- | --- | --- |
| 差异格式 | `git diff --check` | 通过 |
| ArkTS 构建 | `DEVECO_STUDIO_APP=/Volumes/MacSSD/Applications/DevEco-Studio.app ./scripts/build-app.sh --stacktrace` | 通过；圆形障碍与通用音效改造后的完整 ArkTS 编译为 `BUILD SUCCESSFUL in 6 s 395 ms` |
| 清算 Hypium 用例 | `entry/src/ohosTest/ets/test/RpsBattleSnapSystem.test.ets` | 已补充，待 HarmonyOS 测试环境执行 |
| 障碍 Hypium 用例 | `entry/src/ohosTest/ets/test/RpsBattleObstacleSystem.test.ets` | 已补充，待 HarmonyOS 测试环境执行 |
| 模式配置 Hypium 用例 | `entry/src/ohosTest/ets/test/RpsBattleEqualityModeConfig.test.ets` | 已补充，待 HarmonyOS 测试环境执行 |

构建仅保留本地默认签名配置缺失警告：`No signingConfig found for product default`，未阻塞 ArkTS 编译或打包。

## Hypium 覆盖

- 清算预警窗口、单次执行、偶数/奇数/单个单位的减员数量与随机抽取不重复。
- 清算状态清理。
- 小屏/常规屏圆形障碍数量、半径范围、出生区与中心安全区、障碍互不重叠。
- 单位撞击圆形障碍的推出与反弹、单位与障碍圆心重合时的确定性脱困。
- 众生平等的默认开关，以及关闭两个增强机制后仍保持死斗清场。

当前环境中，带 SDK/JDK/Node 路径的 `hvigorw tasks` 仅暴露 HAP 打包任务，未提供可直接调用的 `ohosTest` 或 `test` 任务；`hdc list targets` 未列出已连接 HarmonyOS 设备。因此这些 Hypium 文件未在本机执行，未使用 Node 脚本替代 ArkTS/Hypium 测试。

## 待真机验收

1. 进入`众生平等`，确认默认显示`死斗清场`、`响指减员`和`战场障碍`；两个增强机制均可在开局前独立关闭。
2. 默认组合下，确认约第 3 至 4 秒出现`均衡清算`预警，约第 5 至 6 秒只执行一次；每阵营移除数量为 `floor(存活数 / 2)`，单个单位不会被事件直接清除。
3. 关闭响指减员后，确认没有预警、脉冲、减员提示，日志中的 `snapMs` 与 `snapRemoved/frame` 接近零。
4. 关闭战场障碍后，确认画布不绘制障碍、单位不反弹，日志中的 `obstacleMs` 与 `obstacleHits/frame` 接近零。
5. 默认圆形障碍下，确认三个出生点和中心交战区没有被封锁；单位绕行时不持续卡在障碍内部或高频抖动。
6. 确认预警阶段只播放一次通用警示音、清算完成只播放一次通用事件音；不显示原版角色图片，也不播放原版响指音频。
7. 分别验证暂停/恢复、重新开始和返回大厅，确认清算不会重复触发，障碍不会遗留。
8. 在小、中、大阵容观察 `RpsBattlePerf`，记录 `fps`、`maxInterval`、`snapMs`、`obstacleMs`、`targetMs` 和 `collisionMs`；清算允许出现单次短峰值，不应造成持续掉帧。

## 结论

代码已经通过静态差异检查和官方 HAP 构建。纯规则的 Hypium 用例已按项目规范落盘；因当前命令任务和设备均不可用，自动测试与真机验收待在可运行 HarmonyOS 测试模块的设备环境完成。
