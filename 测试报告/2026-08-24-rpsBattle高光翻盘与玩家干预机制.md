# RPS Battle 高光翻盘与玩家干预机制测试报告

日期：2026-08-24
测试人：Codex
分支：`main`
范围：新版 `entry/src/main/ets/games/rpsBattle/` 的悬赏头名、我要打十个、上帝之手，以及对应的 HarmonyOS 原生测试入口

## 变更摘要

- 新增 `RpsBattleBountySystem.ets`：经典乱斗的头名资格、非头名追击偏置、转阵奖励、护盾和短时加速。
- 新增 `RpsBattleTenAgainstOneSystem.ets`：极端十倍人数差的连续资格、入场冻结、十秒暴走和优先淘汰碰撞。
- 新增 `RpsBattleGodHandSystem.ets`：四种模式可选的三次离散推/吸脉冲、冷却和暂停清理。
- 新增独立的 `RpsBattleEnhancementSetupCard.ets`，并将选择结果归一化写入 `RpsBattleOptions`。
- 上帝之手对局统一标记为干预局，结算不会调用常规最高分记录。
- Canvas 负责头名描边、悬赏脉冲、暴走尾迹和手动力场；ArkUI 只维护低频 HUD 状态。
- 新增 `bountyMs`、`tenAgainstOneMs`、`godHandMs` 等 `RpsBattlePerf` 指标。

## 原生自动化测试

已按项目规范新增或补齐以下 HarmonyOS Hypium 用例：

| 文件 | 重点覆盖 |
| --- | --- |
| `entry/src/ohosTest/ets/test/RpsBattleBountySystem.test.ets` | 开局保护、资格阈值、领先解除、奖励与脉冲过期、关闭状态 |
| `entry/src/ohosTest/ets/test/RpsBattleTenAgainstOneSystem.test.ets` | 连续十倍资格、冻结、暴走、优先淘汰和时长保护 |
| `entry/src/ohosTest/ets/test/RpsBattleGodHandSystem.test.ets` | 推/吸方向、冷却、次数、半径，以及暂停不返还次数或绕过冷却 |
| `entry/src/ohosTest/ets/test/RpsBattleEnhancementConfig.test.ets` | 模式限制、互斥选择、选项归一化和干预局结算标记 |

测试入口已按当前 DevEco Studio 的 Stage 测试模板补齐：

- `entry/src/ohosTest/module.json5`
- `entry/src/ohosTest/ets/testability/TestAbility.ets`
- `entry/src/ohosTest/ets/testrunner/OpenHarmonyTestRunner.ets`
- `entry/src/ohosTest/resources/base/`

项目级 `oh-package.json5` 将 `@ohos/hypium` 声明为 `devDependencies`，不进入应用生产依赖。

## 构建与命令记录

已执行的 HarmonyOS 原生命令：

```bash
git diff --check
DEVECO_STUDIO_APP=/Volumes/MacSSD/Applications/DevEco-Studio.app \
NODE_HOME=/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/tools/node \
./scripts/build-app.sh --stacktrace
DEVECO_SDK_HOME=/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/sdk \
JAVA_HOME=/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home \
/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test \
  -p module=entry -p coverage=false --node-home /Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/tools/node \
  --no-daemon --stacktrace
DEVECO_SDK_HOME=/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/sdk \
JAVA_HOME=/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home \
/Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw onDeviceTest \
  -p module=entry -p product=default -p coverage=false \
  --node-home /Volumes/MacSSD/Applications/DevEco-Studio.app/Contents/tools/node \
  --no-daemon --stacktrace
```

本报告只记录 HarmonyOS 构建和 Hypium/TestKit 测试路径；未使用 Node 脚本执行或替代 ArkTS 规则测试。

## 当前验证状态

| 项目 | 状态 | 说明 |
| --- | --- | --- |
| ArkTS 主应用构建 | 通过 | 使用 DevEco Studio 随附工具链执行，最近一次结果为 `BUILD SUCCESSFUL in 5 s 653 ms` |
| 差异格式检查 | 通过 | `git diff --check` 无输出 |
| Hypium ArkTS 编译 | 通过 | `hvigorw test` 已执行至 `:entry:default@UnitTestArkTS` 成功，新增及既有 Hypium 用例均完成 ArkTS 编译与依赖解析 |
| TestKit 设备测试 HAP | 通过 | `onDeviceTest` 已完成 `:entry:ohosTest@OhosTestCompileArkTS`、`PackageHap` 和主应用 `CompileArkTS`，测试 Ability、运行器及全部用例均进入测试包 |
| Hypium 本地运行 | 未完成 | RichPreviewer 在无 IDE 预览会话的命令行环境中报命令管道与本地 socket 连接失败，未将其误记为用例通过 |
| 设备侧 Hypium 测试 | 阻塞 | 测试 HAP 编译完成后，官方 `onDeviceTest` 在 `GenerateDeviceCoverage` 阶段报 `Connect server failed`；`hdc list targets` 同样无法连接本机 HDC 服务，因此没有可调度设备 |
| Node 替代测试 | 未执行 | 不符合本项目 HarmonyOS 原生测试规范 |

## 真机验收清单

1. 经典乱斗默认不启用强化；`悬赏头名` 与 `我要打十个` 互斥，上帝之手可独立开启。
2. 悬赏头名在达到人数条件后出现头名强调；领先消失后标记和目标偏置立即消失；转换头名单位后确认护盾和短时加速。
3. 我要打十个只在两方、十倍人数差且基础克制对优势方有利时触发一次；确认冻结、暴走和结束后的普通克制恢复。
4. 四种模式都可启用上帝之手；确认推/吸、三次上限、冷却和暂停后力场清理正常。
5. 团队占点、小心叛徒、众生平等开启上帝之手后，确认据点、黑洞、缩圈、叛徒、响指和障碍仍按各自规则运行。
6. 干预局完成后确认不会更新常规最高分；关闭上帝之手的对局仍按原有口径记录成绩。
7. 观察 `RpsBattlePerf`：关闭强化时 `bountyMs`、`tenAgainstOneMs`、`godHandMs` 应接近零；开启时不存在持续性明显掉帧。

## 遗留项

- `@ohos/hypium` 已由 OHPM 安装并锁定在 `oh-package-lock.json5`；仍需通过 TestKit 在已连接真机或模拟器执行 Hypium 套件。
- 本机命令行的 RichPreviewer 缺少 IDE 建立的命令管道，因此不能代替设备侧运行结果。
- UI 视觉和真实手感由项目负责人后续真机验收；本次不把 UI 手工观察伪装成自动化通过。
