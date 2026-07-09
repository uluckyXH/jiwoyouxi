# 2026-07-08 rpsBattle 基础玩法 MVP 测试报告

## 测试范围

- 新版 `rpsBattle` 基础玩法闭环。
- 选择界面：支持阵营选择、对局规模选择、开始乱斗。
- 基础对局：三阵营自动移动、追击、躲避、碰撞转化。
- 对局 HUD：三方人数、倒计时、支持阵营、转化次数。
- 暂停/继续、重新开始、返回大厅。
- 结算层：胜方或平局、最终人数、支持结果、再来一局、重新选择、回大厅。

## 变更文件

- `entry/src/main/ets/games/rpsBattle/RpsBattleTypes.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleRules.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleEngine.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleBoard.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleHud.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleSetupPanel.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleOverlay.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattlePage.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleTheme.ets`

## 构建检查

命令：

```bash
./scripts/build-app.sh --stacktrace
```

结果：

```text
BUILD SUCCESSFUL
```

备注：构建输出仍有 `No signingConfig found for product default` 警告，属于当前本地默认签名配置状态，不影响本次 ArkTS 编译和打包通过。

## 静态检查

命令：

```bash
git diff --check
```

结果：PASS，无空白错误。

## 待真机验收项

- 从大厅最后一个入口进入新版游戏。
- 首屏显示选择界面，不直接开局。
- 顶部栏左侧“大厅”按钮可返回。
- 选择石头、剪刀、布后高亮状态正确。
- 选择小局、标准、大局后人数规模正确。
- 点击“开始乱斗”后进入战场。
- 三阵营单位能自动移动并发生碰撞转化。
- HUD 人数、倒计时、转化次数持续刷新。
- 点击暂停后对局停止，继续后恢复。
- 清场或倒计时结束后展示结算层。
- 结算层“再来一局”“重新选择”“回大厅”可用。
- 小屏和常规手机屏不出现按钮遮挡或文本溢出。

## 遗留问题

- 当前仓库暂无 `entry/src/ohosTest/ets/test/` 测试目录，本次未新增可执行单元测试。
- 规则和引擎已拆成纯 ArkTS 模块，后续补官方单元测试时可直接覆盖克制关系、计数、胜负判定和碰撞转化。
- 真机试玩尚未执行，需在设备上确认 Canvas 帧率、战场尺寸和触控返回体验。
