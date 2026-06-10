# 新增小游戏接入指南

## 文件位置

新增游戏统一放在：

```text
entry/src/main/ets/games/<gameId>/<GameName>Page.ets
```

页面导出格式建议：

```ts
@Component
export struct ExampleGamePage {
  @Prop bestScore: number = 0;
  exitToHub: () => void = () => {};
  recordScore: (score: number) => void = () => {};

  build() {
    Column() {
      // playable UI
    }
    .width('100%')
    .height('100%')
  }
}
```

## 注册入口

在 `entry/src/main/ets/shell/GameRegistry.ets` 添加：

```ts
{
  id: 'example',
  title: '示例游戏',
  subtitle: '一句话说明核心玩法',
  icon: '◎',
  tags: ['离线', '轻松', '快速'],
  accent: '#ef6f57',
  highScoreLabel: '最高分'
}
```

## 路由接入

在 `entry/src/main/ets/pages/Index.ets`：

- import 新页面。
- 在 `build()` 的游戏分支里新增 `else if`。
- 传入 `bestScore`、`exitToHub`、`recordScore`。

## 评分与存档

- 游戏结束时调用 `recordScore(score)`。
- 分数必须是非负数。
- 不要直接读写 preferences，统一走 `Index.ets` 和 `CoopStorage.ets`。

## UI 要求

- 首页点击后直接进入可玩状态。
- 返回按钮文案统一使用“大厅”。
- 暂停、重开、结算弹窗要有。
- 横竖布局优先竖屏手机，兼容平板但不用优先优化。
- 避免把卡片套卡片，游戏核心区域要清楚、稳定。

## 真机验收

新增游戏合并前至少确认：

- 能从首页进入。
- 能返回大厅。
- 游戏不会刚进入就结束。
- 主要操作可点、可拖或可长按。
- 结算后最高分会更新。
- 小屏无文字重叠、无按钮压到系统手势条。
