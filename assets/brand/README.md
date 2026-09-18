# 鸡窝游戏品牌图形

`chicken_mark.svg` 是可编辑的矢量母版：奶油色小鸡抱着木色手柄，坐在鼠尾草绿的小窝里。轮廓使用暖棕色，沿用首页轻松、温暖的手绘风格。

运行 `node scripts/generate-app-brand.mjs` 更新以下资源：

- `AppScope/resources/base/media/app_icon.svg`：带麦芽黄色背景的应用图标；保留完整方形画布，由系统裁切外轮廓。
- `entry/src/main/resources/base/media/start_icon.svg`：浅色开屏插画，透明底。
- `entry/src/main/resources/dark/media/start_icon.svg`：深色开屏插画，透明底。

应用和入口 Ability 共用 AppScope 的图标资源，避免重复资源覆盖。SVG 不含字体、位图或外部依赖。

系统启动窗口使用 `start_window_background` 与 `start_icon`，随后 `StartupPage` 在本地数据读取期间展示应用名和「休息一下，玩一会儿」。不设置最短停留时间。窄横屏使用左右排布，大屏居中放大插画，背景和文字提供系统深色资源。

`docs/previews/app-brand-preview.png` 为设计预览，不是模拟器截图。已检查 SVG XML、圆形/圆角方形裁切、32/48 px 缩放，并通过 `scripts/build-app.sh` 编译。实际系统开屏时长、桌面遮罩和切换观感需设备确认。
