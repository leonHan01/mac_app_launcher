const demoApps = [
  { name: "访达", icon: "📁", className: "icon-finder", category: "utility", running: true, keywords: "finder 文件 访达" },
  { name: "Safari 浏览器", icon: "", className: "icon-safari", category: "work", running: true, keywords: "safari browser 网页 浏览器" },
  { name: "备忘录", icon: "≡", className: "icon-notes", category: "work", keywords: "notes 备忘录 笔记" },
  { name: "邮件", icon: "✉", className: "icon-mail", category: "work", running: true, keywords: "mail 邮件 邮箱" },
  { name: "日历", icon: "27", className: "icon-calendar", category: "work", keywords: "calendar 日历 会议" },
  { name: "计算器", icon: "⌗", className: "icon-calculator", category: "utility", keywords: "calculator 计算器" },
  { name: "音乐", icon: "♪", className: "icon-music", category: "creative", keywords: "music 音乐 apple music" },
  { name: "照片", icon: "✿", className: "icon-photos", category: "creative", keywords: "photos 照片 相册 图片" },
  { name: "信息", icon: "●", className: "icon-messages", category: "work", running: true, keywords: "messages 信息 短信 聊天" },
  { name: "终端", icon: ">_", className: "icon-terminal", category: "utility", keywords: "terminal 终端 命令" },
  { name: "Figma", icon: "", className: "icon-figma", category: "creative", running: true, keywords: "figma 设计 原型" },
  { name: "Slack", icon: "✣", className: "icon-slack", category: "work", running: true, keywords: "slack 协作 消息" },
  { name: "Visual Studio Code", icon: "‹›", className: "icon-vscode", category: "work", running: true, keywords: "vscode code visual studio 代码 开发" },
  { name: "Notion", icon: "N", className: "icon-notion", category: "work", keywords: "notion 笔记 文档" },
  { name: "Arc 浏览器", icon: "", className: "icon-arc", category: "work", keywords: "arc 浏览器 browser" },
  { name: "Spotify", icon: "◒", className: "icon-spotify", category: "creative", keywords: "spotify 音乐 播放" },
  { name: "Discord", icon: "☯", className: "icon-discord", category: "work", keywords: "discord 社区 聊天" },
  { name: "系统设置", icon: "", className: "icon-settings", category: "utility", keywords: "settings 设置 系统" },
  { name: "时钟", icon: "", className: "icon-clock", category: "utility", keywords: "clock 时钟 世界时间" },
  { name: "地图", icon: "", className: "icon-map", category: "utility", keywords: "map 地图 位置" },
  { name: "股市", icon: "↗", className: "icon-stocks", category: "utility", keywords: "stocks 股市 股票" },
  { name: "提醒事项", icon: "", className: "icon-reminders", category: "work", keywords: "reminders 提醒 待办" },
  { name: "实用工具", icon: "", className: "icon-utility", category: "utility", keywords: "utilities 实用 工具" },
  { name: "调度中心", icon: "◎", className: "icon-utility", category: "utility", keywords: "control center 调度 控制" }
];

const nativeMode = window.__NATIVE_LAUNCHER__ === true;
let apps = nativeMode ? [] : demoApps;
let isLoadingNativeApps = nativeMode;

const grid = document.querySelector("#appsGrid");
const searchInput = document.querySelector("#searchInput");
const emptyState = document.querySelector("#emptyState");
const appCount = document.querySelector("#appCount");
const footerStatus = document.querySelector("#footerStatus");
const toast = document.querySelector("#toast");
const filters = [...document.querySelectorAll(".filter")];
const viewButton = document.querySelector("#viewButton");
const launcher = document.querySelector(".launcher");
let activeFilter = "all";
let selectedIndex = -1;
let toastTimeout;

function escapeHTML(value = "") {
  return String(value).replace(/[&<>'"]/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "'": "&#39;",
    '"': "&quot;"
  })[character]);
}

function setEmptyState(title, description) {
  emptyState.querySelector("h2").textContent = title;
  emptyState.querySelector("p").textContent = description;
}

function matchingApps() {
  const query = searchInput.value.trim().toLowerCase();
  return apps.filter((app) => {
    const inCategory = activeFilter === "all" || app.category === activeFilter;
    const text = `${app.name} ${app.keywords || ""}`.toLowerCase();
    return inCategory && text.includes(query);
  });
}

