# 石头剪刀布大作战视觉主题升级测试报告

日期：2026-07-21
范围：新版 `rpsBattle` 视觉主题第一版升级

## 测试内容

- 将新版乱斗从米黄/棕色主题调整为浅灰蓝、白色卡片、深青绿主操作的“清爽战术桌面”主题。
- 覆盖配置页、顶部栏、底部开始区、倒计时遮罩、HUD、暂停弹窗、结算弹窗和 Canvas 战场。
- 保持玩法规则、人数规则、团队占点、黑洞开关和性能主循环不变。

## 自动化检查

```bash
node scripts/test-rps-battle-lineup-rules.mjs
```

结果：通过 11 项，失败 0 项。

```bash
node scripts/test-rps-battle-zone-system.mjs
```

结果：通过 6 项，失败 0 项。

```bash
node scripts/test-rps-battle-black-hole-system.mjs
```

结果：通过 9 项，失败 0 项。

```bash
git diff --check
```

结果：通过。

## 构建检查

```bash
./scripts/build-app.sh --stacktrace
```

结果：未进入 ArkTS 编译阶段，本机 DevEco Studio hvigor 路径缺失：

```text
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw: No such file or directory
```

## 待真机验收

- 首页进入新版乱斗后，配置页不再大面积发黄。
- 四个玩法卡片选中态是否清楚，团队占点蓝绿强调色是否自然。
- 主题、支持阵营、人数和时长控件是否易读，文字是否截断。
- 开始乱斗后的战场背景、实体、中心据点和黑洞是否清楚。
- 暂停弹窗、返回大厅确认和结算弹窗是否和新主题一致。
- 大局模式下 `RpsBattlePerf` 的 `update`、`draw` 指标没有明显抬高。
