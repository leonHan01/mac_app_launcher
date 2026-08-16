# Mac Launcher

[English](README.md)

Mac Launcher 是一款使用 AppKit 构建的原生 macOS 风格应用启动器。它会展示本机安装的应用、真实应用图标和名称，并提供快速搜索、翻页动画以及持久化显示设置。

本项目旨在还原经典 macOS 应用启动器的使用体验，并以现代原生实现重新呈现。

> **拼音搜索是本项目的特色功能：** 中文应用既可以使用完整拼音搜索（例如 `beiwanglu`），也可以使用带空格拼音（`bei wang lu`）或拼音首字母（`bwl`）搜索。

## 应用截图

![Mac Launcher 应用启动器截图](docs/launcher-screenshot.png)

## 功能

- 扫描 `/Applications`、`~/Applications` 和 `/System/Applications` 中的应用。
- 展示本机应用的真实图标和显示名称。
- 使用深色半透明原生风格搜索框，输入光标和文字左对齐。
- 支持中文名称、完整拼音、带空格拼音和拼音首字母搜索。
- 支持鼠标滚轮、触控板滚动、页面圆点和左右滑动动画翻页。
- 打开和隐藏界面时使用淡入淡出动画。
- 点击图标启动对应的本机应用。
- 点击应用网格外的空白区域或按 `Esc` 隐藏界面。
- 隐藏界面后进程继续运行，可从 Dock 重新打开。
- 只有按下 `Command-Q` 才会完全退出应用。
- 右上角设置面板支持搜索并持久屏蔽指定应用。
- 使用 `native/Assets/Launched.png` 中的纸飞机应用图标。

## 系统要求

- macOS 13.0 或更高版本
- Apple Silicon Mac
- Xcode Command Line Tools（`clang`、`codesign` 和 `hdiutil`）

## 构建 DMG

在项目目录运行：

```bash
./build-macos.sh
```

脚本会检查启动器生命周期，编译原生 AppKit 应用，嵌入图标和应用元数据，执行 ad-hoc 签名，并生成 DMG 安装包。

构建产物：

```text
build/Mac-Launcher-1.5.6-arm64.dmg
```

打开 DMG 后，将 `Mac Launcher.app` 拖入 `Applications` 文件夹即可。该版本使用 ad-hoc 签名，没有 Apple Developer ID 签名或公证。在其他 Mac 上首次启动时，macOS 可能需要你前往“系统设置 → 隐私与安全性”确认打开。

## 直接运行应用

```bash
./build-macos.sh
open "build/Mac Launcher.app"
```

启动器显示窗口后会在后台扫描本机应用，扫描期间界面仍可保持响应。

## 浏览器预览

仓库中还包含一个轻量级浏览器预览版本。浏览器预览无法访问 Mac 本机应用列表，也无法启动原生应用。

```bash
python3 -m http.server 4173
```

然后访问 <http://localhost:4173>。

## 项目结构

```text
native/LauncherApp.m       原生 AppKit 启动器实现
native/Info.plist          应用包元数据
native/Assets/              应用图标资源
scripts/check-lifecycle.sh 启动、隐藏、重新打开和退出行为检查
build-macos.sh             编译、签名和打包脚本
index.html                 浏览器预览入口
script.js                  浏览器预览逻辑
styles.css                 浏览器预览样式
```

## License

本项目目前尚未指定许可证。
