# rpsBattle 目标搜索空间索引优化测试报告

日期：2026-07-09
状态：真机复测失败，已回退空间索引；保留热路径微优化

## 背景

显示同步帧驱动上线后，大局真机日志显示平均帧率接近 60FPS，但偶发掉帧：

```text
scale=large entities=36 fps=56.4~60.8 interval=16.4~17.8ms maxInterval=32ms update=11.90~12.47ms draw=1.90~2.05ms target/frame=678~724 collision/frame=117~124
```

判断：

- `draw` 约 2ms，不是主瓶颈。
- `collision/frame` 已从初始 630 降到约 120，碰撞分桶有效。
- `target/frame` 仍有 700 左右，是当前 `update` 的主要成本来源。
- `update + draw` 约 14ms，距离 60Hz 的 16.7ms 帧预算太近，容易被音效或系统调度挤出一帧。

## 改动

改动文件：

- `entry/src/main/ets/games/rpsBattle/RpsBattleEngine.ets`

核心改动：

- 新增按阵营拆分的目标空间桶：
  - `rockTargetBuckets`
  - `scissorsTargetBuckets`
  - `paperTargetBuckets`
- 每帧移动前按当前位置重建目标桶。
- 最近猎物/天敌查询从目标阵营数组扫描改成空间桶扩圈查询。
- 扩圈停止条件使用未访问区域的最小可能距离，避免变成“只找附近目标”。
- 单位移动并跨格后，同步它自己的目标桶位置。
- 删除热路径里的 `normalized()` 临时对象分配。
- 逃离判断先用平方距离过滤，减少不必要的开方。

## 不变内容

本轮不改游戏内容：

- 不改三阵营克制关系。
- 不改单位数量。
- 不改移动加速度、最大速度、逃离距离。
- 不改碰撞转化规则。
- 不改结算规则。
- 不改 UI、音效、暂停、返回大厅。

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

## 真机复测结果

空间索引版大局日志：

```text
scale=large entities=36 fps=31.1~32.1 interval=31.2~31.8ms maxInterval=31~50ms update=21.52~23.16ms draw=1.81~2.12ms target/frame=434~624 collision/frame=121~143
```

结论：

- `target/frame` 从上一轮 `678~724` 降到 `434~624`，扫描次数确实下降。
- 但 `update` 从上一轮约 `12ms` 升到 `21.52~23.16ms`，整体耗时明显恶化。
- `fps` 从接近 60 降到约 32，`interval` 接近 31ms。
- 系统日志出现 `ProcessJank`，说明这版造成真实卡顿。

原因判断：

- 精确空间索引为了保证“仍找真正最近目标”，需要扩圈扫描、计算未访问区域最小距离、维护多组桶。
- 当前实体数量只有 36 个，目标阵营数组扫描虽然次数多，但结构简单、常数开销低。
- 空间索引减少了扫描次数，却引入了更高常数开销，收益被抵消并反向恶化。

处理：

- 已回退目标空间索引。
- 保留不改变玩法的热路径微优化：去掉 `normalized()` 临时对象、逃离距离先做平方判断。

## 回退后复测重点

请继续复制 `RpsBattlePerf` 日志，重点看大局：

```text
RpsBattlePerf loop=displaySync targetFps=60 scale=large ...
```

对比字段：

- `target/frame`：预计回到上一轮 `678~724` 附近。
- `update`：应从空间索引版 `21~23ms` 回落到约 `12ms`，若热路径微优化有效可能略低。
- `draw`：应继续维持约 `2ms`，不要异常上升。
- `fps`：目标接近 60。
- `maxInterval`：目标是不再频繁出现 `32ms`。
- `collision/frame`：应继续保持约 `120` 左右，不应回升到 `630`。

## 下一步判断

如果回退后 `fps` 恢复接近 60：

- 确认空间索引路线放弃。
- 下一步做分段耗时日志，把 movement、target、collision 拆开计时。

如果回退后 `update` 仍然接近 22ms：

- 说明还有别的改动或设备状态影响，需要继续查。

如果仍要继续压目标搜索：

- 不再采用精确空间索引。
- 优先考虑“上一帧目标缓存 + 定期重寻”，并用开关验证是否影响手感。
- 或者接受大局动态 30/45FPS，标准局保持 60FPS。
