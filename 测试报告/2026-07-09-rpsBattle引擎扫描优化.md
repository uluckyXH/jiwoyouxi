# 2026-07-09 rpsBattle 引擎扫描优化测试报告

## 测试范围

- 新版 `rpsBattle` 引擎性能优化。
- 目标搜索从全量实体扫描改为按阵营缓存扫描。
- 人数统计改为引擎内增量维护，减少重复全量统计。
- 碰撞检测从全体两两检查改为均匀网格空间分桶。
- 保留原有移动、追捕、逃离、碰撞推开、克制转化和结算规则。

## 变更文件

- `entry/src/main/ets/games/rpsBattle/RpsBattleEngine.ets`

## 优化前真机基线

标准局：

```text
scale=standard entities=24 update=12.14~12.30ms draw=1.69~1.77ms target/frame=1152 collision/frame=276
```

大局：

```text
scale=large entities=36 update=21.73ms draw=2.00ms target/frame=2592 collision/frame=630
```

## 预期变化

- 标准局 `target/frame` 从 `1152` 降到约 `300~500`。
- 大局 `target/frame` 从 `2592` 降到约 `700~1100`。
- `collision/frame` 在单位分散时低于全量两两检查。
- `update` 应明显低于优化前。
- `draw` 不应明显变化，因为本次未改渲染。

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

## 待真机验收项

- 标准局运行 20 秒，复制 `RpsBattlePerf` 日志对比 `target/frame` 和 `update`。
- 大局运行 20 秒，复制 `RpsBattlePerf` 日志对比 `target/frame`、`collision/frame` 和 `update`。
- 观察单位是否仍会正常追捕、逃离、碰撞、转化。
- 观察清场结算和限时结算是否仍正常。
- 暂停、继续、返回大厅后确认循环和音效无异常。

## 风险点

- 空间分桶会改变碰撞候选遍历顺序，战场细节可能与优化前不完全一致，但核心规则不变。
- 如果单位在同一区域高度聚集，`collision/frame` 下降幅度会低于分散场景。
