# 鸡窝游戏 HarmonyOS Native

`jiwoyouxi` 是《鸡窝游戏》的原生鸿蒙 NEXT 主线工程。它不使用 ArkWeb/WebView，合集大厅、小游戏逻辑、Canvas 渲染和本地统计都运行在 ArkTS + ArkUI 中。

## 当前状态

更新时间：2026-06-09

- 主线目标：先做好 HarmonyOS 原生离线游戏合集，暂不做其他系统。
- 首页大厅、收藏、最近游玩、成就、设置和本地最高分已经接入。
- 6 个离线游戏入口已经接入。
- 俄罗斯方块正在重点打磨：UI 已改成奶油玻璃风格，底部 4 键控制已重构为面板级触摸分发，仍需最后一轮真机复测。
- 详细进度见 [docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)。

当前离线游戏入口：

- 石头剪刀布大作战
- 别踩白块
- 扫雷
- 俄罗斯方块
- 合成大西瓜
- 弹射鸡蛋

## 协作入口

- 新人先读 [CONTRIBUTING.md](CONTRIBUTING.md)。
- 新增游戏按 [docs/ADDING_GAMES.md](docs/ADDING_GAMES.md) 接入。
- 真机验收按 [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md) 检查。
- 当前进度和已知风险在 [docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)。

## 目录职责

- `entry/src/main/ets/pages/Index.ets`：合集薄入口和游戏路由。
- `entry/src/main/ets/pages/HubPage.ets`：游戏大厅、最近游玩、收藏、成就墙和统一设置。
- `entry/src/main/ets/app/CoopStorage.ets`：基于 preferences 的本地最高分、游玩次数、最近和收藏存储。
- `entry/src/main/ets/shell`：游戏模块定义和注册表。
- `entry/src/main/ets/design`：鸡窝游戏视觉 token。
- `entry/src/main/ets/games/rps/RpsPage.ets`：原 World of RPS 原生玩法页。
- `entry/src/main/ets/games/*`：第一批原生离线小游戏。
- `entry/src/main/ets/components`：可复用 ArkUI 组件，目前包含「我要打十个」倒计时条。
- `entry/src/main/ets/model/GameEngine.ets`：游戏模拟、碰撞、缩圈、黑洞、叛徒、响指等机制。
- `entry/src/main/ets/model/GameTypes.ets`：游戏数据结构、阵营常量、默认配置。
- `entry/src/main/ets/model/Presets.ets`：经典战役预设。
- `entry/src/main/ets/model/TenAgainstOneSystem.ets`：「我要打十个」触发、反杀、结算逻辑。
- `entry/src/main/ets/model/GameRules.ets`：阵营计数、存活阵营、领先方等纯规则函数。
- `entry/src/main/ets/model/OptionSummary.ets`：开局配置摘要文案。
- `entry/src/main/ets/render/CanvasRenderer.ets`：Canvas 绘制，包含实体、障碍、黑洞、叛徒标记、暴走残影。
- `entry/src/main/ets/services/AudioService.ets`：BGM、音效加载与播放。
- `entry/src/main/resources/base/media`：原生图片资源。
- `entry/src/main/resources/rawfile/audio`：音频资源。

## 模块约束

- 合集入口保持薄路由；新增小游戏优先放到 `entry/src/main/ets/games/<gameId>`。
- 页面和引擎文件继续控制在 1000 行以内；RPS 新增玩法优先拆到 `model/*System.ets` 或 `components`。
- 纯规则函数不写进页面，放在 `GameRules.ets` / 独立系统文件里，方便后续复用和测试。
- `build-profile.json5` 使用 DevEco 写入的本机调试签名；换机器或换设备时在 DevEco 里重新生成签名。

## 构建

首次拉仓库后，根目录真实 `build-profile.json5` 不会进 Git，因为里面有本机签名路径和密码。协作者需要复制示例文件并在 DevEco 里生成自己的签名：

```bash
cp build-profile.example.json5 build-profile.json5
```

然后用 DevEco 打开工程，在 Signing Configs 里生成调试签名。

```bash
./scripts/build-app.sh --stacktrace
```

当前工程使用 DevEco 写入的本机调试签名。真机部署优先安装 signed HAP：

```bash
./scripts/install-signed-hap.sh
```

不要手工安装 `build/outputs/default/*.app` 聚合包；当前设备会对该 `.app` 路径报 `no signature file`。已验证 `entry/build/default/outputs/default/entry-default-signed.hap` 可以正常安装。

## Git 约定

- `build/`、`entry/build/`、`.hvigor/`、`.idea/`、`phone-shots/` 不进 Git。
- 根目录 `build-profile.json5` 不进 Git。
- 真机截图和 layout dump 只留本地排查，不提交。
- 合并前至少跑一次构建，并在 PR/提交说明里写清真机验证结果。
