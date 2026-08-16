# Launchpad

一个 macOS 风格应用启动器，既可在浏览器中预览，也可构建为原生 macOS 应用。

直接用浏览器打开 `index.html`，或在本目录运行：

```bash
python3 -m http.server 4173
```

然后访问 `http://localhost:4173`。

macOS 版为原生 AppKit 全屏启动台，并使用纸飞机品牌图标。主搜索框使用深色半透明原生材质、细边框与柔和阴影，输入文字左对齐。启动和隐藏时使用柔和的淡入淡出效果，界面显示后在后台扫描 `/Applications`、`~/Applications` 和 `/System/Applications`。它展示本机真实图标，支持关键词搜索，并通过鼠标滚轮配合左右滑动动画翻页；点击图标会启动对应的本机应用，点击空白处或按 `Esc` 仅隐藏界面，再次点击 Dock 图标即可恢复。只有 `Command-Q` 会完全退出进程。右上角设置可选择并持久屏蔽不想显示的应用。

## 构建 DMG

在搭载 Apple Silicon 的 Mac 上运行：

```bash
./build-macos.sh
```

构建产物位于 `build/Mac-Launcher-1.5.5-arm64.dmg`。DMG 中包含应用和“Applications”快捷方式，可直接将应用拖入“应用程序”文件夹。

该项目使用本地 ad-hoc 签名，不含 Apple Developer ID 签名或公证；其他 Mac 上首次启动时可能需要在“系统设置 → 隐私与安全性”中确认打开。