function renderApps() {
  if (isLoadingNativeApps) {
    grid.innerHTML = "";
    emptyState.hidden = false;
    setEmptyState("正在读取本机应用", "正在扫描“应用程序”文件夹…");
    appCount.textContent = "读取中";
    footerStatus.textContent = "正在准备本机应用列表";
    return;
  }

  const visible = matchingApps();
  grid.innerHTML = visible.map((app, index) => `
    <button class="app" type="button" data-name="${escapeHTML(app.name)}" data-path="${escapeHTML(app.path || "")}" data-index="${index}" aria-label="打开 ${escapeHTML(app.name)}">
      <span class="app-icon ${app.iconURL ? "app-icon-image" : escapeHTML(app.className || "icon-utility")}">${app.iconURL ? `<img src="${escapeHTML(app.iconURL)}" alt="" />` : escapeHTML(app.icon)}</span>
      <span class="app-name">${escapeHTML(app.name)}</span>
      ${app.running ? '<span class="app-dot" aria-label="正在运行"></span>' : ""}
    </button>
  `).join("");
  emptyState.hidden = visible.length !== 0;
  if (!visible.length) setEmptyState("没有找到应用", "试试使用其他关键词搜索。");
  appCount.textContent = `${visible.length} 个应用`;
  footerStatus.textContent = visible.length === apps.length ? "应用程序已准备就绪" : `显示 ${visible.length} 个匹配结果`;
  selectedIndex = visible.length ? Math.min(selectedIndex, visible.length - 1) : -1;
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => toast.classList.remove("show"), 1800);
}

function openApp(button) {
  const appName = button.dataset.name;
  showToast(`正在打开「${appName}」`);
  const launcherHandler = window.webkit?.messageHandlers?.launchApp;
  if (launcherHandler && button.dataset.path) {
    footerStatus.textContent = `正在启动 ${appName}`;
    launcherHandler.postMessage({ path: button.dataset.path, name: appName });
    return;
  }
  footerStatus.textContent = `已启动 ${appName}`;
}

window.__setNativeApps = (nativeApps) => {
  apps = Array.isArray(nativeApps) ? nativeApps : [];
  isLoadingNativeApps = false;
  selectedIndex = -1;
  renderApps();
};

window.__nativeLaunchResult = ({ name, success }) => {
  const message = success ? `已打开「${name}」` : `无法打开「${name}」`;
  showToast(message);
  footerStatus.textContent = message;
};

grid.addEventListener("click", (event) => {
  const button = event.target.closest(".app");
  if (button) openApp(button);
});

searchInput.addEventListener("input", renderApps);

filters.forEach((filter) => {
  filter.addEventListener("click", () => {
    activeFilter = filter.dataset.filter;
    filters.forEach((item) => item.classList.toggle("is-active", item === filter));
    selectedIndex = -1;
    renderApps();
  });
});

viewButton.addEventListener("click", () => {
  const compact = launcher.classList.toggle("compact");
  viewButton.setAttribute("aria-pressed", String(compact));
  showToast(compact ? "已切换为紧凑视图" : "已切换为舒适视图");
});

document.addEventListener("keydown", (event) => {
  const isSearchShortcut = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k";
  if (isSearchShortcut) {
    event.preventDefault();
    searchInput.focus();
    searchInput.select();
    return;
  }
  if (event.key === "Escape" && document.activeElement === searchInput) {
    searchInput.value = "";
    searchInput.blur();
    renderApps();
    return;
  }
  if (["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(event.key) && document.activeElement !== searchInput) {
    const buttons = [...grid.querySelectorAll(".app")];
    if (!buttons.length) return;
    event.preventDefault();
    const columns = getComputedStyle(grid).gridTemplateColumns.split(" ").length;
    const delta = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -columns, ArrowDown: columns }[event.key];
    selectedIndex = selectedIndex === -1 ? 0 : (selectedIndex + delta + buttons.length) % buttons.length;
    buttons[selectedIndex].focus();
  }
  if (event.key === "Enter" && document.activeElement?.classList.contains("app")) {
    event.preventDefault();
    openApp(document.activeElement);
  }
});

renderApps();
