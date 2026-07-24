# 2026-07-09 rpsBattle 性能计数日志测试报告

## 测试范围

- 新版 `rpsBattle` 增加开发期性能计数日志。
- 页面主循环统计实际帧间隔、引擎 update 耗时、Canvas draw 耗时。
- 引擎统计每帧目标搜索扫描次数和碰撞检查次数。
- 日志每秒聚合输出一次，避免逐帧刷日志影响运行。
- 暂停后继续时重置统计窗口，避免暂停时间污染帧间隔数据。

## 变更文件

- `entry/src/main/ets/games/rpsBattle/RpsBattlePage.ets`
- `entry/src/main/ets/games/rpsBattle/RpsBattleEngine.ets`

## 日志格式

示例：

```text
RpsBattlePerf scale=large entities=36 frames=31 fps=30.2 interval=33.1ms maxInterval=42ms update=1.35ms draw=5.10ms target/frame=2592 collision/frame=630 conversions/frame=0.16 totalConversions=12
```

字段说明：

- `scale`：当前规模，`small` / `standard` / `large`。
- `entities`：当前实体数量。
- `frames`：本轮聚合窗口内帧数。
- `fps`：本轮聚合窗口估算 FPS。
- `interval`：平均实际帧间隔。
- `maxInterval`：本轮聚合窗口最大帧间隔。
- `update`：平均引擎更新耗时。
- `draw`：平均 Canvas 绘制耗时。
- `target/frame`：平均每帧目标搜索扫描次数。
- `collision/frame`：平均每帧碰撞检查次数。
- `conversions/frame`：平均每帧转化次数。
- `totalConversions`：当前累计转化次数。

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

当前 `rpsBattle` 包仍处于未跟踪目录状态，`git diff --check` 无法完整覆盖未跟踪文件。本次以 ArkTS 构建通过作为主要校验。

## 待真机验收项

- 标准局运行 20 秒，确认每秒输出 `RpsBattlePerf`。
- 大局运行 20 秒，确认日志字段完整。
- 暂停 3 秒后继续，确认继续后的 `maxInterval` 不被暂停时间污染。
- 结算后确认日志停止输出。
- 返回大厅后确认日志停止输出。

## 后续分析方式

- 如果 `update` 高，优先看阵营缓存、增量计数、空间分桶。
- 如果 `draw` 高，优先看静态背景/动态单位分层和单位绘制降本。
- 如果 `update`、`draw` 都不高但 `maxInterval` 偶发很大，再评估帧驱动方案。
