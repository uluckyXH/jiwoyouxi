# rpsBattle 显示同步帧驱动优化测试报告

日期：2026-07-09
状态：本地构建通过，待真机复测

## 背景

真机日志显示，引擎扫描优化后大局 `update` 已从约 `21.73ms` 降到约 `8.97ms`，`target/frame` 和 `collision/frame` 也明显下降。但用户仍反馈体感有卡顿。

因此本轮判断：剩余卡顿不再优先按“单帧算法过重”处理，而是先验证 `setInterval(33ms)` 带来的 30FPS 帧节奏问题。

## 改动

改动文件：

- `entry/src/main/ets/games/rpsBattle/RpsBattlePage.ets`

核心改动：

- 引入 `@kit.ArkGraphics2D` 的 `displaySync`。
- 将主循环从 `setInterval(33ms)` 替换为 `displaySync.DisplaySync`。
- 设置预期帧率范围为 `60/60/60`。
- 使用 `displaySync.IntervalInfo.timestamp` 计算 `dt`。
- 暂停、结算、返回大厅时停止显示同步器。
- 页面销毁时解绑 `frame` 回调。
- 性能日志新增 `loop=displaySync targetFps=60`。
- 时间戳间隔兼容纳秒、微秒、毫秒三种单位。

未改动：

- 石头剪刀布克制规则。
- 移动、追捕、逃离、碰撞转化。
- 结算、暂停、继续、返回大厅。
- BGM、转化音效、胜利音效。

## 本地验证

执行命令：

```text
./scripts/build-app.sh --stacktrace
```

结果：

```text
BUILD SUCCESSFUL
```

已知非阻塞警告：

```text
WARN: No signingConfig found for product default
```

## 真机复测重点

请重点复制 `RpsBattlePerf` 日志。新日志应包含：

```text
RpsBattlePerf loop=displaySync targetFps=60 scale=...
```

重点指标：

- `fps`：如果显示同步生效，应接近 60。
- `interval`：如果 60Hz 生效，应接近 16 到 17ms。
- `maxInterval`：判断是否还有明显尖峰。
- `update`：大局 60Hz 下最好继续低于 8ms，越低越稳。
- `draw`：如果接近或超过 6ms，下一步优先做渲染降级。
- `target/frame`、`collision/frame`：确认引擎扫描优化没有退化。

## 下一步判断

如果真机体感变顺：

- 保留 `displaySync` 驱动。
- 后续继续做素材接入前的渲染分层。

如果 `fps` 接近 60 但仍卡：

- 看 `maxInterval` 尖峰是否对应 SoundPool 日志。
- 继续压 `draw`，减少每帧文字、网格和半透明绘制。
- 评估大局模式视觉降级。

如果 `fps` 只有 30 左右：

- 说明系统实际调度没有按 60Hz 跑。
- 继续看 `interval/maxInterval` 是否比原 timer 稳。
- 必要时改成动态目标帧率：标准局 60，大局 45 或 30。

如果 `update + draw` 接近 16ms：

- 说明 60Hz 帧预算吃紧。
- 不继续提高帧率，优先做热路径对象分配优化和渲染降本。
