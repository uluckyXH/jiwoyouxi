# 真机 QA 清单

## 通用

- `./scripts/build-app.sh --stacktrace` 构建成功。
- `./scripts/install-signed-hap.sh` 安装成功。
- App 能从桌面启动。
- 首页无明显文字重叠。
- 底部 Tab 可切换：首页、收藏、成就、设置。
- 收藏、最近游玩、最高分能持久化。
- 返回键在游戏内回大厅，在大厅交给系统。

## 俄罗斯方块

- 进入游戏后不是旧局残留。
- 底部只有 4 个按钮：`←`、`→`、`↓`、`↻`。
- `←/→` 点按移动一格。
- `←/→` 长按 180ms 后连续移动，每 80ms 左右。
- `↓` 点按软降一格。
- `↓` 长按 350ms 硬降并锁定。
- `↻` 只做顺时针旋转。
- 暂停/继续正常。
- 游戏结束后“再来一局”和“回大厅”正常。

## 截图留档

建议截图放本机 `phone-shots/`，该目录不进 Git。

常用命令：

```bash
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc shell uitest screenCap -p /data/local/tmp/current.png
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc file recv /data/local/tmp/current.png phone-shots/current.png
```
