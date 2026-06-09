# 协作开发说明

本仓库只做 HarmonyOS 原生 ArkTS / ArkUI 版本。不要引入 WebView、HTML 游戏页或其他平台适配，除非项目负责人明确下口令。

## 分支建议

- `main`：可构建、可安装的主线。
- `feature/<game-id>`：新增或重做某个游戏。
- `fix/<scope>`：修复具体问题。
- 合并前至少跑一次 `./scripts/build-app.sh --stacktrace`。

## 新增游戏流程

1. 先在 [docs/GAME_BACKLOG.md](docs/GAME_BACKLOG.md) 查候选清单，或用 GitHub issue 模板登记新游戏。
2. 在 `entry/src/main/ets/games/<gameId>/<GameName>Page.ets` 新建页面。
3. 在 `entry/src/main/ets/shell/GameRegistry.ets` 注册标题、图标、标签和最高分类型。
4. 在 `entry/src/main/ets/pages/Index.ets` 导入页面并接入路由。
5. 游戏结束时调用 `recordScore(score)`，返回大厅调用 `exitToHub()`。
6. 所有状态保存在本页面或 `CoopStorage` 统一快照里，不要使用网络依赖。
7. 真机至少验证启动、返回、暂停/重开、最高分记录和小屏布局。

## UI 约束

- 使用 `CoopTheme` 的奶油色、圆角、液态玻璃风格。
- 游戏首屏必须是可玩界面，不做营销落地页。
- 按钮、棋盘、工具栏要有稳定尺寸，不能因文字或状态变化导致布局跳动。
- 小屏上不得遮挡系统手势条。

## 签名说明

根目录 `build-profile.json5` 含本机 DevEco 签名路径和密码，已被 `.gitignore` 排除。

协作者首次拉仓库后：

1. 复制 `build-profile.example.json5` 为 `build-profile.json5`。
2. 用 DevEco 打开工程。
3. 在 Signing Configs 中为自己的设备生成调试签名。
4. 使用 `./scripts/build-app.sh --stacktrace` 构建。

真机部署优先用：

```bash
./scripts/install-signed-hap.sh
```
